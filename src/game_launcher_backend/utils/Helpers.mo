import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Char "mo:base/Char";
import Error "mo:base/Error";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import L "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";

module {
    //util types
    //
    public type headerField = (Text, Text);
    public type HttpRequest = {
        body : Blob;
        headers : [headerField];
        method : Text;
        url : Text;
    };
    public type HttpResponse = {
        body : Blob;
        headers : [headerField];
        status_code : Nat16;
    };

    //utility functions
    //
    public func key(x : Nat32) : Trie.Key<Nat32> {
        return { hash = x; key = x };
    };

    public func keyT(x : Text) : Trie.Key<Text> {
        return { hash = Text.hash(x); key = x };
    };

    public func textToNat(txt : Text) : Nat {
        assert (txt.size() > 0);
        let chars = txt.chars();

        var num : Nat = 0;
        for (v in chars) {
            let charToNum = Nat32.toNat(Char.toNat32(v) -48);
            assert (charToNum >= 0 and charToNum <= 9);
            num := num * 10 + charToNum;
        };

        return num;
    };

    public func textToFloat(t : Text) : Float {
        var i : Float = 1;
        var f : Float = 0;
        var isDecimal : Bool = false;
        for (c in t.chars()) {
            if (Char.isDigit(c)) {
                let charToNat : Nat64 = Nat64.fromNat(Nat32.toNat(Char.toNat32(c) -48));
                let natToFloat : Float = Float.fromInt64(Int64.fromNat64(charToNat));
                if (isDecimal) {
                    let n : Float = natToFloat / Float.pow(10, i);
                    f := f + n;
                } else {
                    f := f * 10 + natToFloat;
                };
                i := i + 1;
            } else {
                if (Char.equal(c, '.') or Char.equal(c, ',')) {
                    f := f / Float.pow(10, i); // Force decimal
                    f := f * Float.pow(10, i); // Correction
                    isDecimal := true;
                    i := 1;
                } else {};
            };
        };

        return f;
    };

    public func textToarray(text : Text) : async ([Nat8]) {
        var blob : Blob = Text.encodeUtf8(text);
        var array : [Nat8] = Blob.toArray(blob);
        return array;
    };
};
