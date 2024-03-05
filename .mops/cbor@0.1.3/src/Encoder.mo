import NatX "mo:xtended-numbers/NatX";
import FloatX "mo:xtended-numbers/FloatX";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Util "./Util";
import Errors "./Errors";
import Value "./Value";

module {
  public func encode(value : Value.Value) : Result.Result<[Nat8], Errors.EncodingError> {
    let buffer = Buffer.Buffer<Nat8>(10);
    switch (encodeToBuffer(buffer, value)) {
      case (#ok) #ok(Buffer.toArray(buffer));
      case (#err(e)) #err(e);
    };
  };

  public func encodeToBuffer(buffer : Buffer.Buffer<Nat8>, value : Value.Value) : Result.Result<(), Errors.EncodingError> {
    switch (value) {
      case (#majorType0(t0)) encodeMajorType0(buffer, t0);
      case (#majorType1(t1)) encodeMajorType1(buffer, t1);
      case (#majorType2(t2)) encodeMajorType2(buffer, t2);
      case (#majorType3(t3)) encodeMajorType3(buffer, t3);
      case (#majorType4(t4)) encodeMajorType4(buffer, t4);
      case (#majorType5(t5)) encodeMajorType5(buffer, t5);
      case (#majorType6(t6)) encodeMajorType6(buffer, t6.tag, t6.value);
      case (#majorType7(t7)) {
        switch (t7) {
          case (#_break) return #err(#invalidValue("Break is not allowed as a value"));
          case (#_null) encodeMajorType7(buffer, #_null);
          case (#_undefined) encodeMajorType7(buffer, #_undefined);
          case (#bool(b)) encodeMajorType7(buffer, #bool(b));
          case (#float(f)) encodeMajorType7(buffer, #float(f));
          case (#integer(i)) encodeMajorType7(buffer, #integer(i));
        };
      };
    };
  };

  public func encodeMajorType0(buffer : Buffer.Buffer<Nat8>, value : Nat64) : Result.Result<(), Errors.EncodingError> {
    encodeNatHeaderInternal(buffer, 0, value);
    return #ok();
  };

  public func encodeMajorType1(buffer : Buffer.Buffer<Nat8>, value : Int) : Result.Result<(), Errors.EncodingError> {
    let maxValue : Int = -1;
    let minValue : Int = -0x10000000000000000;
    if (value > maxValue or value < minValue) {
      return #err(#invalidValue("Major type 1 values must be between -2^64 and -1"));
    };
    // Convert negative number (-1 - N) to Nat (N) to store as bytes
    let natValue : Nat = Int.abs(value + 1);
    encodeNatHeaderInternal(buffer, 1, Nat64.fromNat(natValue));
    return #ok();
  };

  public func encodeMajorType2(buffer : Buffer.Buffer<Nat8>, value : [Nat8]) : Result.Result<(), Errors.EncodingError> {
    // Value is header bits + value bytes
    // Header is major type and value byte length
    let byteLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 2, byteLength);
    for (b in Iter.fromArray(value)) {
      buffer.add(b);
    };
    #ok();
  };

  public func encodeMajorType3(buffer : Buffer.Buffer<Nat8>, value : Text) : Result.Result<(), Errors.EncodingError> {

    // Value is header bits + utf8 encoded string bytes
    // Header is major type and utf8 byte length
    let utf8Bytes = Text.encodeUtf8(value);
    let byteLength : Nat64 = Nat64.fromNat(utf8Bytes.size());
    encodeNatHeaderInternal(buffer, 3, byteLength);
    for (utf8Byte in utf8Bytes.vals()) {
      buffer.add(utf8Byte);
    };
    #ok();
  };

  public func encodeMajorType4(buffer : Buffer.Buffer<Nat8>, value : [Value.Value]) : Result.Result<(), Errors.EncodingError> {
    let arrayLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 4, arrayLength);
    // Value is header bits + concatenated encoded cbor values
    // Header is major type and array length
    for (v in Iter.fromArray(value)) {
      switch (encodeToBuffer(buffer, v)) {
        case (#err(e)) return #err(e);
        case (#ok) {};
      };
    };
    #ok();
  };

  public func encodeMajorType5(buffer : Buffer.Buffer<Nat8>, value : [(Value.Value, Value.Value)]) : Result.Result<(), Errors.EncodingError> {
    let arrayLength : Nat64 = Nat64.fromNat(value.size());
    encodeNatHeaderInternal(buffer, 5, arrayLength);
    // Value is header bits + concatenated encoded cbor key value map pairs
    // Header is major type and map key length
    for ((k, v) in Iter.fromArray(value)) {
      switch (encodeToBuffer(buffer, k)) {
        case (#err(e)) return #err(e);
        case (#ok(b)) b;
      };
      switch (encodeToBuffer(buffer, v)) {
        case (#err(e)) return #err(e);
        case (#ok(b)) b;
      };
    };
    #ok();
  };

  public func encodeMajorType6(buffer : Buffer.Buffer<Nat8>, tag : Nat64, value : Value.Value) : Result.Result<(), Errors.EncodingError> {
    encodeNatHeaderInternal(buffer, 6, tag);
    // Value is header bits + concatenated encoded cbor value
    // Header is major type and tag value
    encodeToBuffer(buffer, value);
  };

  public func encodeMajorType7(buffer : Buffer.Buffer<Nat8>, value : { #integer : Nat8; #bool : Bool; #_null; #_undefined; #float : FloatX.FloatX }) : Result.Result<(), Errors.EncodingError> {
    let (additionalBits : Nat8, additionalBytes : ?Buffer.Buffer<Nat8>) = switch (value) {
      case (#bool(false))(20 : Nat8, null);
      case (#bool(true))(21 : Nat8, null);
      case (#_null)(22 : Nat8, null);
      case (#_undefined)(23 : Nat8, null);
      case (#integer(i)) {
        if (i <= 19) {
          (i, null);
        } else if (i <= 31) {
          // Invalid values, since it is redundant
          return #err(#invalidValue("Major Type 7 ineter "));
        } else {
          let innerBuffer = Buffer.Buffer<Nat8>(1);
          innerBuffer.add(i);
          (24 : Nat8, ?innerBuffer);
        };
      };
      case (#float(f)) {
        let floatBytesBuffer = Buffer.Buffer<Nat8>(8);
        FloatX.encode(floatBytesBuffer, f, #msb);
        let n : Nat8 = switch (f.precision) {
          case (#f16) 25;
          case (#f32) 26;
          case (#f64) 27;
        };
        (n, ?floatBytesBuffer);
      };
    };
    encodeRaw(buffer, 7, additionalBits, additionalBytes);
    #ok();
  };

  private func encodeRaw(buffer : Buffer.Buffer<Nat8>, majorType : Nat8, additionalBits : Nat8, additionalBytes : ?Buffer.Buffer<Nat8>) {
    let firstByte : Nat8 = majorType << 5 + additionalBits;
    // Concatenate the header byte and the additional bytes (if available)
    buffer.add(firstByte);

    switch (additionalBytes) {
      case (null) {};
      case (?bytes) {
        buffer.append(bytes);
      };
    };
  };

  private func encodeNatHeaderInternal(buffer : Buffer.Buffer<Nat8>, majorType : Nat8, value : Nat64) {
    let (additionalBits : Nat8, additionalBytes : ?Buffer.Buffer<Nat8>) = if (value <= 23) {
      (Nat8.fromNat(Nat64.toNat(value)), null);
    } else {
      let addBitsBuffer = Buffer.Buffer<Nat8>(8);
      let additionalBits : Nat8 = if (value <= 0xff) {
        addBitsBuffer.add(Nat8.fromNat(Nat64.toNat(value)));
        24;
      } else if (value <= 0xffff) {
        NatX.encodeNat16(addBitsBuffer, Nat16.fromNat(Nat64.toNat(value)), #msb);
        25 // 25 indicates 2 more bytes of info
      } else if (value <= 0xffffffff) {
        NatX.encodeNat32(addBitsBuffer, Nat32.fromNat(Nat64.toNat(value)), #msb);
        26 // 26 indicates 4 more bytes of info
      } else {
        NatX.encodeNat64(addBitsBuffer, value, #msb);
        27 // 27 indicates 8 more bytes of info
      };
      (additionalBits, ?addBitsBuffer);
    };
    encodeRaw(buffer, majorType, additionalBits, additionalBytes);
  };

};
