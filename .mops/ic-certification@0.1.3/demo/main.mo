/*
This small Motoko canister demonstrates, as a proof of concept, how to serve
HTTP requests with dynamic data, and how to do that in a certified way.

To learn more about the theory behind certified variables, I recommend
my talk at https://dfinity.org/howitworks/response-certification
*/


/*
We start with s bunch of imports.
*/

import T "mo:base/Text";
import O "mo:base/Option";
import A "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import CertifiedData "mo:base/CertifiedData";
import SHA256 "mo:sha2/Sha256";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import ManagementCanister "ManagementCanister";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import CBOR "mo:cbor/Decoder";

// These could import from mo:merkle-tree if this was in a separate repository
import CertTree "../src/CertTree";
import ReqData "../src/ReqData";
import CanisterSigs "../src/CanisterSigs";
import MerkleTree "../src/MerkleTree";

/*
This actor demostrates the MerkleTree library. Its functionality is

 * Storing a certfiable key-value store.
 * Certified HTTP read access to it.
 * Setting and deleting values via update calls.

*/

actor Self {

/*
We'll use the merkle tree structure also as a key-value store for our main data.
This may not always be the right thing -- if you do not want to certify the raw
data directly, but only some views (e.g. a HTML rendering), it may make sense to
keep the main data in a regular data structure.  But here we will use it, also
to exercise lookup, deletion and iteration.
*/
  stable let cert_store : CertTree.Store = CertTree.newStore();
  let ct = CertTree.Ops(cert_store);

/*
For debugging and exploration, a way to view the tree
*/
  public query func get_cert_tree() : async MerkleTree.RawTree {
    MerkleTree.structure(cert_store.tree);
  };

/*
Two public methods to modify the merkle tree.
*/

  public shared func store(key : Text, value : Text) : async () {
    // Store key directly
    ct.put(["store", T.encodeUtf8(key)], T.encodeUtf8(value));
    ct.put(["http_assets", T.encodeUtf8("/get/" # key)], T.encodeUtf8(value));
    update_asset_hash(?key); // will be explained below
  };

  public shared func delete(key : Text) : async () {
    ct.delete(["store", T.encodeUtf8(key)]);
    update_asset_hash(?key); // will be explained below
  };

/*
A HTML rendering of the main page, including links to all keys:
*/

  func my_id(): Principal = Principal.fromActor(Self);

  func page_template(body : Text): Blob {
    return T.encodeUtf8 (
      "<html>" #
      "<head>" #
      "<meta name='viewport' content='width=device-width, initial-scale=1'>" #
      "<link rel='stylesheet' href='https://unpkg.com/chota@latest'>" #
      "<title>IC certified assets demo</title>" #
      "</head>" #
      "<body>" #
      "<div class='container' role='document'>" #
      body #
      "</div>" #
      "</body>" #
      "</html>"
    )
  };

  func main_page(): Blob {
    page_template(
      "<p>This canister demonstrates certified HTTP assets from Motoko.</p>" #
      "<p>You can see this text at <tt>https://" # debug_show my_id() # ".ic0.app/</tt> " #
      "(note, no <tt>raw</tt> in the URL!) and it will validate!</p>" #
      "<p>This canister is dynamic, and implements a simple key-value store. Here is the list of " #
      "keys:</p>" #
      "<ul>" #
      T.join("", Iter.map(ct.labelsAt(["store"]), func(key : Blob) : Text {
          "<li><a href='/get/" # ofUtf8(key) # "'>" # ofUtf8(key) # "</a></li>"
      })) #
      "</ul>" #
      "<p>And to demonstrate that this really is dynamic, you can store and delete keys using " #
      "<a href='https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=" # debug_show my_id() # "'>" #
      "the Candid UI</a>.</p>" #
      "<p>The source of this canister can be found at " #
      "<a href='https://github.com/nomeata/ic-certification/tree/main/demo'>https://github.com/nomeata/ic-certification/tree/main/demo</a>.</p>"
    );
  };

  func value_page(key : Text): Blob {
    switch (ct.lookup(["store", T.encodeUtf8(key)])) {
      case (null) { page_template("<p>Key " # key # " not found.</p>"); };
      case (?v) { page_template(
        "<p>Key " # key # " has value:</p>" #
        "<pre>" # ofUtf8(v) # "</pre>");
      };
    }
  };

/*
To serve HTTP assets, we have to define a query method called `http_request`,
and return the body and the headers. If you don’t care about certification and
just want to serve from <canisterid>.raw.ic0.app, you can do that without
worrying about the ic-certification header.
*/

  type HeaderField = (Text, Text);

  type HttpResponse = {
    status_code: Nat16;
    headers: [HeaderField];
    body: Blob;
  };

  type HttpRequest  = {
    method: Text;
    url: Text;
    headers: [HeaderField];
    body: Blob;
  };

/*
Simple request routing. 
*/
  public query func http_request(req : HttpRequest) : async HttpResponse {
    if (req.method == "GET") {
      // check if / is requested
      if (req.url == "/") {
        // If so, return the main page with with right headers
        return {
          status_code = 200;
          headers = [ ("content-type", "text/html"), certification_header(req.url) ];
          body = main_page()
        }
      };
      switch (T.stripStart(req.url, #text "/get/")) {
        case null {};
        case (?key) {
          return { status_code = 200;
            headers = [ ("content-type", "text/html"), certification_header(req.url) ];
            body = value_page(key);
          }
        }
      };
    };
    // Nothing matched?
    // Else return an error code. Note that we cannot certify this response
    // so a user going to https://ce7vw-haaaa-aaaai-aanva-cai.ic0.app/foo
    // will not see the error message
    return {
      status_code = 404;
      headers = [ ("content-type", "text/plain") ];
      body = "404 Not found.\n This canister only serves /.\n"
    }
  };


/*
We need to store a hash the rendered pages in hash tree.
See <https://internetcomputer.org/docs/current/references/ic-interface-spec#http-gateway> for
the specification.

So this function needs to be called whenever some output changes.

In this demo, when a key is deleted, we actually certify the “key not there” page.
This is not good for production, because the hash tree will ever grow.
*/

  func update_asset_hash(ok : ?Text) {
    // Always update main page
    ct.put(["http_assets", "/"], h(main_page()));
    // Update the page at that key
    switch (ok) {
      case null {};
      case (?k) {
        ct.put(["http_assets", T.encodeUtf8("/get/" # k)], h(value_page(k)));
      }
    };
    // After every modification, we should update the hash.
    ct.setCertifiedData();
  };

/*
After upgrades, the view functions might have changed. So lets recompute all of them.
This may not scale!
*/
  system func postupgrade() {
    ct.delete(["http_assets"]);  // forget about old keys
    for (rk in ct.labelsAt(["store"])) {
        let k = ofUtf8(rk);
        ct.put(["http_assets", T.encodeUtf8("/get/" # k)], h(value_page(k)));
    };
    update_asset_hash(null);
  };

/*
In fact, we should do it during initialization as well, but Motoko’s definedness analysis is
too strict and will not allow the following, and there is no `system func init` in Motoko.
This means it will not validate until the first post call comes in.
*/
  // update_asset_hash();

/*
The other use of the tree is when calculating the ic-certificate header. This header
contains the certificate obtained from the system, which we just pass through,
and a witness calculated from hash tree that reveals the hash of the current
value of the main page.
*/

  func certification_header(url : Text) : HeaderField {
    let witness = ct.reveal(["http_assets", T.encodeUtf8(url)]);
    let encoded = ct.encodeWitness(witness);
    let cert = switch (CertifiedData.getCertificate()) {
      case (?c) c;
      case null {
        // unfortunately, we cannot do
        //   throw Error.reject("getCertificate failed. Call this as a query call!")
        // here, because this function isn’t async, but we can’t make it async
        // because it is called from a query (and it would do the wrong thing) :-(
        //
        // So just return erronous data instead
        "getCertificate failed. Call this as a query call!" : Blob
      }
    };
    return
      ("ic-certificate",
        "certificate=:" # base64(cert) # ":, " #
        "tree=:" # base64(encoded) # ":"
      )
  };

/*
A simple public who-am-I query method, to test request construction and signing.
*/
  public query({caller}) func whoami() : async Text {
    return Principal.toText(caller);
  };

/*
In order to sign requests, we have to store them.
For now, we simply keep track of one request; a real application
would keep a map, with identifiers to correlate the prepare and the fetch call,
as well as deleting old requests.
*/
  type ReqData = {
    time : Time.Time;
    content : ReqData.R;
    request_id : Blob;
    sig_payload_hash : Blob;
    sender_pk : Blob;
  };
  var current_request : ?ReqData = null;

  /*
  The CanisterSigManager
  */
  let csm = CanisterSigs.Manager(ct, null);

  system func preupgrade() {
    csm.pruneAll();
  };

  public func prepare_whoami_request() : async () {
    let now = Time.now();
    let expiry = now + 3*60*1000_000_000;

    let pk = CanisterSigs.publicKey(my_id(), "");
    let id = CanisterSigs.selfAuthenticatingPrincipal(pk);

    let content : ReqData.R = [
        ("request_type", #string("query")),
        ("canister_id", #blob((Principal.toBlob(my_id())))),
        ("method_name", #string("whoami")),
        ("ingress_expiry", #nat(Int.abs(expiry))),
        ("sender", #blob(Principal.toBlob(id))),
        ("arg", #blob("DIDL\00\00"))
    ];

    // Prepare signature
    let request_id = ReqData.hash(content);
    let sig_payload_hash = h2("\0Aic-request", request_id);
    csm.prepare("", sig_payload_hash);

    current_request := ?{
      time = now;
      content = content;
      sender_pk = pk;
      request_id = request_id;
      sig_payload_hash = sig_payload_hash;
    }
  };

  public query func fetch_whoami_request() : async Blob {
    switch (current_request) {
      case null { throw (Error.reject("No request prepared")) };
      case (?req_data) {
        let sig = csm.fetch("", req_data.sig_payload_hash);
        let r : ReqData.R = [
          ("content", #map(req_data.content)),
          ("sender_pubkey", #blob(req_data.sender_pk)),
          ("sender_sig", #blob(sig))
        ];
        ReqData.encodeCBOR(r);
      };
    };
  };

  public query func sigManagerSize() : async Nat {
    csm.size();
  };

/* 
The following is an attempt at a horrible hack to get the certificate in an update method
(to be able to send signed requests to the IC directly).
It uses the http_request feature of the IC with an anonymous query call to
itself to get the certificat.
Unfortuantely, this does not really work: http_request only works when the
responses are equal, and that is not the case (even using a transform function).
So users wanting canisters to sign IC requests should use an external tool to query
for the responses and send them off. 
*/
  public query func strip_headers({response : ManagementCanister.HttpResponse; context : Blob})
    : async ManagementCanister.HttpResponse {
      //return { body = response.body; status = response.status; headers = []}
      return { body = response.body; status = response.status; headers = []}
  };

  public func whoami_request_as_update() : async Blob {
    let now = Time.now();
    let expiry = now + 3*60*1000_000_000;
    let content : ReqData.R = [
      ("request_type", #string("query")),
      ("canister_id", #blob((Principal.toBlob(my_id())))),
      ("method_name", #string("whoami_request")),
      ("ingress_expiry", #nat(Int.abs(expiry))),
      ("sender", #blob("\04")),
      ("arg", #blob("DIDL\00\00"))
    ];
    let r : ReqData.R = [ ("content", #map(content)) ];
    let body = ReqData.encodeCBOR(r);
    ExperimentalCycles.add(1_000_000_000);
    let resp = await ManagementCanister.ic.http_request(
      { url = "https://ic0.app/api/v2/canister/" # Principal.toText(my_id()) # "/query";
        headers = [ {name = "content-type"; value = "application/cbor"} ];
        method = #post;
        max_response_bytes = ?1000;
        body = ?body;
        transform = ?{ context = ""; function = strip_headers; };
      }
    );
    if (resp.status != 200) {
      throw (Error.reject("Self-query-call failed with status " # debug_show resp.status))
    };
    let v = switch (CBOR.decode(resp.body)) {
      case (#ok(v)) v;
      case (#err(e)) { throw (Error.reject("Could not decode body: " # debug_show e) ) };
    };
    throw (Error.reject(debug_show v));
  };

  /*
  An example for sending off a query request to the IC itself
  Only really possible with anonymous requests.
  */
  func unsigned_whoami_request() : Blob {
    let now = Time.now();
    let expiry = now + 3*60*1000_000_000;
    let content : ReqData.R = [
        ("request_type", #string("query")),
        ("canister_id", #blob((Principal.toBlob(my_id())))),
        ("method_name", #string("whoami")),
        ("ingress_expiry", #nat(Int.abs(expiry))),
        ("sender", #blob("\04")),
        ("arg", #blob("DIDL\00\00"))
    ];
    let r : ReqData.R = [ ("content", #map(content)) ];
    ReqData.encodeCBOR(r);
  };

  public func submit_request() : async ManagementCanister.HttpResponse {
    ExperimentalCycles.add(1_000_000_000);
    return await ManagementCanister.ic.http_request(
      { url = "https://ic0.app/api/v2/canister/" # Principal.toText(my_id()) # "/query";
        headers = [ {name = "content-type"; value = "application/cbor"} ];
        method = #post;
        max_response_bytes = ?1000;
        body = ?(unsigned_whoami_request());
        transform = ?{ context = ""; function = strip_headers; };
      }
    );
  };

/*
Convenience function to implement SHA256 on Blobs rather than [Int8]
*/
  func h(b1 : Blob) : Blob {
    SHA256.fromBlob(#sha256, b1)
  };
  func h2(b1 : Blob, b2 : Blob) : Blob {
    let d = SHA256.Digest(#sha256);
    d.writeBlob(b1);
    d.writeBlob(b2);
    d.sum();
  };

/*
Base64 encoding.
(Is there a library around? maybe https://github.com/aviate-labs/encoding.mo?)
*/

  func base64(b : Blob) : Text {
    let base64_chars : [Text] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"];
    let bytes = Blob.toArray(b);
    let pad_len = if (bytes.size() % 3 == 0) { 0 } else {3 - bytes.size() % 3 : Nat};
    let buf = Buffer.fromArray<Nat8>(bytes);
    for (_ in Iter.range(0, pad_len-1)) { buf.add(0)};
    let padded_bytes = Buffer.toArray(buf);
    var out = "";
    for (j in Iter.range(1,padded_bytes.size() / 3)) {
      let i = j - 1 : Nat; // annoying inclusive upper bound in Iter.range
      let b1 = padded_bytes[3*i];
      let b2 = padded_bytes[3*i+1];
      let b3 = padded_bytes[3*i+2];
      let c1 = (b1 >> 2          ) & 63;
      let c2 = (b1 << 4 | b2 >> 4) & 63;
      let c3 = (b2 << 2 | b3 >> 6) & 63;
      let c4 = (b3               ) & 63;
      out #= base64_chars[Nat8.toNat(c1)]
          # base64_chars[Nat8.toNat(c2)]
          # (if (3*i+1 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c3)] })
          # (if (3*i+2 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c4)] });
    };
    return out
  };

  // We put the blobs in the tree, we know they are valid
  func ofUtf8(b: Blob) : Text {
    switch (T.decodeUtf8(b)){
      case (?t) t;
      case null { Debug.trap("Internal error: invalid utf8")};
    }
  };
}


