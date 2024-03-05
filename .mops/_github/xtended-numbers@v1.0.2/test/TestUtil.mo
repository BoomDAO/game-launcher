import Char "mo:base/Char";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {
    public func bytesAreEqual(b1: [Nat8], b2: [Nat8]) : Bool {

        if (b1.size() != b2.size()) {
            return false;
        };
        for (i in Iter.range(0, b1.size() - 1)) {
            if(b1[i] != b2[i]){
                return false;
            };
        };
        true;
    };


};