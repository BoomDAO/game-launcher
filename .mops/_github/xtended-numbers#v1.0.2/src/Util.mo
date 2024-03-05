import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";

module {
  public func natToLeastSignificantBits(value: Nat, byteLength: Nat, hasSign: Bool) : [Bool] {
    let buffer = Buffer.Buffer<Bool>(64);
    var remainingValue: Nat = value;
    while (remainingValue > 0) {
      let bit: Bool = remainingValue % 2 == 1;
      buffer.add(bit);
      remainingValue /= 2;
    };
    while (buffer.size() % byteLength != 0) {
      buffer.add(false); // Pad 0's for full byte
    };
    if (hasSign) {
        let mostSignificantBit: Bool = buffer.get(buffer.size() - 1);
        if (mostSignificantBit) {
            // If most significant bit is a 1, overflow to another byte
            for (i in Iter.range(1, byteLength)) {
                buffer.add(false);
            };
        };
    };
    // Least Sigficant Bit first
    Buffer.toArray(buffer);
  };

  public func invariableLengthBytesEncode(buffer: Buffer.Buffer<Nat8>, bits: [Bool]) {
    
    let byteCount: Nat = (bits.size() / 7) + (if (bits.size() % 7 != 0) 1 else 0); // 7, not 8, the 8th bit is to indicate end of number
    
    label f for (byteIndex in Iter.range(0, byteCount - 1))
    {
        var byte: Nat8 = 0;
        for (bitOffset in Iter.range(0, 6)) {
            let bit: Bool = bits[byteIndex * 7 + bitOffset];
            if (bit) {
                // Set bit
                byte := Nat8.bitset(byte, bitOffset);
            };
        };
        let hasMoreBits = bits.size() > (byteIndex + 1) * 7;
        if (hasMoreBits)
        {
            // Have most left of byte be 1 if there is another byte
            byte := Nat8.bitset(byte, 7);
        };
        buffer.add(byte);
    };
  };

  public func invariableLengthBytesDecode(bytes: Iter.Iter<Nat8>) : [Bool] {
    
    let buffer = Buffer.Buffer<Bool>(1);
    label f for(byte in bytes) {
        for (i in Iter.range(0, 6)) {
            let bit = Nat8.bittest(byte, i);
            buffer.add(bit);
        };
        let hasNext = Nat8.bittest(byte, 7);
        if(not hasNext) {
            break f;
        };
    };
    Buffer.toArray(buffer);
  };

  public func twosCompliment(bits: [Bool]): [Bool] {
    // Ones compliment, flip all bits
    let flippedBits = Array.map(bits, func(b: Bool): Bool { not b });
    
    // Twos compliment, add 1
    let lastIndex: Nat = flippedBits.size() - 1;
    let varBits: [var Bool] = Array.thaw(flippedBits);

    // Loop through adding 1 to the LSB, and carry the 1 if neccessary
    label l for (n in Iter.range(0, lastIndex)) {
        varBits[n] := not varBits[n]; // flip
        if (varBits[n]) {
            // If flipped to 1, end
            break l;
        } else {
            // If flipped to 0, carry the one till the first 0
        };
    };
    Array.freeze(varBits);
  };

  public func reverseTwosCompliment(bits: [Bool]): [Bool] {
    // Reverse Twos compliment, remove 1
    // Find the 1 closest to the lsb, then convert it to 0 and everything toward lsb 1
    let varBits: [var Bool] = Array.thaw(bits);
    label f for (n in Iter.range(0, bits.size() - 1)) {
        let index = Int.abs(n);
        if (varBits[index]) {
            varBits[index] := false;
            for (i in Iter.revRange(index-1, 0)) {
                varBits[Int.abs(i)] := true;
            };
            break f;
        };
    };
    let newBits = Array.freeze(varBits);

    // Reverse Ones compliment, flip all bits
    Array.map(newBits, func(b: Bool): Bool { not b });
  };

  public func bitsToText(bits: [Bool], order: {#lsb;#msb}) : Text {
    let range = switch(order) {
        case (#msb) Iter.range(0, bits.size() - 1);
        case (#lsb) Iter.revRange(bits.size() - 1, 0);
    };
    "0b" # Text.fromIter(Iter.map<Int, Char>(range, func(i: Int) { if (bits[Int.abs(i)]) '1' else '0'}));
  };

    public func toHexString(array : [Nat8]) : Text {
        Array.foldLeft<Nat8, Text>(array, "", func (accum, w8) {
            var pre = "";
            if(accum != ""){
                pre #= ", ";
            };
            accum # pre # encodeW8(w8);
        });
    };
    private let base : Nat8 = 0x10; 

    private let symbols = [
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
    ];
    /**
    * Encode an unsigned 8-bit integer in hexadecimal format.
    */
    private func encodeW8(w8 : Nat8) : Text {
        let c1 = symbols[Nat8.toNat(w8 / base)];
        let c2 = symbols[Nat8.toNat(w8 % base)];
        "0x" # Char.toText(c1) # Char.toText(c2);
    };
}