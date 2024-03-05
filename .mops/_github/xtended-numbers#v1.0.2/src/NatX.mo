import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Util "./Util";

module {
  public func from64To8(value: Nat64) : Nat8 {
      Nat8.fromNat(Nat64.toNat(value));
  };

  public func from64To16(value: Nat64) : Nat16 {
      Nat16.fromNat(Nat64.toNat(value));
  };

  public func from64To32(value: Nat64) : Nat32 {
      Nat32.fromNat(Nat64.toNat(value));
  };

  public func from64ToNat(value: Nat64) : Nat {
      Nat64.toNat(value);
  };

  
  public func from32To8(value: Nat32) : Nat8 {
      Nat8.fromNat(Nat32.toNat(value));
  };

  public func from32To16(value: Nat32) : Nat16 {
      Nat16.fromNat(Nat32.toNat(value));
  };

  public func from32To64(value: Nat32) : Nat64 {
      Nat64.fromNat(Nat32.toNat(value));
  };

  public func from32ToNat(value: Nat32) : Nat {
      Nat32.toNat(value);
  };


  public func from16To8(value: Nat16) : Nat8 {
      Nat8.fromNat(Nat16.toNat(value));
  };

  public func from16To32(value: Nat16) : Nat32 {
      Nat32.fromNat(Nat16.toNat(value));
  };

  public func from16To64(value: Nat16) : Nat64 {
      Nat64.fromNat(Nat16.toNat(value));
  };

  public func from16ToNat(value: Nat16) : Nat {
      Nat16.toNat(value);
  };


  public func from8To16(value: Nat8) : Nat16 {
      Nat16.fromNat(Nat8.toNat(value));
  };

  public func from8To32(value: Nat8) : Nat32 {
      Nat32.fromNat(Nat8.toNat(value));
  };

  public func from8To64(value: Nat8) : Nat64 {
      Nat64.fromNat(Nat8.toNat(value));
  };

  public func from8ToNat(value: Nat8) : Nat {
      Nat8.toNat(value);
  };


  public func encodeNat(buffer: Buffer.Buffer<Nat8>, value: Nat, encoding: {#unsignedLEB128}) {
    switch(encoding) {
      case (#unsignedLEB128) {
        if (value == 0) {
          buffer.add(0);
          return;
        };
        // Unsigned LEB128 - https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128
        //       10011000011101100101  In raw binary
        //      010011000011101100101  Padded to a multiple of 7 bits
        //  0100110  0001110  1100101  Split into 7-bit groups
        // 00100110 10001110 11100101  Add high 1 bits on all but last (most significant) group to form bytes
        let bits: [Bool] = Util.natToLeastSignificantBits(value, 7, false);
        
        Util.invariableLengthBytesEncode(buffer, bits);
      };
    };
  };

  public func encodeNat8(buffer: Buffer.Buffer<Nat8>, value: Nat8) {
    buffer.add(value);
  };

  public func encodeNat16(buffer: Buffer.Buffer<Nat8>, value: Nat16, encoding: {#lsb; #msb}) {
    encodeNatX(buffer, Nat64.fromNat(Nat16.toNat(value)), encoding, #b16);
  };

  public func encodeNat32(buffer: Buffer.Buffer<Nat8>, value: Nat32, encoding: {#lsb; #msb}) {
    encodeNatX(buffer, Nat64.fromNat(Nat32.toNat(value)), encoding, #b32);
  };

  public func encodeNat64(buffer: Buffer.Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb}) {
    encodeNatX(buffer, value, encoding, #b64);
  };


  public func decodeNat(bytes: Iter.Iter<Nat8>, encoding: {#unsignedLEB128}) : ?Nat {  
      do ? {  
        var v: Nat = 0;
        var i: Nat = 0;
        label l loop {
          let byte: Nat8 = bytes.next()!;
          v += Nat8.toNat(byte & 0x7f) * Nat.pow(2, 7 * i); // Shift over 7 * i bits to get value to add, ignore first bit
          i += 1;
          let hasNextByte = (byte & 0x80) == 0x80; // If starts with a 1, there is another byte
          if (not hasNextByte) {
            break l;
          };
        };
        v
      };
  };

  public func decodeNat8(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat8 {
    bytes.next();
  };

  public func decodeNat16(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat16 {
    do ? { 
      let value: Nat64 = decodeNatX(bytes, encoding, #b16)!;
      from64To16(value);
    };
  };

  public func decodeNat32(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat32 {
    do ? { 
      let value: Nat64 = decodeNatX(bytes, encoding, #b32)!;
      from64To32(value);
    };
  };

  public func decodeNat64(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat64 {
    decodeNatX(bytes, encoding, #b64);
  };



  private func decodeNatX(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}, size: {#b16; #b32; #b64}) : ?Nat64 {
    do ? {
      let byteLength: Nat64 = getByteLength(size);
      var nat64 : Nat64 = 0;
      let lastIndex : Nat64 = byteLength - 1;
      for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
        let b = from8To64(bytes.next()!);
        let byteOffset: Nat64 = switch (encoding) {
          case (#lsb) Nat64.fromNat(i);
          case (#msb) Nat64.fromNat(Nat64.toNat(byteLength-1) - i);
        };
        nat64 |= b << (byteOffset * 8);
      };
      nat64;
    }
  };

  private func encodeNatX(buffer: Buffer.Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb}, size: {#b16; #b32; #b64}) {
    let byteLength: Nat64 = getByteLength(size);
    for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
      let byteOffset: Nat64 = switch (encoding) {
        case (#lsb) Nat64.fromNat(i);
        case (#msb) Nat64.fromNat(Nat64.toNat(byteLength-1) - i);
      };
      let byte: Nat8 = from64To8((value >> (byteOffset * 8)) & 0xff);
      buffer.add(byte);
    };
  };


  private func getByteLength(size: {#b16; #b32; #b64}) : Nat64 {
    switch(size) {
      case (#b16) 2;
      case (#b32) 4;
      case (#b64) 8;
    }
  };
}