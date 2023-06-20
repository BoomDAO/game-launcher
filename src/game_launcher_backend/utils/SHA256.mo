import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";

import Util "ArrayUtil";

import Binary "Binary";

import Debug "mo:base/Debug";

module {
    // First thirty-two bits of the fractional parts of the cube roots of the 
    // first sixty-four prime numbers.
    private let K : [Nat32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
        0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
        0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
        0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
        0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
        0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
        0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
        0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];

    // Initial hash value, H(0).
    private let H256 : [Nat32] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c,
        0x1f83d9ab, 0x5be0cd19,
    ];
    private let H224 : [Nat32] = [
        0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939, 0xffc00b31, 0x68581511,
        0x64f98fa7, 0xbefa4fa4,
    ];

    private let chunk = 64;

    /// Returns the SHA256 checksum of the data.
    public func sum256(bs : [Nat8]) : [Nat8] {
        let h = Hash(false);
        h.write(bs);
        h.checkSum();
    };

    /// Returns the SHA224 checkum of the data.
    public func sum224(bs : [Nat8]) : [Nat8] {
        let h = Hash(true);
        h.write(bs);
        h.checkSum()
    };

    public class Hash(is224 : Bool) = {
        var h   : [var Nat32] = switch (is224) {
            case (false) { Array.thaw(H256); };
            case (true)  { Array.thaw(H224); };
        };
        var x   : [var Nat8]  = Array.init<Nat8>(64, 0);
        var nx                = 0;
        var len : Nat64       = 0;

        // The size of the checksum in bytes.
        public func size() : Nat {
            switch (is224) {
                case (false) { 32; };
                case (true)  { 28; };
            };
        };

        public func sum(bs : [Nat8]) : [Nat8] {
            Array.append(bs, checkSum());
        };

        public func checkSum() : [Nat8] {
            let n = len;
            var tmp = Array.init<Nat8>(64, 0);
            tmp[0] := 0x80;
            if (Nat64.toNat(len) % 64 < 56) {
                write(Util.takeN<Nat8>(
                    56 - Nat64.toNat(len) % 64,
                    Array.freeze(tmp),
                ));
            } else {
                write(Util.takeN<Nat8>(
                    64 + 56 - Nat64.toNat(len) % 64, 
                    Array.freeze(tmp),
                ));
            };
            write(Binary.BigEndian.fromNat64(n << 3));
            var digest : [Nat8] = [];
            label l for (i in h.keys()) {
                if (i == 7 and is224) { break l; };
                digest := Array.append(digest, Binary.BigEndian.fromNat32(h[i]));
            };
            digest;
        };

        public func write(bs : [Nat8]) {
            var p = bs;
            len +%= Nat64.fromNat(bs.size());
            if (0 < nx) {
                let n = Util.copy<Nat8>(nx, x, p);
                nx += n;
                if (nx == 64) {
                    block(Array.freeze(x));
                    nx := 0;
                };
                p := Util.removeN(n, p);
            };
            if (64 <= p.size()) {
                let n = Nat64.toNat(Nat64.fromNat(p.size()) & (^63));
                block(Util.takeN(n, p));
                p := Util.removeN(n, p);
            };
            if (0 < p.size()) {
                nx := Util.copy<Nat8>(0, x, p);
            };
        };

        private func block(bs : [Nat8]) {
            var p = bs;
            var w : [var Nat32] = Array.init<Nat32>(64, 0);
            var h0 = h[0]; var h1 = h[1]; var h2 = h[2]; var h3 = h[3];
            var h4 = h[4]; var h5 = h[5]; var h6 = h[6]; var h7 = h[7];
            while (chunk <= p.size()) {
                for (i in Iter.range(0, 15)) {
                    let j = i * 4;
                    w[i] := nat8to32(p[j]) << 24 | nat8to32(p[j+1]) << 16 | nat8to32(p[j+2]) << 8 | nat8to32(p[j+3]);
                };
                for (i in Iter.range(16, 63)) {
                    let v1 = w[i-2];
                    let t1 = (Nat32.bitrotRight(v1, 17) ^ Nat32.bitrotRight(v1, 19)) ^ (v1 >> 10);
                    let v2 = w[i-15];
                    let t2 = (Nat32.bitrotRight(v2, 7) ^ Nat32.bitrotRight(v2, 18)) ^ (v2 >> 3);
                    w[i] := t1 +% w[i-7] +% t2 +% w[i - 16];
                };
                var a = h0; var b = h1; var c = h2; var d = h3;
                var e = h4; var f = h5; var g = h6; var h = h7;
                for (i in Iter.range(0, 63)) {
                    let t1 = h +% (Nat32.bitrotRight(e, 6) ^ Nat32.bitrotRight(e, 11) ^ Nat32.bitrotRight(e, 25)) +% ((e & f) ^ (^e & g)) +% K[i] +% w[i];
                    let t2 = (Nat32.bitrotRight(a, 2) ^ Nat32.bitrotRight(a, 13) ^ Nat32.bitrotRight(a, 22)) +% ((a & b) ^ (a & c) ^ (b & c));
                    h := g; g := f; f := e; e := d +% t1;
                    d := c; c := b; b := a; a := t1 +% t2;
                };
                h0 +%= a; h1 +%= b; h2 +%= c; h3 +%= d;
                h4 +%= e; h5 +%= f; h6 +%= g; h7 +%= h;
                p := Util.removeN(chunk, p);
            };
            h[0] := h0; h[1] := h1; h[2] := h2; h[3] := h3;
            h[4] := h4; h[5] := h5; h[6] := h6; h[7] := h7;
        };

        private func nat8to32(n : Nat8) : Nat32 {
            Nat32.fromNat(Nat8.toNat(n));
        };
    };
};
