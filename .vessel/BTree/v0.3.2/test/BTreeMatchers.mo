import BT "../src/BTree";
import T "mo:matchers/Testable";
import Nat "mo:base/Nat";

module {
  public func testableBTree<K, V>(
    t: BT.BTree<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool,
    keyToText: K -> Text,
    valueToText: V -> Text,
  ): T.TestableItem<BT.BTree<K, V>> = {
    display = func(t: BT.BTree<K, V>): Text = BT.toText<K, V>(t, keyToText, valueToText);
    equals = func(t1: BT.BTree<K, V>, t2: BT.BTree<K, V>): Bool {
      BT.equals(t1, t2, keyEquals, valueEquals);
    }; 
    item = t;
  };

  public func testableNatBTreeScanLimitResult(scanLimitResult: BT.ScanLimitResult<Nat, Nat>): T.TestableItem<BT.ScanLimitResult<Nat, Nat>> = {
    display = func({
      results: [(Nat, Nat)];
      nextKey: ?Nat;
    }: BT.ScanLimitResult<Nat, Nat>): Text {
      var output = "{ results=[";
      for ((k, v) in results.vals()) {
        output #= "(" # Nat.toText(k) # "," # Nat.toText(v) # "),";
      };
      output # "]; nextKey=" # debug_show(nextKey);
    };
    equals = func(
      r1: BT.ScanLimitResult<Nat, Nat>,
      r2: BT.ScanLimitResult<Nat, Nat>
    ): Bool {
      func resultsEqual(r1: [(Nat, Nat)], r2: [(Nat, Nat)]): Bool {
        if (r1.size() != r2.size()) { return false };
        var i = 0;
        for ((k1, v1) in r1.vals()) {
          if (not (Nat.equal(k1, r2[i].0) and Nat.equal(v1, r2[i].1))) { return false };
          i += 1;
        };
        true
      };

      switch(r1.nextKey, r2.nextKey) {
        case (null, null) { resultsEqual(r1.results, r2.results) };
        case (?k1, ?k2) { Nat.equal(k1, k2) and resultsEqual(r1.results, r2.results)};
        case _ { false }
      };
    };
    item = scanLimitResult;
  }
}