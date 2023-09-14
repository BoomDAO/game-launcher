import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import Nat "mo:base/Nat";

import BT "../src/BTree";
import BTM "./BTreeMatchers";
import Check "../src/Check";
import Rand3000 "./rand3000";

func testableNatBTree(t: BT.BTree<Nat, Nat>): T.TestableItem<BT.BTree<Nat, Nat>> {
  BTM.testableBTree(t, Nat.equal, Nat.equal, Nat.toText, Nat.toText)
}; 

// Note: Don't add any more tests do this file, as will overflow wasmtime memory capacity
let btreePropertyTests = S.suite("check validity of mass insertion/deletion", [
  S.suite("BTree with order 4", [
    S.test("deletion from left side retains validity",
      do {
        var i = 0;
        let t = BT.init<Nat, Nat>(?4);
        while (i < 2000) {
          ignore BT.insert<Nat, Nat>(t, Nat.compare, i, i);
          i += 1
        };

        i := 0;
        while (i < 2000) {
          let deletedValue = BT.delete<Nat, Nat>(t, Nat.compare, i);
          assert deletedValue == ?i;
          switch(Check.checkDataOrderIsValid<Nat, Nat>(t, Nat.compare)) {
            case (#ok) {};
            case (#err) { assert false };
          };
          switch(Check.checkTreeDepthIsValid<Nat, Nat>(t)) {
            case (#ok(_)) {};
            case (#err) { assert false };
          };
          i += 1;
        };

        t
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var null, null, null];
            var count = 0;
          }
        });
        var size = 0;
        order = 4;
      }))
    ),
    S.test("deletion from right side retains validity",
      do {
        var i = 0;
        let t = BT.init<Nat, Nat>(?4);
        while (i < 2000) {
          ignore BT.insert<Nat, Nat>(t, Nat.compare, i, i);
          i += 1
        };

        i := 2000 - 1;
        label l loop {
          let deletedValue = BT.delete<Nat, Nat>(t, Nat.compare, i);
          assert deletedValue == ?i;
          switch(Check.checkDataOrderIsValid<Nat, Nat>(t, Nat.compare)) {
            case (#ok) {};
            case (#err) { assert false };
          };
          switch(Check.checkTreeDepthIsValid<Nat, Nat>(t)) {
            case (#ok(_)) {};
            case (#err) { assert false };
          };
          if (i == 0) { break l };

          i -= 1;
        };

        t
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var null, null, null];
            var count = 0;
          }
        });
        var size = 0;
        order = 4;
      }))
    ),
    S.test("random deletion retains validity",
      do {
        var i = 0;
        let t = BT.init<Nat, Nat>(?4);
        while (i < 3000) {
          ignore BT.insert<Nat, Nat>(t, Nat.compare, i, i);
          i += 1
        };

        for (key in Rand3000.rand3000.vals()) {
          let deletedValue = BT.delete<Nat, Nat>(t, Nat.compare, key);
          assert deletedValue == ?key;
          switch(Check.checkDataOrderIsValid<Nat, Nat>(t, Nat.compare)) {
            case (#ok) {};
            case (#err) { assert false };
          };
          switch(Check.checkTreeDepthIsValid<Nat, Nat>(t)) {
            case (#ok(_)) {};
            case (#err) { assert false };
          };
        };

        t
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var null, null, null]; 
            var count = 0;
          }
        });
        var size = 0;
        order = 4;
      }))
    ),
  ]),
]);

S.run(btreePropertyTests);