import Array "mo:base/Array";

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
};