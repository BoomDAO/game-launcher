/// Cycle-optimized Sha512 variants.
///
/// Features:
///
/// * Algorithms: `sha512_224`, `sha512_256`, `sha384`, `sha512`
/// * Input types: `Blob`, `[Nat8]`, `Iter<Nat8>`
/// * Output types: `Blob`

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Prim "mo:prim";

module {
  public type Algorithm = {
    #sha384;
    #sha512;
    #sha512_224;
    #sha512_256;
  };

  let K00 : Nat64 = 0x428a2f98d728ae22;
  let K01 : Nat64 = 0x7137449123ef65cd;
  let K02 : Nat64 = 0xb5c0fbcfec4d3b2f;
  let K03 : Nat64 = 0xe9b5dba58189dbbc;
  let K04 : Nat64 = 0x3956c25bf348b538;
  let K05 : Nat64 = 0x59f111f1b605d019;
  let K06 : Nat64 = 0x923f82a4af194f9b;
  let K07 : Nat64 = 0xab1c5ed5da6d8118;
  let K08 : Nat64 = 0xd807aa98a3030242;
  let K09 : Nat64 = 0x12835b0145706fbe;
  let K10 : Nat64 = 0x243185be4ee4b28c;
  let K11 : Nat64 = 0x550c7dc3d5ffb4e2;
  let K12 : Nat64 = 0x72be5d74f27b896f;
  let K13 : Nat64 = 0x80deb1fe3b1696b1;
  let K14 : Nat64 = 0x9bdc06a725c71235;
  let K15 : Nat64 = 0xc19bf174cf692694;
  let K16 : Nat64 = 0xe49b69c19ef14ad2;
  let K17 : Nat64 = 0xefbe4786384f25e3;
  let K18 : Nat64 = 0x0fc19dc68b8cd5b5;
  let K19 : Nat64 = 0x240ca1cc77ac9c65;
  let K20 : Nat64 = 0x2de92c6f592b0275;
  let K21 : Nat64 = 0x4a7484aa6ea6e483;
  let K22 : Nat64 = 0x5cb0a9dcbd41fbd4;
  let K23 : Nat64 = 0x76f988da831153b5;
  let K24 : Nat64 = 0x983e5152ee66dfab;
  let K25 : Nat64 = 0xa831c66d2db43210;
  let K26 : Nat64 = 0xb00327c898fb213f;
  let K27 : Nat64 = 0xbf597fc7beef0ee4;
  let K28 : Nat64 = 0xc6e00bf33da88fc2;
  let K29 : Nat64 = 0xd5a79147930aa725;
  let K30 : Nat64 = 0x06ca6351e003826f;
  let K31 : Nat64 = 0x142929670a0e6e70;
  let K32 : Nat64 = 0x27b70a8546d22ffc;
  let K33 : Nat64 = 0x2e1b21385c26c926;
  let K34 : Nat64 = 0x4d2c6dfc5ac42aed;
  let K35 : Nat64 = 0x53380d139d95b3df;
  let K36 : Nat64 = 0x650a73548baf63de;
  let K37 : Nat64 = 0x766a0abb3c77b2a8;
  let K38 : Nat64 = 0x81c2c92e47edaee6;
  let K39 : Nat64 = 0x92722c851482353b;
  let K40 : Nat64 = 0xa2bfe8a14cf10364;
  let K41 : Nat64 = 0xa81a664bbc423001;
  let K42 : Nat64 = 0xc24b8b70d0f89791;
  let K43 : Nat64 = 0xc76c51a30654be30;
  let K44 : Nat64 = 0xd192e819d6ef5218;
  let K45 : Nat64 = 0xd69906245565a910;
  let K46 : Nat64 = 0xf40e35855771202a;
  let K47 : Nat64 = 0x106aa07032bbd1b8;
  let K48 : Nat64 = 0x19a4c116b8d2d0c8;
  let K49 : Nat64 = 0x1e376c085141ab53;
  let K50 : Nat64 = 0x2748774cdf8eeb99;
  let K51 : Nat64 = 0x34b0bcb5e19b48a8;
  let K52 : Nat64 = 0x391c0cb3c5c95a63;
  let K53 : Nat64 = 0x4ed8aa4ae3418acb;
  let K54 : Nat64 = 0x5b9cca4f7763e373;
  let K55 : Nat64 = 0x682e6ff3d6b2b8a3;
  let K56 : Nat64 = 0x748f82ee5defb2fc;
  let K57 : Nat64 = 0x78a5636f43172f60;
  let K58 : Nat64 = 0x84c87814a1f0ab72;
  let K59 : Nat64 = 0x8cc702081a6439ec;
  let K60 : Nat64 = 0x90befffa23631e28;
  let K61 : Nat64 = 0xa4506cebde82bde9;
  let K62 : Nat64 = 0xbef9a3f7b2c67915;
  let K63 : Nat64 = 0xc67178f2e372532b;
  let K64 : Nat64 = 0xca273eceea26619c;
  let K65 : Nat64 = 0xd186b8c721c0c207;
  let K66 : Nat64 = 0xeada7dd6cde0eb1e;
  let K67 : Nat64 = 0xf57d4f7fee6ed178;
  let K68 : Nat64 = 0x06f067aa72176fba;
  let K69 : Nat64 = 0x0a637dc5a2c898a6;
  let K70 : Nat64 = 0x113f9804bef90dae;
  let K71 : Nat64 = 0x1b710b35131c471b;
  let K72 : Nat64 = 0x28db77f523047d84;
  let K73 : Nat64 = 0x32caab7b40c72493;
  let K74 : Nat64 = 0x3c9ebe0a15c9bebc;
  let K75 : Nat64 = 0x431d67c49c100d4c;
  let K76 : Nat64 = 0x4cc5d4becb3e42b6;
  let K77 : Nat64 = 0x597f299cfc657e2a;
  let K78 : Nat64 = 0x5fcb6fab3ad6faec;
  let K79 : Nat64 = 0x6c44198c4a475817;

  let ivs : [[Nat64]] = [
    [
      // 512-224
      0x8c3d37c819544da2,
      0x73e1996689dcd4d6,
      0x1dfab7ae32ff9c82,
      0x679dd514582f9fcf,
      0x0f6d2b697bd44da8,
      0x77e36f7304c48942,
      0x3f9d85a86a1d36c8,
      0x1112e6ad91d692a1,
    ],
    [
      // 512-256
      0x22312194fc2bf72c,
      0x9f555fa3c84c64c2,
      0x2393b86b6f53b151,
      0x963877195940eabd,
      0x96283ee2a88effe3,
      0xbe5e1e2553863992,
      0x2b0199fc2c85b8aa,
      0x0eb72ddc81c52ca2,
    ],
    [
      // 384
      0xcbbb9d5dc1059ed8,
      0x629a292a367cd507,
      0x9159015a3070dd17,
      0x152fecd8f70e5939,
      0x67332667ffc00b31,
      0x8eb44a8768581511,
      0xdb0c2e0d64f98fa7,
      0x47b5481dbefa4fa4,
    ],
    [
      // 512
      0x6a09e667f3bcc908,
      0xbb67ae8584caa73b,
      0x3c6ef372fe94f82b,
      0xa54ff53a5f1d36f1,
      0x510e527fade682d1,
      0x9b05688c2b3e6c1f,
      0x1f83d9abfb41bd6b,
      0x5be0cd19137e2179,
    ],
  ];

  let rot = Nat64.bitrotRight;

  public class Digest(algo_ : Algorithm) {
    let (sum_bytes, iv) = switch (algo_) {
      case (#sha512_224) { (28, 0) };
      case (#sha512_256) { (32, 1) };
      case (#sha384) { (48, 2) };
      case (#sha512) { (64, 3) };
    };

    public func algo() : Algorithm = algo_;

    var s0 : Nat64 = 0;
    var s1 : Nat64 = 0;
    var s2 : Nat64 = 0;
    var s3 : Nat64 = 0;
    var s4 : Nat64 = 0;
    var s5 : Nat64 = 0;
    var s6 : Nat64 = 0;
    var s7 : Nat64 = 0;

    let msg : [var Nat64] = Array.init<Nat64>(80, 0);
    let digest = Array.init<Nat8>(sum_bytes, 0);
    var word : Nat64 = 0;

    var i_msg : Nat8 = 0;
    var i_byte : Nat8 = 8;
    var i_block : Nat64 = 0;

    public func reset() {
      i_msg := 0;
      i_byte := 8;
      i_block := 0;
      s0 := ivs[iv][0];
      s1 := ivs[iv][1];
      s2 := ivs[iv][2];
      s3 := ivs[iv][3];
      s4 := ivs[iv][4];
      s5 := ivs[iv][5];
      s6 := ivs[iv][6];
      s7 := ivs[iv][7];
    };

    reset();

    private func writeByte(val : Nat8) : () {
      word := (word << 8) ^ Prim.nat32ToNat64(Prim.nat16ToNat32(Prim.nat8ToNat16(val)));
      i_byte -%= 1;
      if (i_byte == 0) {
        msg[Nat8.toNat(i_msg)] := word;
        word := 0;
        i_byte := 8;
        i_msg +%= 1;
        if (i_msg == 16) {
          process_block();
          i_msg := 0;
          i_block +%= 1;
        };
      };
    };

    // We must be at a word boundary, i.e. i_byte must be equal to 8
    private func writeWord(val : Nat64) : () {
      assert (i_byte == 8);
      msg[Nat8.toNat(i_msg)] := val;
      i_msg +%= 1;
      if (i_msg == 16) {
        process_block();
        i_msg := 0;
        i_block +%= 1;
      };
    };

    private func process_block() : () {
      // Below is an inlined and unrolled version of this code:
      // for ((i, j, k, l, m) in expansion_rounds.vals()) {
      //   // (j,k,l,m) = (i+1,i+9,i+14,i+16)
      //   let (v0, v1) = (msg[j], msg[l]);
      //   let s0 = rot(v0, 07) ^ rot(v0, 18) ^ (v0 >> 03);
      //   let s1 = rot(v1, 17) ^ rot(v1, 19) ^ (v1 >> 10);
      //   msg[m] := msg[i] +% s0 +% msg[k] +% s1;
      // };
      let w00 = msg[0];
      let w01 = msg[1];
      let w02 = msg[2];
      let w03 = msg[3];
      let w04 = msg[4];
      let w05 = msg[5];
      let w06 = msg[6];
      let w07 = msg[7];
      let w08 = msg[8];
      let w09 = msg[9];
      let w10 = msg[10];
      let w11 = msg[11];
      let w12 = msg[12];
      let w13 = msg[13];
      let w14 = msg[14];
      let w15 = msg[15];
      let w16 = w00 +% rot(w01, 01) ^ rot(w01, 08) ^ (w01 >> 07) +% w09 +% rot(w14, 19) ^ rot(w14, 61) ^ (w14 >> 06);
      let w17 = w01 +% rot(w02, 01) ^ rot(w02, 08) ^ (w02 >> 07) +% w10 +% rot(w15, 19) ^ rot(w15, 61) ^ (w15 >> 06);
      let w18 = w02 +% rot(w03, 01) ^ rot(w03, 08) ^ (w03 >> 07) +% w11 +% rot(w16, 19) ^ rot(w16, 61) ^ (w16 >> 06);
      let w19 = w03 +% rot(w04, 01) ^ rot(w04, 08) ^ (w04 >> 07) +% w12 +% rot(w17, 19) ^ rot(w17, 61) ^ (w17 >> 06);
      let w20 = w04 +% rot(w05, 01) ^ rot(w05, 08) ^ (w05 >> 07) +% w13 +% rot(w18, 19) ^ rot(w18, 61) ^ (w18 >> 06);
      let w21 = w05 +% rot(w06, 01) ^ rot(w06, 08) ^ (w06 >> 07) +% w14 +% rot(w19, 19) ^ rot(w19, 61) ^ (w19 >> 06);
      let w22 = w06 +% rot(w07, 01) ^ rot(w07, 08) ^ (w07 >> 07) +% w15 +% rot(w20, 19) ^ rot(w20, 61) ^ (w20 >> 06);
      let w23 = w07 +% rot(w08, 01) ^ rot(w08, 08) ^ (w08 >> 07) +% w16 +% rot(w21, 19) ^ rot(w21, 61) ^ (w21 >> 06);
      let w24 = w08 +% rot(w09, 01) ^ rot(w09, 08) ^ (w09 >> 07) +% w17 +% rot(w22, 19) ^ rot(w22, 61) ^ (w22 >> 06);
      let w25 = w09 +% rot(w10, 01) ^ rot(w10, 08) ^ (w10 >> 07) +% w18 +% rot(w23, 19) ^ rot(w23, 61) ^ (w23 >> 06);
      let w26 = w10 +% rot(w11, 01) ^ rot(w11, 08) ^ (w11 >> 07) +% w19 +% rot(w24, 19) ^ rot(w24, 61) ^ (w24 >> 06);
      let w27 = w11 +% rot(w12, 01) ^ rot(w12, 08) ^ (w12 >> 07) +% w20 +% rot(w25, 19) ^ rot(w25, 61) ^ (w25 >> 06);
      let w28 = w12 +% rot(w13, 01) ^ rot(w13, 08) ^ (w13 >> 07) +% w21 +% rot(w26, 19) ^ rot(w26, 61) ^ (w26 >> 06);
      let w29 = w13 +% rot(w14, 01) ^ rot(w14, 08) ^ (w14 >> 07) +% w22 +% rot(w27, 19) ^ rot(w27, 61) ^ (w27 >> 06);
      let w30 = w14 +% rot(w15, 01) ^ rot(w15, 08) ^ (w15 >> 07) +% w23 +% rot(w28, 19) ^ rot(w28, 61) ^ (w28 >> 06);
      let w31 = w15 +% rot(w16, 01) ^ rot(w16, 08) ^ (w16 >> 07) +% w24 +% rot(w29, 19) ^ rot(w29, 61) ^ (w29 >> 06);
      let w32 = w16 +% rot(w17, 01) ^ rot(w17, 08) ^ (w17 >> 07) +% w25 +% rot(w30, 19) ^ rot(w30, 61) ^ (w30 >> 06);
      let w33 = w17 +% rot(w18, 01) ^ rot(w18, 08) ^ (w18 >> 07) +% w26 +% rot(w31, 19) ^ rot(w31, 61) ^ (w31 >> 06);
      let w34 = w18 +% rot(w19, 01) ^ rot(w19, 08) ^ (w19 >> 07) +% w27 +% rot(w32, 19) ^ rot(w32, 61) ^ (w32 >> 06);
      let w35 = w19 +% rot(w20, 01) ^ rot(w20, 08) ^ (w20 >> 07) +% w28 +% rot(w33, 19) ^ rot(w33, 61) ^ (w33 >> 06);
      let w36 = w20 +% rot(w21, 01) ^ rot(w21, 08) ^ (w21 >> 07) +% w29 +% rot(w34, 19) ^ rot(w34, 61) ^ (w34 >> 06);
      let w37 = w21 +% rot(w22, 01) ^ rot(w22, 08) ^ (w22 >> 07) +% w30 +% rot(w35, 19) ^ rot(w35, 61) ^ (w35 >> 06);
      let w38 = w22 +% rot(w23, 01) ^ rot(w23, 08) ^ (w23 >> 07) +% w31 +% rot(w36, 19) ^ rot(w36, 61) ^ (w36 >> 06);
      let w39 = w23 +% rot(w24, 01) ^ rot(w24, 08) ^ (w24 >> 07) +% w32 +% rot(w37, 19) ^ rot(w37, 61) ^ (w37 >> 06);
      let w40 = w24 +% rot(w25, 01) ^ rot(w25, 08) ^ (w25 >> 07) +% w33 +% rot(w38, 19) ^ rot(w38, 61) ^ (w38 >> 06);
      let w41 = w25 +% rot(w26, 01) ^ rot(w26, 08) ^ (w26 >> 07) +% w34 +% rot(w39, 19) ^ rot(w39, 61) ^ (w39 >> 06);
      let w42 = w26 +% rot(w27, 01) ^ rot(w27, 08) ^ (w27 >> 07) +% w35 +% rot(w40, 19) ^ rot(w40, 61) ^ (w40 >> 06);
      let w43 = w27 +% rot(w28, 01) ^ rot(w28, 08) ^ (w28 >> 07) +% w36 +% rot(w41, 19) ^ rot(w41, 61) ^ (w41 >> 06);
      let w44 = w28 +% rot(w29, 01) ^ rot(w29, 08) ^ (w29 >> 07) +% w37 +% rot(w42, 19) ^ rot(w42, 61) ^ (w42 >> 06);
      let w45 = w29 +% rot(w30, 01) ^ rot(w30, 08) ^ (w30 >> 07) +% w38 +% rot(w43, 19) ^ rot(w43, 61) ^ (w43 >> 06);
      let w46 = w30 +% rot(w31, 01) ^ rot(w31, 08) ^ (w31 >> 07) +% w39 +% rot(w44, 19) ^ rot(w44, 61) ^ (w44 >> 06);
      let w47 = w31 +% rot(w32, 01) ^ rot(w32, 08) ^ (w32 >> 07) +% w40 +% rot(w45, 19) ^ rot(w45, 61) ^ (w45 >> 06);
      let w48 = w32 +% rot(w33, 01) ^ rot(w33, 08) ^ (w33 >> 07) +% w41 +% rot(w46, 19) ^ rot(w46, 61) ^ (w46 >> 06);
      let w49 = w33 +% rot(w34, 01) ^ rot(w34, 08) ^ (w34 >> 07) +% w42 +% rot(w47, 19) ^ rot(w47, 61) ^ (w47 >> 06);
      let w50 = w34 +% rot(w35, 01) ^ rot(w35, 08) ^ (w35 >> 07) +% w43 +% rot(w48, 19) ^ rot(w48, 61) ^ (w48 >> 06);
      let w51 = w35 +% rot(w36, 01) ^ rot(w36, 08) ^ (w36 >> 07) +% w44 +% rot(w49, 19) ^ rot(w49, 61) ^ (w49 >> 06);
      let w52 = w36 +% rot(w37, 01) ^ rot(w37, 08) ^ (w37 >> 07) +% w45 +% rot(w50, 19) ^ rot(w50, 61) ^ (w50 >> 06);
      let w53 = w37 +% rot(w38, 01) ^ rot(w38, 08) ^ (w38 >> 07) +% w46 +% rot(w51, 19) ^ rot(w51, 61) ^ (w51 >> 06);
      let w54 = w38 +% rot(w39, 01) ^ rot(w39, 08) ^ (w39 >> 07) +% w47 +% rot(w52, 19) ^ rot(w52, 61) ^ (w52 >> 06);
      let w55 = w39 +% rot(w40, 01) ^ rot(w40, 08) ^ (w40 >> 07) +% w48 +% rot(w53, 19) ^ rot(w53, 61) ^ (w53 >> 06);
      let w56 = w40 +% rot(w41, 01) ^ rot(w41, 08) ^ (w41 >> 07) +% w49 +% rot(w54, 19) ^ rot(w54, 61) ^ (w54 >> 06);
      let w57 = w41 +% rot(w42, 01) ^ rot(w42, 08) ^ (w42 >> 07) +% w50 +% rot(w55, 19) ^ rot(w55, 61) ^ (w55 >> 06);
      let w58 = w42 +% rot(w43, 01) ^ rot(w43, 08) ^ (w43 >> 07) +% w51 +% rot(w56, 19) ^ rot(w56, 61) ^ (w56 >> 06);
      let w59 = w43 +% rot(w44, 01) ^ rot(w44, 08) ^ (w44 >> 07) +% w52 +% rot(w57, 19) ^ rot(w57, 61) ^ (w57 >> 06);
      let w60 = w44 +% rot(w45, 01) ^ rot(w45, 08) ^ (w45 >> 07) +% w53 +% rot(w58, 19) ^ rot(w58, 61) ^ (w58 >> 06);
      let w61 = w45 +% rot(w46, 01) ^ rot(w46, 08) ^ (w46 >> 07) +% w54 +% rot(w59, 19) ^ rot(w59, 61) ^ (w59 >> 06);
      let w62 = w46 +% rot(w47, 01) ^ rot(w47, 08) ^ (w47 >> 07) +% w55 +% rot(w60, 19) ^ rot(w60, 61) ^ (w60 >> 06);
      let w63 = w47 +% rot(w48, 01) ^ rot(w48, 08) ^ (w48 >> 07) +% w56 +% rot(w61, 19) ^ rot(w61, 61) ^ (w61 >> 06);
      let w64 = w48 +% rot(w49, 01) ^ rot(w49, 08) ^ (w49 >> 07) +% w57 +% rot(w62, 19) ^ rot(w62, 61) ^ (w62 >> 06);
      let w65 = w49 +% rot(w50, 01) ^ rot(w50, 08) ^ (w50 >> 07) +% w58 +% rot(w63, 19) ^ rot(w63, 61) ^ (w63 >> 06);
      let w66 = w50 +% rot(w51, 01) ^ rot(w51, 08) ^ (w51 >> 07) +% w59 +% rot(w64, 19) ^ rot(w64, 61) ^ (w64 >> 06);
      let w67 = w51 +% rot(w52, 01) ^ rot(w52, 08) ^ (w52 >> 07) +% w60 +% rot(w65, 19) ^ rot(w65, 61) ^ (w65 >> 06);
      let w68 = w52 +% rot(w53, 01) ^ rot(w53, 08) ^ (w53 >> 07) +% w61 +% rot(w66, 19) ^ rot(w66, 61) ^ (w66 >> 06);
      let w69 = w53 +% rot(w54, 01) ^ rot(w54, 08) ^ (w54 >> 07) +% w62 +% rot(w67, 19) ^ rot(w67, 61) ^ (w67 >> 06);
      let w70 = w54 +% rot(w55, 01) ^ rot(w55, 08) ^ (w55 >> 07) +% w63 +% rot(w68, 19) ^ rot(w68, 61) ^ (w68 >> 06);
      let w71 = w55 +% rot(w56, 01) ^ rot(w56, 08) ^ (w56 >> 07) +% w64 +% rot(w69, 19) ^ rot(w69, 61) ^ (w69 >> 06);
      let w72 = w56 +% rot(w57, 01) ^ rot(w57, 08) ^ (w57 >> 07) +% w65 +% rot(w70, 19) ^ rot(w70, 61) ^ (w70 >> 06);
      let w73 = w57 +% rot(w58, 01) ^ rot(w58, 08) ^ (w58 >> 07) +% w66 +% rot(w71, 19) ^ rot(w71, 61) ^ (w71 >> 06);
      let w74 = w58 +% rot(w59, 01) ^ rot(w59, 08) ^ (w59 >> 07) +% w67 +% rot(w72, 19) ^ rot(w72, 61) ^ (w72 >> 06);
      let w75 = w59 +% rot(w60, 01) ^ rot(w60, 08) ^ (w60 >> 07) +% w68 +% rot(w73, 19) ^ rot(w73, 61) ^ (w73 >> 06);
      let w76 = w60 +% rot(w61, 01) ^ rot(w61, 08) ^ (w61 >> 07) +% w69 +% rot(w74, 19) ^ rot(w74, 61) ^ (w74 >> 06);
      let w77 = w61 +% rot(w62, 01) ^ rot(w62, 08) ^ (w62 >> 07) +% w70 +% rot(w75, 19) ^ rot(w75, 61) ^ (w75 >> 06);
      let w78 = w62 +% rot(w63, 01) ^ rot(w63, 08) ^ (w63 >> 07) +% w71 +% rot(w76, 19) ^ rot(w76, 61) ^ (w76 >> 06);
      let w79 = w63 +% rot(w64, 01) ^ rot(w64, 08) ^ (w64 >> 07) +% w72 +% rot(w77, 19) ^ rot(w77, 61) ^ (w77 >> 06);

      // compress
      var a = s0;
      var b = s1;
      var c = s2;
      var d = s3;
      var e = s4;
      var f = s5;
      var g = s6;
      var h = s7;

      // Below is an inlined and unrolled version of this code:
      // for (i in compression_rounds.keys()) {
      //   let ch = (e & f) ^ (^ e & g);
      //   let maj = (a & b) ^ (a & c) ^ (b & c);
      //   let sigma0 = rot(a, 02) ^ rot(a, 13) ^ rot(a, 22);
      //   let sigma1 = rot(e, 06) ^ rot(e, 11) ^ rot(e, 25);
      //   let t = h +% K[i] +% msg[i] +% ch +% sigma1;
      //   h := g;
      //   g := f;
      //   f := e;
      //   e := d +% t;
      //   d := c;
      //   c := b;
      //   b := a;
      //   a := t +% maj +% sigma0;
      // };

      var t = 0 : Nat64;
      t := h +% K00 +% w00 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K01 +% w01 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K02 +% w02 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K03 +% w03 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K04 +% w04 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K05 +% w05 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K06 +% w06 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K07 +% w07 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K08 +% w08 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K09 +% w09 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K10 +% w10 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K11 +% w11 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K12 +% w12 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K13 +% w13 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K14 +% w14 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K15 +% w15 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K16 +% w16 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K17 +% w17 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K18 +% w18 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K19 +% w19 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K20 +% w20 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K21 +% w21 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K22 +% w22 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K23 +% w23 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K24 +% w24 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K25 +% w25 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K26 +% w26 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K27 +% w27 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K28 +% w28 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K29 +% w29 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K30 +% w30 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K31 +% w31 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K32 +% w32 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K33 +% w33 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K34 +% w34 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K35 +% w35 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K36 +% w36 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K37 +% w37 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K38 +% w38 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K39 +% w39 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K40 +% w40 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K41 +% w41 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K42 +% w42 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K43 +% w43 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K44 +% w44 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K45 +% w45 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K46 +% w46 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K47 +% w47 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K48 +% w48 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K49 +% w49 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K50 +% w50 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K51 +% w51 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K52 +% w52 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K53 +% w53 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K54 +% w54 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K55 +% w55 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K56 +% w56 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K57 +% w57 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K58 +% w58 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K59 +% w59 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K60 +% w60 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K61 +% w61 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K62 +% w62 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K63 +% w63 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K64 +% w64 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K65 +% w65 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K66 +% w66 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K67 +% w67 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K68 +% w68 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K69 +% w69 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K70 +% w70 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K71 +% w71 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K72 +% w72 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K73 +% w73 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K74 +% w74 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K75 +% w75 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K76 +% w76 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K77 +% w77 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K78 +% w78 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);
      t := h +% K79 +% w79 +% (e & f) ^ (^ e & g) +% rot(e, 14) ^ rot(e, 18) ^ rot(e, 41); h := g; g := f; f := e; e := d +% t; d := c; c := b; b := a; a := t +% (b & c) ^ (b & d) ^ (c & d) +% rot(a, 28) ^ rot(a, 34) ^ rot(a, 39);

      // final addition
      s0 +%= a;
      s1 +%= b;
      s2 +%= c;
      s3 +%= d;
      s4 +%= e;
      s5 +%= f;
      s6 +%= g;
      s7 +%= h;
    };

    public func writeIter(iter : { next() : ?Nat8 }) : () {
      label reading loop {
        switch (iter.next()) {
          case (?val) {
            writeByte(val);
            continue reading;
          };
          case (null) {
            break reading;
          };
        };
      };
    };

    public func writeArray(arr : [Nat8]) : () = writeIter(arr.vals());
    public func writeBlob(blob : Blob) : () = writeIter(blob.vals());

    public func sum() : Blob {
      // calculate padding
      // t = bytes in the last incomplete block (0-127)
      let t : Nat8 = (i_msg << 3) +% 8 -% i_byte;
      // p = length of padding (1-128)
      var p : Nat8 = if (t < 112) (112 -% t) else (240 -% t);
      // n_bits = length of message in bits
      // Note: This implementation only handles messages < 2^64 bits
      let n_bits : Nat64 = ((i_block << 7) +% Nat64.fromIntWrap(Nat8.toNat(t))) << 3;

      // write 1-7 padding bytes 
      writeByte(0x80);
      p -%= 1;
      while (p & 0x7 != 0) {
        writeByte(0);
        p -%= 1;
      };
      // write padding words
      p >>= 3;
      while (p != 0) {
        writeWord(0);
        p -%= 1;
      };

      // write length (16 bytes)
      // Note: this exactly fills the block buffer, hence process_block will get
      // triggered by the last writeByte
      writeWord(0);
      writeWord(n_bits);

      // retrieve sum
      digest[0] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 56) & 0xff));
      digest[1] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 48) & 0xff));
      digest[2] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 40) & 0xff));
      digest[3] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 32) & 0xff));
      digest[4] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 24) & 0xff));
      digest[5] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 16) & 0xff));
      digest[6] := Nat8.fromIntWrap(Nat64.toNat((s0 >> 8) & 0xff));
      digest[7] := Nat8.fromIntWrap(Nat64.toNat(s0 & 0xff));

      digest[8] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 56) & 0xff));
      digest[9] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 48) & 0xff));
      digest[10] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 40) & 0xff));
      digest[11] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 32) & 0xff));
      digest[12] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 24) & 0xff));
      digest[13] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 16) & 0xff));
      digest[14] := Nat8.fromIntWrap(Nat64.toNat((s1 >> 8) & 0xff));
      digest[15] := Nat8.fromIntWrap(Nat64.toNat(s1 & 0xff));

      digest[16] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 56) & 0xff));
      digest[17] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 48) & 0xff));
      digest[18] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 40) & 0xff));
      digest[19] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 32) & 0xff));
      digest[20] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 24) & 0xff));
      digest[21] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 16) & 0xff));
      digest[22] := Nat8.fromIntWrap(Nat64.toNat((s2 >> 8) & 0xff));
      digest[23] := Nat8.fromIntWrap(Nat64.toNat(s2 & 0xff));

      digest[24] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 56) & 0xff));
      digest[25] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 48) & 0xff));
      digest[26] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 40) & 0xff));
      digest[27] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 32) & 0xff));

      if (algo_ == #sha512_224) return Blob.fromArrayMut(digest);

      digest[28] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 24) & 0xff));
      digest[29] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 16) & 0xff));
      digest[30] := Nat8.fromIntWrap(Nat64.toNat((s3 >> 8) & 0xff));
      digest[31] := Nat8.fromIntWrap(Nat64.toNat(s3 & 0xff));

      if (algo_ == #sha512_256) return Blob.fromArrayMut(digest);


      digest[32] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 56) & 0xff));
      digest[33] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 48) & 0xff));
      digest[34] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 40) & 0xff));
      digest[35] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 32) & 0xff));
      digest[36] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 24) & 0xff));
      digest[37] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 16) & 0xff));
      digest[38] := Nat8.fromIntWrap(Nat64.toNat((s4 >> 8) & 0xff));
      digest[39] := Nat8.fromIntWrap(Nat64.toNat(s4 & 0xff));

      digest[40] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 56) & 0xff));
      digest[41] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 48) & 0xff));
      digest[42] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 40) & 0xff));
      digest[43] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 32) & 0xff));
      digest[44] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 24) & 0xff));
      digest[45] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 16) & 0xff));
      digest[46] := Nat8.fromIntWrap(Nat64.toNat((s5 >> 8) & 0xff));
      digest[47] := Nat8.fromIntWrap(Nat64.toNat(s5 & 0xff));

      if (algo_ == #sha384) return Blob.fromArrayMut(digest);

      digest[48] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 56) & 0xff));
      digest[49] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 48) & 0xff));
      digest[50] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 40) & 0xff));
      digest[51] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 32) & 0xff));
      digest[52] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 24) & 0xff));
      digest[53] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 16) & 0xff));
      digest[54] := Nat8.fromIntWrap(Nat64.toNat((s6 >> 8) & 0xff));
      digest[55] := Nat8.fromIntWrap(Nat64.toNat(s6 & 0xff));

      digest[56] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 56) & 0xff));
      digest[57] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 48) & 0xff));
      digest[58] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 40) & 0xff));
      digest[59] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 32) & 0xff));
      digest[60] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 24) & 0xff));
      digest[61] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 16) & 0xff));
      digest[62] := Nat8.fromIntWrap(Nat64.toNat((s7 >> 8) & 0xff));
      digest[63] := Nat8.fromIntWrap(Nat64.toNat(s7 & 0xff));

      return Blob.fromArrayMut(digest);
    };
  }; // class Digest

  // Calculate SHA256 hash digest from [Nat8].
  public func fromArray(algo : Algorithm, arr : [Nat8]) : Blob {
    let digest = Digest(algo);
    digest.writeIter(arr.vals());
    return digest.sum();
  };

  // Calculate SHA2 hash digest from Iter.
  public func fromIter(algo : Algorithm, iter : { next() : ?Nat8 }) : Blob {
    let digest = Digest(algo);
    digest.writeIter(iter);
    return digest.sum();
  };

  // Calculate SHA2 hash digest from Blob.
  public func fromBlob(algo : Algorithm, b : Blob) : Blob {
    let digest = Digest(algo);
    digest.writeIter(b.vals());
    return digest.sum();
  };
};
