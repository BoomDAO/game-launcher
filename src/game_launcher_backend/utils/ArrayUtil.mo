import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import { Array_tabulate } = "mo:⛔";

module Util {
    public func copy<T>(
        n : Nat,   // Position to start writing.
        dst : [var T], 
        src : [T],
    ) : Nat {
        let l = dst.size();
        for (i in src.keys()) {
            if (l <= i) return l;
            dst[n + i] := src[i];
        };
        src.size();
    };

    public func removeN<T>(
        n : Nat,  // Number to remove.
        xs : [T],
    ) : [T] {
        Array.tabulate<T>(
            xs.size() - n,
            func (i : Nat) : T {
                xs[i + n];
            },
        );
    };

    public func takeN<T>(
        n : Nat,  // Number to take.
        xs : [T],
    ) : [T] {
        Array.tabulate<T>(
            n,
            func (i : Nat) : T {
                xs[i];
            },
        );
    };

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

    // Checks whether an array contains a given value.
    public func contains<T>(xs : [T], y : T, equal : (T, T) -> Bool) : Bool {
        for (x in xs.vals()) {
            if (equal(x, y)) return true;
        }; false;
    };

    // Drops the first 'n' elements of an array, returns the remainder of that array.
    public func drop<T>(xs : [T], n : Nat) : [T] {
        let xS = xs.size();
        if (xS <= n) return [];
        let s = xS - n : Nat;
        Array_tabulate<T>(s, func (i : Nat) : T { xs[n + i]; });
    };

    // Slices out [i-j[ elements of an array.
    public func slice<T>(xs : [T], i : Nat, j : Nat) : [T] {
        if (j < i) return [];
        if (j == i) return [xs[i]];
        Array_tabulate<T>(j - i, func (k : Nat) : T { xs[i+k]; });
    };

    // Splits an array in two parts, based on the given element index.
    public func split<T>(xs : [T], n : Nat) : ([T], [T]) {
        if (n == 0) { return (xs, [] : [T]); };
        let xS = xs.size();
        if (xS <= n) { return ([] : [T], xs); };
        let s = xS - n : Nat;
        (
            Array_tabulate<T>(n, func (i : Nat) : T { xs[i]; }),
            Array_tabulate<T>(s, func (i : Nat) : T { xs[n + i]; })
        );
    };

    // Returns the first 'n' elements of an array.
    public func take<T>(xs : [T], n : Nat) : [T] {
        let xS = xs.size();
        if (xS <= n) return xs;
        Array_tabulate<T>(n, func (i : Nat) : T { xs[i]; });
    };
};