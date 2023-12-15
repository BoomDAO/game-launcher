import Array "mo:base/Array";
import List "mo:base/List";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Int "mo:base/Int";
import IntX "../src/IntX";
import TestUtil "./TestUtil";
import Util "../src/Util";


module {

    public func run(){
        testInt8([0x00], 0);
        testInt8([0x01], 1);
        testInt8([0x7f], 127);
        testInt8([0xff], -1);
        testInt8([0x80], -128);


        testInt16([0x00, 0x00], 0);
        testInt16([0x00, 0x01], 1);
        testInt16([0x00, 0xff], 255);
        testInt16([0x01, 0x00], 256);
        testInt16([0x7f, 0xff], 32767);
        testInt16([0xff, 0xff], -1);
        testInt16([0x80, 0x00], -32768);


        testInt32([0x00, 0x00, 0x00, 0x00], 0);
        testInt32([0x00, 0x00, 0x00, 0x01], 1);
        testInt32([0x00, 0x00, 0x00, 0xff], 255);
        testInt32([0x00, 0x00, 0x01, 0x00], 256);
        testInt32([0x00, 0x00, 0xff, 0xff], 65535);
        testInt32([0x7f, 0xff, 0xff, 0xff], 2147483647);
        testInt32([0x80, 0x00, 0x00, 0x00], -2147483648);
        testInt32([0xff, 0xff, 0xff, 0xff], -1);


        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 0);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01], 1);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff], 255);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00], 256);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff], 65535);
        testInt64([0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff], 4294967295);
        testInt64([0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 9223372036854775807);
        testInt64([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], -9223372036854775808);
        testInt64([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], -1);

        testInt([0xc0, 0xbb, 0x78], -123456, #signedLEB128);
        testInt([0xbc, 0x7f], -68, #signedLEB128);
        testInt([0x71], -15, #signedLEB128);
        testInt([0x7c], -4, #signedLEB128);
        testInt([0x00], 0, #signedLEB128);
        testInt([0x10], 16, #signedLEB128);
        testInt([0x80, 0x01], 128, #signedLEB128);
        testInt([0xe5, 0x8e, 0x26], 624485, #signedLEB128);
         
    };

    private func testInt8(bytes: [Nat8], expected: Int8) {
        testIntX(IntX.decodeInt8, encodeInt8, Int8.equal, Int8.toText, bytes, expected);
    };
    private func testInt16(bytes: [Nat8], expected: Int16) {
        testIntX(IntX.decodeInt16, IntX.encodeInt16, Int16.equal, Int16.toText, bytes, expected);
    };
    private func testInt32(bytes: [Nat8], expected: Int32) {
        testIntX(IntX.decodeInt32, IntX.encodeInt32, Int32.equal, Int32.toText, bytes, expected);
    };
    private func testInt64(bytes: [Nat8], expected: Int64) {
        testIntX(IntX.decodeInt64, IntX.encodeInt64, Int64.equal, Int64.toText, bytes, expected);
    };

    private func testInt(bytes: [Nat8], expected: Int, encoding: {#signedLEB128}) {
        let actual: ?Int = IntX.decodeInt(Iter.fromArray(bytes), encoding);
        switch (actual) {
            case (null) Debug.trap("Unable to parse Int from bytes: " # Util.toHexString(bytes));
            case (?a) {
                if(a != expected) {
                    Debug.trap("Expected: " # Int.toText(expected) # "\nActual: " # Int.toText(a) # "\nBytes: " # Util.toHexString(bytes));
                };
                let buffer = Buffer.Buffer<Nat8>(bytes.size());
                IntX.encodeInt(buffer, expected, encoding);
                let expectedBytes: [Nat8] = buffer.toArray();
                if (not TestUtil.bytesAreEqual(bytes, expectedBytes)){
                    Debug.trap("Expected Bytes: " # Util.toHexString(expectedBytes) # "\nActual Bytes: " # Util.toHexString(bytes));
                };
            };
        }
    };

    private func encodeInt8(buffer: Buffer.Buffer<Nat8>, value: Int8, encoding: {#lsb; #msb}) {
        IntX.encodeInt8(buffer, value);
    };

    private func testIntX<T>(
        decode: (Iter.Iter<Nat8>, {#lsb; #msb}) -> ?T,
        encode: (Buffer.Buffer<Nat8>, T, {#lsb; #msb}) -> (),
        equal: (T, T) -> Bool,
        toText: (T) -> Text,
        bytes: [Nat8],
        expected: T
    ) {
        testIntXInternal<T>(decode, encode, equal, toText, bytes, expected, #msb);
        let reverseBytes = List.toArray(List.reverse(List.fromArray(bytes)));
        testIntXInternal<T>(decode, encode, equal, toText, reverseBytes, expected, #lsb);

    };

    private func testIntXInternal<T>(
        decode: (Iter.Iter<Nat8>, {#lsb; #msb}) -> ?T,
        encode: (Buffer.Buffer<Nat8>, T, {#lsb; #msb}) -> (),
        equal: (T, T) -> Bool,
        toText: (T) -> Text,
        bytes: [Nat8],
        expected: T,
        encoding: {#lsb; #msb}
    ) {
        let actual: ?T = decode(Iter.fromArray(bytes), encoding);
        switch (actual) {
            case (null) Debug.trap("Unable to parse Int from bytes: " # Util.toHexString(bytes));
            case (?a) {
                if(not equal(a, expected)) {
                    Debug.trap("Expected: " # toText(expected) # "\nActual: " # toText(a) # "\nBytes: " # Util.toHexString(bytes));
                };
                let buffer = Buffer.Buffer<Nat8>(bytes.size());
                encode(buffer, expected, encoding);
                let expectedBytes: [Nat8] = buffer.toArray();
                if (not TestUtil.bytesAreEqual(bytes, expectedBytes)){
                    Debug.trap("Expected Bytes: " # Util.toHexString(expectedBytes) # "\nActual Bytes: " # Util.toHexString(bytes));
                };
            };
        }

    };
}