import Array "mo:base/Array";
import Iter "mo:base/Iter";

import Debug "mo:base/Debug";

import Array_ "mo:base/Array";
import Copy "../src/Copy";

let n = Array.init<Nat>(10, 0);
let m = Iter.toArray(Iter.range(0, 9));

Copy.copy(n, m);
assert(Array.freeze(n) == m);

// copy(n[5:], m)
Copy.copyOffset(n, 5, m, 0);
assert(Array.freeze(n) == [0, 1, 2, 3, 4, 0, 1, 2, 3, 4]);

// copy(n[6:], n)
Copy.copyOffsetVar(n, 6, n, 0);
assert(Array.freeze(n) == [0, 1, 2, 3, 4, 0, 0, 1, 2, 3]);
