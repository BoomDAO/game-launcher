import NatX "mo:xtended-numbers/NatX";
import FloatX "mo:xtended-numbers/FloatX";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Errors "./Errors";
import Util "./Util";
import Value "./Value";

module {

  public func decode(blob : Blob) : Result.Result<Value.Value, Errors.DecodingError> {
    let decoder = CborDecoder(blob.vals());
    decoder.decode();
  };

  private class CborDecoder(bytes : Iter.Iter<Nat8>) {
    var byte_position : Nat = 0;
    let iterator : Iter.Iter<Nat8> = bytes;

    public func decode() : Result.Result<Value.Value, Errors.DecodingError> {
      decodeInternal(false);
    };

    private func decodeInternal(allowBreak : Bool) : Result.Result<Value.Value, Errors.DecodingError> {
      let firstByte : Nat8 = switch (readByte()) {
        case (null) {
          return #err(#unexpectedEndOfBytes);
        };
        case (?firstByte) firstByte;
      };
      let (majorType, additionalBits) = parseMajorType(firstByte);
      let result = switch (majorType) {
        case (0) parseMajorType0(additionalBits);
        case (1) parseMajorType1(additionalBits);
        case (2) parseMajorType2(additionalBits);
        case (3) parseMajorType3(additionalBits);
        case (4) parseMajorType4(additionalBits);
        case (5) parseMajorType5(additionalBits);
        case (6) parseMajorType6(additionalBits);
        case (7) parseMajorType7(additionalBits);
        case _ return #err(#invalid("Invalid major type: " # Nat8.toText(majorType)));
      };
      if (not allowBreak) {
        return switch (result) {
          case (#ok(#majorType7(#_break))) #err(#unexpectedBreak);
          case (a) a;
        };
      };
      result;
    };

    private func parseMajorType0(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let value = switch (getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) {
          switch (decodeAdditionalBytes(b)) {
            case (#err(e)) return #err(e);
            case (#ok(v)) v;
          };
        };
        case (#ok(#indef)) return #err(#invalid("Major type 0 does not support 31 for additional bits"));
        case (#err(x)) return #err(x);
      };
      #ok(#majorType0(value));
    };

    private func parseMajorType1(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let value : Nat64 = switch (getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) {
          switch (decodeAdditionalBytes(b)) {
            case (#err(e)) return #err(e);
            case (#ok(v)) v;
          };
        };
        case (#ok(#indef)) return #err(#invalid("Major type 1 does not support 31 for additional bits"));
        case (#err(x)) return #err(x);
      };

      let intValue : Int = convertBitsToInt(value);
      #ok(#majorType1(intValue));
    };

    private func convertBitsToInt(value : Nat64) : Int {
      let maxInt64Value : Nat64 = 0x7FFFFFFFFFFFFFFF;
      var intValue : Int = if (value > maxInt64Value) {
        // If value is larger than Int64 can handle, break it up into Int pieces and then add those
        var overflowCount = 1;
        var v : Nat64 = value - maxInt64Value;
        if (v > maxInt64Value) {
          v := v - maxInt64Value;
          overflowCount := 2;
        };
        var intValue : Int = Int64.toInt(Int64.fromNat64(v));
        while (overflowCount > 0) {
          // Add back each overflow
          intValue += Int64.toInt(Int64.fromNat64(maxInt64Value));
          overflowCount -= 1;
        };
        intValue;
      } else {
        // Otherwise just convert it
        Int64.toInt(Int64.fromNat64(value));
      };
      -1 - intValue; // Real value is (-1 - value)
    };

    private func parseMajorType2(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let byte_value = switch (getAdditionalBitsByteValue(additionalBits, 2)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      #ok(#majorType2(byte_value));
    };

    private func parseMajorType3(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let byte_value = switch (getAdditionalBitsByteValue(additionalBits, 3)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      let blob = Blob.fromArray(byte_value);
      let text_value : Text = switch (Text.decodeUtf8(blob)) {
        case (null) return #err(#invalid("Invalid UTF8 String: " # debug_show (blob)));
        case (?v) v;
      };
      #ok(#majorType3(text_value));
    };

    private func parseMajorType4(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let array_length : Nat64 = switch (getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) {
          switch (decodeAdditionalBytes(b)) {
            case (#err(e)) return #err(e);
            case (#ok(v)) v;
          };
        };
        case (#ok(#indef)) {
          // Loop indefinitely for each array item
          let buffer = Buffer.Buffer<Value.Value>(1);
          label l loop {
            let cbor_value : Value.Value = switch (decodeInternal(true)) {
              case (#err(e)) return #err(e);
              case (#ok(#majorType7(#_break))) break l;
              case (#ok(v)) v;
            };
            buffer.add(cbor_value);
          };
          return #ok(#majorType4(Buffer.toArray(buffer)));
        };
        case (#err(x)) return #err(x);
      };
      let buffer = Buffer.Buffer<Value.Value>(Nat64.toNat(array_length));
      for (i in Iter.range(1, Nat64.toNat(array_length))) {
        let cbor_value : Value.Value = switch (decodeInternal(false)) {
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
        buffer.add(cbor_value);
      };
      #ok(#majorType4(Buffer.toArray(buffer)));
    };

    private func parseMajorType5(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let map_size : Nat64 = switch (getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) {
          switch (decodeAdditionalBytes(b)) {
            case (#err(e)) return #err(e);
            case (#ok(v)) v;
          };
        };
        case (#ok(#indef)) {
          // Loop indefinitely for each array item
          let buffer = Buffer.Buffer<(Value.Value, Value.Value)>(1);
          label l loop {
            let (key, value) = switch (decodeKeyValuePair()) {
              case (#err(#unexpectedBreak)) break l;
              case (#err(e)) return #err(e);
              case (#ok(v)) v;
            };
            buffer.add((key, value));
          };
          return #ok(#majorType5(Buffer.toArray(buffer)));
        };
        case (#err(x)) return #err(x);
      };
      let buffer = Buffer.Buffer<(Value.Value, Value.Value)>(Nat64.toNat(map_size));
      for (i in Iter.range(1, Nat64.toNat(map_size))) {
        let (key, value) = switch (decodeKeyValuePair()) {
          case (#err(e)) return #err(e);
          case (#ok(v)) v;
        };
        buffer.add((key, value));
      };
      #ok(#majorType5(Buffer.toArray(buffer)));
    };

    private func parseMajorType6(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      let tag : Nat64 = switch (getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat64.fromNat(Nat8.toNat(n)); // Convert number to value
        case (#ok(#bytes(b))) {
          switch (decodeAdditionalBytes(b)) {
            case (#err(e)) return #err(e);
            case (#ok(v)) v;
          };
        };
        case (#ok(#indef)) return #err(#invalid("Value 31 is not allowed for additional bits for major type 6"));
        case (#err(x)) return #err(x);
      };
      let value : Value.Value = switch (decodeInternal(false)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      #ok(#majorType6({ tag = tag; value = value }));
    };

    private func parseMajorType7(additionalBits : Nat8) : Result.Result<Value.Value, Errors.DecodingError> {
      if (additionalBits == 0xff) {
        // ff -> break code
        return #ok(#majorType7(#_break));
      };
      // 0..24 are simple values
      if (additionalBits <= 23) {
        let simple = switch (additionalBits) {
          case (20) #bool(false);
          case (21) #bool(true);
          case (22) #_null;
          case (23) #_undefined;
          case (a) #integer(a);
        };
        return #ok(#majorType7(simple));
      };
      if (additionalBits == 24) {
        // 24 indicates that the next byte has the simple value (excluding 0..31)
        let byte = switch (readByte()) {
          case (null) return #err(#unexpectedEndOfBytes);
          case (?v) {
            if (v <= 31) {
              return #err(#invalid("Simple value 0 to 31 is not allowed in the extra byte"));
            };
            #integer(v);
          };
        };
        return #ok(#majorType7(byte));
      };
      // If 25..27, then the value is a float (half, single, double)
      let (byteLength, precision) = switch (additionalBits) {
        case (25)(2, #f16); // Half, 16 bit
        case (26)(4, #f32); // Single, 32 bit
        case (27)(8, #f64); // Double, 64 bit
        case (31) return #ok(#majorType7(#_break));
        case (b) return #err(#invalid("Invalid additional bits value: " # Nat8.toText(b)));
      };
      let value = switch (readBytes(byteLength)) {
        case (null) return #err(#unexpectedEndOfBytes);
        case (?v) {
          switch (FloatX.decode(Iter.fromArray(v), precision, #msb)) {
            case (null) return #err(#invalid("Invalid float value"));
            case (?v) v;
          };
        };
      };
      #ok(#majorType7(#float(value)));
    };

    private func parseMajorType(byte : Nat8) : (Nat8, Nat8) {
      let majorType : Nat8 = (byte >> 5) & 0x07; // Get first 3 bits
      let additionalBits : Nat8 = byte & 0x1F; // Get last 5 bits
      (majorType, additionalBits);
    };

    private func readByte() : ?Nat8 {
      byte_position += 1;
      return iterator.next();
    };

    private func readBytes(n : Nat) : ?[Nat8] {
      if (n < 1) {
        return ?[];
      };
      let iter : Iter.Iter<Nat> = Iter.range(1, n);
      let buffer = Buffer.Buffer<Nat8>(n);
      for (i in iter) {
        let byte = switch (readByte()) {
          case (null) return null;
          case (?byte) byte;
        };
        buffer.add(byte);
      };
      return ?Buffer.toArray(buffer);
    };

    private func readIndefBytes(chunkedMajorType : ?Nat8) : Result.Result<[Nat8], Errors.DecodingError> {
      let buffer = Buffer.Buffer<Nat8>(1);
      label l loop {
        let byte = switch (readByte()) {
          case (null) return #err(#unexpectedEndOfBytes);
          case (?byte) byte;
        };
        if (byte == 0xff) {
          break l; // Reached end of indefinate byte sequence
        };
        switch (chunkedMajorType) {
          case (null) buffer.add(byte); // byte is actual byte value
          case (?t) {
            // byte represents major type/additional bits of next byte chunk
            let (majorType, additionalBits) = parseMajorType(byte);
            if (majorType != t) {
              return #err(#invalid("Major type " # Nat8.toText(majorType) # " expected, got " # Nat8.toText(t)));
            };

            let bytes = switch (readBytes(Nat8.toNat(additionalBits))) {
              case (null) return #err(#unexpectedEndOfBytes);
              case (?v) v;
            };
            Util.appendArrayToBuffer(buffer, bytes);
          };
        };
      };
      return #ok(Buffer.toArray(buffer));
    };

    private func decodeKeyValuePair() : Result.Result<(Value.Value, Value.Value), Errors.DecodingError> {
      let key : Value.Value = switch (decodeInternal(false)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      let value : Value.Value = switch (decodeInternal(false)) {
        case (#err(e)) return #err(e);
        case (#ok(v)) v;
      };
      #ok((key, value));
    };

    private func decodeAdditionalBytes(bytes : [Nat8]) : Result.Result<Nat64, Errors.DecodingError> {
      let iter = Iter.fromArray(bytes);
      // Convert bytes to value
      let result : ?Nat64 = switch (bytes.size()) {
        case (1) do ? { NatX.from8To64(NatX.decodeNat8(iter, #msb)!) };
        case (2) do ? { NatX.from16To64(NatX.decodeNat16(iter, #msb)!) };
        case (4) do ? { NatX.from32To64(NatX.decodeNat32(iter, #msb)!) };
        case (8) NatX.decodeNat64(iter, #msb);
        case (s) return #err(#invalid("Invalid additional bytes size: " # Nat.toText(s)));
      };
      switch (result) {
        case (null) #err(#unexpectedEndOfBytes);
        case (?v) #ok(v);
      };
    };

    private func getAdditionalBitsByteValue(additionalBits : Nat8, majorType : Nat8) : Result.Result<[Nat8], Errors.DecodingError> {
      let bytes_to_read : Nat = switch (getAdditionalBitsValue(additionalBits)) {
        case (#ok(#num(n))) Nat8.toNat(n); // Convert number to length
        case (#ok(#bytes(b))) {
          switch (decodeAdditionalBytes(b)) {
            case (#err(e)) return #err(e);
            case (#ok(v)) Nat64.toNat(v);
          };
        };
        case (#ok(#indef)) {
          // Read indefinite length of bytes
          let indef_bytes = switch (readIndefBytes(?majorType)) {
            case (#err(e)) return #err(e);
            case (#ok(b)) b;
          };
          return #ok(indef_bytes);
        };
        case (#err(x)) return #err(x);
      };
      let bytes = switch (readBytes(bytes_to_read)) {
        // Read the byte strng
        case (null) return #err(#unexpectedEndOfBytes);
        case (?b) b;
      };
      #ok(bytes);
    };

    private func getAdditionalBitsValue(additionalBits : Nat8) : Result.Result<{ #num : Nat8; #bytes : [Nat8]; #indef }, Errors.DecodingError> {
      // Check additional bits for value
      // 23 or less => additional bits is the value
      // 24 => read 1 more byte for value
      // 25 => read 2 more bytes for value
      // 26 => read 4 more bytes for value
      // 27 => read 8 more bytes for value

      if (additionalBits <= 23) {
        return #ok(#num(additionalBits));
      };
      let content_byte_length : Nat = switch (additionalBits) {
        case (24) 1;
        case (25) 2;
        case (26) 4;
        case (27) 8;
        case (31) return #ok(#indef);
        case a {
          let message = "Invalid additional bits value: " # Nat8.toText(additionalBits);
          return #err(#invalid(message));
        };
      };
      let value_bytes : [Nat8] = switch (readBytes(content_byte_length)) {
        case (null) return #err(#unexpectedEndOfBytes);
        case (?b) b;
      };
      #ok(#bytes(value_bytes));
    };

  };
};
