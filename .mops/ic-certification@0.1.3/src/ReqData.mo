/// **Internet Computer Request Data**
///
/// This library provides functionality for the data structures encountered when interacting
/// with the Internet Computer, in particular its HTTP API, certificates and canister signatures.
///
/// This contains the generic functionality: A data type `R` for such values,
/// CBOR encoding (`encodeCBOR`) and the “[Representation-independent hash[” (`hash`).
///
/// [Representation-independent hash]: <https://internetcomputer.org/docs/current/references/ic-interface-spec#hash-of-map>

import SHA256 "mo:sha2/Sha256";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import CV "mo:cbor/Value";
import CBOR "mo:cbor/Encoder";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";

module {

  type Hash = Blob;

  /// A generic record or map of value
  public type R = [(Text, V)];

  /// A structured value
  public type V = {
    #blob : Blob;
    #string : Text;
    #nat : Nat;
    #array : [V];
    #map : R;
  };

  /// Calculate the representation-independent hash
  public func hash(r : R) : Blob { Blob.fromArray(hash_val(#map(r))) };

  /// CBOR-encode the value (including the CBOR self-describing tag)
  public func encodeCBOR(r : R) : Blob {
    let v : CV.Value = #majorType6{ tag = 55799; value = fromR(r) };
    
    switch (CBOR.encode(v)) {
      case (#ok(a)) { Blob.fromArray(a)};
      case (#err(e)) { Debug.trap(debug_show e) };
    };
  };

  func fromR(r : R) : CV.Value {
    #majorType5(Array.map<(Text,V),(CV.Value,CV.Value)>(r,
      func ((k, v))  { (fromV(#string k), fromV(v)) }
    ))
  };
  func fromV(v : V) : CV.Value {
    switch (v) {
      case (#blob(b))   { #majorType2(Blob.toArray(b)) };
      case (#string(t)) { #majorType3(t) };
      case (#nat(n))    { #majorType0(Nat64.fromNat(n)) };
      case (#array(a))  { #majorType4(Array.map(a, fromV)) };
      case (#map(m))    { fromR(m) };
    }
  };

  // Also see https://github.com/dfinity/ic-hs/blob/master/src/IC/HTTP/RequestId.hs
  func hash_val(v : V) : [Nat8] {
    encode_val(v) |> SHA256.fromArray(#sha256, _) |> Blob.toArray _
  };

  func encode_val(v : V) : [Nat8] {
    switch (v) {
      case (#blob(b))   { Blob.toArray(b) };
      case (#string(t)) { Blob.toArray(Text.encodeUtf8(t)) };
      case (#nat(n))    { leb128(n) };
      case (#array(a))  { arrayConcat(Iter.map(a.vals(), hash_val)); };
      case (#map(m))    {
        let entries : Buffer.Buffer<Blob> = Buffer.fromIter(Iter.map(m.vals(), func ((k : Text, v : V)) : Blob {
            Blob.fromArray(arrayConcat([ hash_val(#string(k)), hash_val(v) ].vals()));
        }));
        entries.sort(Blob.compare); // No Array.compare, so go through blob
        arrayConcat(Iter.map(entries.vals(), Blob.toArray));
      }
    }
  };

  func leb128(nat : Nat) : [Nat8] {
    var n = nat;
    let buf = Buffer.Buffer<Nat8>(3);
    loop {
      if (n <= 127) {
        buf.add(Nat8.fromNat(n));
        return Buffer.toArray(buf);
      };
      buf.add(Nat8.fromIntWrap(n) | 0x80);
      n /= 128;
    }
  };

  func h(b1 : Blob) : Blob {
    SHA256.fromBlob(#sha256, b1);
  };

  // Missing in standard library? Faster implementation?
  func bufferAppend<X>(buf : Buffer.Buffer<X>, a : [X]) {
    for (x in a.vals()) { buf.add(x) };
  };

  // Array concat
  func arrayConcat<X>(as : Iter.Iter<[X]>) : [X] {
    let buf = Buffer.Buffer<X>(0);
    for (a in as) { bufferAppend(buf, a) };
    Buffer.toArray(buf);
  };

}
