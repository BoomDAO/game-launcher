import Iter "mo:base/Iter";
import Int "mo:base/Int";

module {
    public func swap<A>(arr:[var A], a: Nat, b: Nat) {
        let tmp = arr[a];
        arr[a] := arr[b];
        arr[b] := tmp;
    };

    public func reverseFrom<A>(arr: [var A], start: Nat) {
        reverseRange(arr, start, Int.abs(arr.size() - 1));
    };

    public func reverseRange<A>(arr: [var A], start: Nat, end: Nat) {
        assert(end < arr.size());

        var i = start;
        var j = end;

        while (i < j){
            swap(arr, i, j);
            i += 1;
            j -= 1;
        };
    };
}