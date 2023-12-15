/// **Dyadic intervals**
///
/// This module is mostly internal to `MerkleTree`. It is a separate module mainly to expose
/// its code for the test suite without polluting the `MerkleTree` interface.

import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";

module {

  public type Prefix = [Nat8];
  public type IntervalLength = Nat;

  /// A diadic interval, identified by a common prefix and its length in bits
  public type Interval = { prefix : Prefix; len : IntervalLength };

  public func singleton(p : Prefix) : Interval {
    return { prefix = p; len = p.size() * 8};
  };

  /// Smart constructor. Normalizes the prefix by setting all bits beyond len to zero.
  public func mk(p : Prefix, i : IntervalLength) : Interval {
    if (i % 8 != 0 and i / 8 < p.size() ) {
      let byte = p[i/8];
      let mask = 0xff >> Nat8.fromNat(i % 8);
      if (byte & mask != 0) {
        let a = Array.thaw<Nat8>(p);
        a[i/8] := byte & ^mask;
        return { prefix = Array.freeze(a); len = i}
      }
    };
    return { prefix = p; len = i};
  };

  public type FindResult =
    { #before : IntervalLength;
      #needle_is_prefix;
      #equal;
      #in_left_half;
      #in_right_half;
      #after : IntervalLength;
    };
  public func find(needle: Prefix, i : Interval) : FindResult {
    // Debug.print(debug_show (i.len, i.prefix.size()));
    assert(i.len <= i.prefix.size() * 8);

    var bi = 0;
    let end = Nat.min(needle.size() * 8, i.len+1);
    while (bi < end) {
      // This is the case when i.len points to the first bit of the byte after the prefix
      // (Could alternatively require i.len < i.prefix.size()*8 and require padded prefixes )
      if (bi == i.prefix.size() * 8) {
        let b1 = needle[bi / 8];
        if (Nat8.bittest(b1, 7 - (i.len - bi))) {
          return #in_right_half
        } else {
          return #in_left_half
        }
      } else {
        let b1 = needle[bi / 8];
        let b2 = i.prefix[bi / 8];

        let mask : Nat8 =
          if (bi == i.len) { 0x00 }
          else { 0xff << Nat8.fromNat(8 - Nat.min(i.len - bi, 8)) };
        let mb1 = b1 & mask;
        let mb2 = b2 & mask;

        if (mb1 == mb2) {
          // good so far
          if (bi + 8 <= i.len) {
            // more bytes to compare, so continue
            bi += 8
          } else {
            if (Nat8.bittest(b1, 7 - (i.len - bi))) {
              return #in_right_half
            } else {
              return #in_left_half
            }
          }
        } else {
          // needle is not in the interval
          if (mb1 < mb2) {
            // needle is before the interval
            return #before (bi + Nat8.toNat(Nat8.bitcountLeadingZero(mb1 ^ mb2)));
          } else {
            // needle is after the interval
            return #after (bi + Nat8.toNat(Nat8.bitcountLeadingZero(mb1 ^ mb2)));
          }
        }
      }
    };
    // All common bits are equal
    if (i.len == needle.size() * 8) {
      return #equal
    } else {
      return #needle_is_prefix;
    }
  };

}

