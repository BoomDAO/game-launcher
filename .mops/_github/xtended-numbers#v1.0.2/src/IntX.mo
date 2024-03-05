import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import NatX "./NatX";
import Util "./Util";
import Result "mo:base/Result";
import Debug "mo:base/Debug";

module {
  public func from64To8(value: Int64) : Int8 {
      Int8.fromInt(Int64.toInt(value));
  };

  public func from64To16(value: Int64) : Int16 {
      Int16.fromInt(Int64.toInt(value));
  };

  public func from64To32(value: Int64) : Int32 {
      Int32.fromInt(Int64.toInt(value));
  };

  public func from64ToInt(value: Int64) : Int {
      Int64.toInt(value);
  };

  
  public func from32To8(value: Int32) : Int8 {
      Int8.fromInt(Int32.toInt(value));
  };

  public func from32To16(value: Int32) : Int16 {
      Int16.fromInt(Int32.toInt(value));
  };

  public func from32To64(value: Int32) : Int64 {
      Int64.fromInt(Int32.toInt(value));
  };

  public func from32ToInt(value: Int32) : Int {
      Int32.toInt(value);
  };


  public func from16To8(value: Int16) : Int8 {
      Int8.fromInt(Int16.toInt(value));
  };

  public func from16To32(value: Int16) : Int32 {
      Int32.fromInt(Int16.toInt(value));
  };

  public func from16To64(value: Int16) : Int64 {
      Int64.fromInt(Int16.toInt(value));
  };

  public func from16ToInt(value: Int16) : Int {
      Int16.toInt(value);
  };


  public func from8To16(value: Int8) : Int16 {
      Int16.fromInt(Int8.toInt(value));
  };

  public func from8To32(value: Int8) : Int32 {
      Int32.fromInt(Int8.toInt(value));
  };

  public func from8To64(value: Int8) : Int64 {
      Int64.fromInt(Int8.toInt(value));
  };

  public func from8ToInt(value: Int8) : Int {
      Int8.toInt(value);
  };



  public func encodeInt(buffer: Buffer.Buffer<Nat8>, value: Int, encoding: {#signedLEB128}) {
    switch(encoding) {
      case (#signedLEB128) {
        if (value == 0) {
          buffer.add(0);
          return;
        };
        // Signed LEB128 - https://en.wikipedia.org/wiki/LEB128#Signed_LEB128
        //         11110001001000000  Binary encoding of 123456
        //   00001_11100010_01000000  As a 21-bit number (multiple of 7)
        //   11110_00011101_10111111  Negating all bits (one's complement)
        //   11110_00011101_11000000  Adding one (two's complement) (Binary encoding of signed -123456)
        // 1111000  0111011  1000000  Split into 7-bit groups
        //01111000 10111011 11000000  Add high 1 bits on all but last (most significant) group to form bytes
        let positiveValue = Int.abs(value);
        var bits: [Bool] = Util.natToLeastSignificantBits(positiveValue, 7, true);
        if (value < 0) {
          // If negative, then get twos compliment
          bits := Util.twosCompliment(bits);
        };
        Util.invariableLengthBytesEncode(buffer, bits);
      };
    };
  };

  public func encodeInt8(buffer: Buffer.Buffer<Nat8>, value: Int8) {
    buffer.add(Int8.toNat8(value));
  };

  public func encodeInt16(buffer: Buffer.Buffer<Nat8>, value: Int16, encoding: {#lsb; #msb}) {
    encodeIntX(buffer, Int64.fromInt(Int16.toInt(value)), encoding, #b16);
  };

  public func encodeInt32(buffer: Buffer.Buffer<Nat8>, value: Int32, encoding: {#lsb; #msb}) {
    encodeIntX(buffer, Int64.fromInt(Int32.toInt(value)), encoding, #b32);
  };

  public func encodeInt64(buffer: Buffer.Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb}) {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, #b64);
  };


  public func decodeInt(bytes: Iter.Iter<Nat8>, encoding: {#signedLEB128}) : ?Int {
    do ? {
      switch(encoding){
        case (#signedLEB128) {
          var bits: [Bool] = Util.invariableLengthBytesDecode(bytes);
          let isNegative = bits[bits.size() - 1];
          if (isNegative) {
            // Reverse twos compliment
            bits := Util.reverseTwosCompliment(bits);
          };
          var i = 0;
          let int = Array.foldLeft<Bool, Int>(bits, 0, func (accum: Int, bit: Bool) {
            let newAccum = if (bit) {
              accum + Nat.pow(2, i); // Shift over 7 * i bits to get value to add, ignore first bit
            } else {
              accum;
            };
            i += 1;
            newAccum;
          });
          if (isNegative){
            int * -1
          } else {
            int
          };
        };
      };
    };
  };

  public func decodeInt8(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int8 {
    do ? { 
      let bits: [Bool] = decodeIntX(bytes, encoding, #b8)!;
      bitsToInt<Int8>(bits, 0, Int8.bitset);
    };
  };

  public func decodeInt16(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int16 {
    do ? { 
      let bits: [Bool] = decodeIntX(bytes, encoding, #b16)!;
      bitsToInt<Int16>(bits, 0, Int16.bitset);
    };
  };

  public func decodeInt32(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int32 {
    do ? { 
      let bits: [Bool] = decodeIntX(bytes, encoding, #b32)!;
      bitsToInt<Int32>(bits, 0, Int32.bitset);
    };
  };

  public func decodeInt64(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int64 {
    do ? { 
      let bits: [Bool] = decodeIntX(bytes, encoding, #b64)!;
      bitsToInt<Int64>(bits, 0, Int64.bitset);
    }
  };



  private func decodeIntX(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}, size: {#b8; #b16; #b32; #b64}) : ?[Bool] {
    do ? {
      let byteLength: Nat64 = getByteLength(size);
      var nat64 : Nat64 = 0;
      let lastIndex : Nat64 = byteLength - 1;
      for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
        let b: Nat8 = bytes.next()!;
        let byteOffset: Nat64 = switch (encoding) {
          case (#lsb) Nat64.fromNat(i);
          case (#msb) Nat64.fromNat(Nat64.toNat(byteLength-1) - i);
        };
        nat64 |= NatX.from8To64(b) << (byteOffset * 8);
      };
      // Convert to bits in LSB order
      var bits: [Bool] = Array.tabulate<Bool>(Nat64.toNat(byteLength * 8), func(i: Nat) { Nat64.bittest(nat64, i) });
      bits
    }
  };

  private func bitsToInt<T>(bits: [Bool], initial: T, bitset: (T, Nat) -> T) : T {
      var bitOffset = 0;
      Array.foldLeft<Bool, T>(bits, initial, func (accum: T, x: Bool) {
        let newAccum: T = if (not x) {
          accum; // Dont set if 0
        } else {
          bitset(accum, bitOffset); // Set if 1
        };
        bitOffset += 1;
        newAccum;
      });
  };

  private func getByteLength(size: {#b8; #b16; #b32; #b64}) : Nat64 {
    switch(size) {
      case (#b8) 1;
      case (#b16) 2;
      case (#b32) 4;
      case (#b64) 8;
    }
  };


  private func encodeIntX(buffer: Buffer.Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb}, size: {#b16; #b32; #b64}) {
    let byteLength: Nat64 = getByteLength(size);
    for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
      let byteOffset: Int64 = switch (encoding) {
        case (#lsb) Int64.fromInt(i);
        case (#msb) Int64.fromInt(Nat64.toNat(byteLength - 1) - i);
      };
      let byte: Int64 = (value >> (byteOffset * 8)) & 0xff;
      buffer.add(Nat8.fromNat(Int.abs(Int64.toInt(byte))));
    };
  };

}