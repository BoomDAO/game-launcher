/// **Internet Computer Canister Signatures**
///
/// This modules allows canister to produce signatures according to the
/// “[Canister Signature scheme]”.
///
/// [Canister Signature scheme]: <https://internetcomputer.org/docs/current/references/ic-interface-spec#canister-signatures>
///

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import MerkleTree "MerkleTree";
import ReqData "ReqData";
import CertTree "CertTree";
import Time "mo:base/Time";
import Deque "mo:base/Deque";
import CertifiedData "mo:base/CertifiedData";
import Error "mo:base/Error";
import SHA256 "mo:sha2/Sha256";
import Debug "mo:base/Debug";
import List "mo:base/List";

module {
  public type PublicKey = Blob;
  public type Seed = Blob;
  public type Signature = Blob;
  public type PayloadHash = Blob;

  /// Calculate the DER-encoded public key for the given canister and seed
  public func publicKey(canister_id : Principal, seed : Seed) : PublicKey {
    let b = Principal.toBlob(canister_id);
    let buf = Buffer.Buffer<Nat8>(0);
    buf.add(Nat8.fromNat(b.size()));
    bufferAppend(buf, b);
    bufferAppend(buf, seed);
    wrapDer(Blob.fromArray(Buffer.toArray(buf)));
  };

  /// Derive a self-authenticating principal from a public key
  public func selfAuthenticatingPrincipal(publicKey : PublicKey) : Principal {
    let buf = Buffer.Buffer<Nat8>(28+1);
    bufferAppend(buf, SHA256.fromBlob(#sha224, publicKey));
    buf.add(0x02);
    Principal.fromBlob(Blob.fromArray(Buffer.toArray(buf)));
  };

  func wrapDer(raw_key : Blob) : Blob {
    let canister_sig_oid_seq : Blob = "\30\0c\06\0a\2b\06\01\04\01\83\b8\43\01\02";
    let buf = Buffer.Buffer<Nat8>(0);
    buf.add(0x30); // SEQUENCE
    buf.add(Nat8.fromNat(canister_sig_oid_seq.size() + 3 + raw_key.size())); // overall length  
    bufferAppend(buf, canister_sig_oid_seq);
    buf.add(0x03); // BIT String
    buf.add(Nat8.fromNat(1 + raw_key.size())); // key size
    buf.add(0x00); // BIT Padding
    bufferAppend(buf, raw_key);
    Blob.fromArray(Buffer.toArray(buf));
  };

  // Missing in standard library? Faster implementation?
  func bufferAppend(buf : Buffer.Buffer<Nat8>, b : Blob) {
    for (x in b.vals()) { buf.add(x) };
  };

  /// Encode the system certificate and the canister's hash tree witness
  /// as a Canister Signature scheme signature (CBOR-encoded)
  ///
  /// The witness must reveal the path `["sigs",seed, hash_of_msg_payload]`.
  /// So for example in an update method run something like
  /// ```
  /// let sig_payload_hash = h2("\0Aic-request", request_id);
  /// let path : CertTree.Path = ["sig", h "", sig_payload_hash];
  /// ct.put(path, "");
  /// ct.setCertifiedData();
  /// ```
  /// and then in the query method obtain the witness and the signature using
  /// ```
  /// let witness = ct.reveal(req_data.path);
  /// let sig = CanisterSigs.signature(cert, witness);
  /// ```
  public func signature(cert : Blob, witness : MerkleTree.Witness) : Signature {
    ReqData.encodeCBOR([
      ("certificate", #blob(cert)),
      ("tree", repOfWitness(witness))
    ])
  } ;

  func repOfWitness(w : MerkleTree.Witness) : ReqData.V {
    switch(w) {
      case (#empty)        { #array([#nat(0)]) };
      case (#fork(l,r))    { #array([#nat(1), repOfWitness(l), repOfWitness(r)]) };
      case (#labeled(k,w)) { #array([#nat(2), #blob(k), repOfWitness(w)])};
      case (#leaf(v))      { #array([#nat(3), #blob(v)])};
      case (#pruned(h))    { #array([#nat(4), #blob(h)])};
    }
  };

  /// The canister signature manager class provides a bit of convenience for keeping track of the
  /// prepare/fetch/delete cycle.
  ///
  /// Instantiate it with access to your canister's `CertTree.Ops`, e.g.
  /// ```
  /// stable let cert_store : CertTree.Store = CertTree.newStore();
  /// let ct = CertTree.Ops(cert_store);
  /// let csm = CanisterSigs.Manager(ct, null); 
  /// ```
  /// Then in the update call, call `prepare`, and in the query call call `fetch`.
  ///
  /// If your `CertTree.Store` is stable, it is recommended to prune all signatures in pre or
  /// post-upgrade:
  /// ```
  /// system func preupgrade() {
  ///  csm.pruneAll();
  /// };
  /// ```
  public class Manager(ct : CertTree.Ops, expiry : ?Time.Time) {

    var queue : Deque.Deque<(Time.Time, Seed, PayloadHash)> = Deque.empty();

    let exp = switch (expiry) {
      case null (60_000_000_000);
      case (?t) t;
    };

    /// Prepare a signature.
    ///
    /// The second argument is the hashed paylaod, e.g.
    /// ```
    /// let request_id = ReqData.hash(content);
    /// let sig_payload_hash = h2("\0Aic-request", request_id);
    /// csm.prepare("", sig_payload_hash);
    /// ```
    ///
    /// Also calls `setCertifiedData()` on the certified data for you.
    public func prepare(seed : Seed, plh : PayloadHash) {
      let path : CertTree.Path = ["sig", h seed, plh];
      prune();
      let expiry = Time.now() + exp;
      queue := Deque.pushBack(queue, (expiry, seed, plh));
      ct.put(path, "");
      ct.setCertifiedData();
    };

    /// Generate the signature.
    ///
    /// This only works in a query _call_, and will trap if no certificate is available.
    public func fetch(seed : Seed, plh : PayloadHash) : Signature {
      let path : CertTree.Path = ["sig", h seed, plh];
      let cert = switch (CertifiedData.getCertificate()) {
        case (?c) c;
        case null { Debug.trap("No certificate available. Is this a query call?"); };
      };
      let witness = ct.reveal(path);
      signature(cert, witness);
    };

    /// Drops expired signatures from the state tree.
    /// This is automatically called from `prepare`, so usually
    /// you do not need to call this.
    public func prune() {
      let now = Time.now();
      loop {
        switch (Deque.popFront(queue)) {
          case null { return };
          case (?(h, q2)) {
            let (expiry, seed, plh) = h;
            if (expiry < now) {
              // expired
              queue := q2;
            } else {
              // not expird
              return;
            }
          }
        }
      };
    };


    /// Drops all signatures. Useful in the pre_upgrade hook, to keep things tidy
    /// else signatures may lurk there forever, if the CanisterSigManager forgets about them.
    public func pruneAll() {
      ct.delete(["sig"]);
    };

    /// Number of unexpired signatures. Useful to inculde in metrics
    public func size() : Nat {
      List.size(queue.0) + List.size(queue.1);
    }

  };

  // Hash-related functions
  func h(b : Blob) : Blob {
      SHA256.fromBlob(#sha256, b)
  };

}
