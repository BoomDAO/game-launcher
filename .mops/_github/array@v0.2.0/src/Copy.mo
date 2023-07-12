import Nat "mo:base/Nat";

module {
    public func copy<T>(dst : [var T], src : [T]) {
        copyOffset<T>(dst, 0, src, 0);
    };

    public func copyOffset<T>(dst : [var T], startDst : Nat, src : [T], startSrc : Nat) {
        let n = Nat.min(
            dst.size() - startDst,
            src.size() - startSrc,  
        );
        var i = 0;
        while (i < n) {
            dst[startDst + i] := src[startSrc + i];
            i += 1;
        };
    };

    public func copyVar<T>(dst : [var T], src : [var T]) {
        copyOffsetVar<T>(dst, 0, src, 0);
    };

    public func copyOffsetVar<T>(dst : [var T], startDst : Nat, src : [var T], startSrc : Nat) {
        let n = Nat.min(
            dst.size() - startDst,
            src.size() - startSrc,  
        );
        var i = 0;
        while (i < n) {
            dst[startDst + i] := src[startSrc + i];
            i += 1;
        };
    };
};