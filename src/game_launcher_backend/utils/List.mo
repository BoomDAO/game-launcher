import Iter "mo:base/Iter";
import List "mo:base/List";

module {
    private type List<T> = List.List<T>;

    public func fromText(t : Text) : List<Char> {
        fromIter(t.chars());
    };

    public func fromIter<T>(i : Iter.Iter<T>) : List<T> {
        switch (i.next()) {
            case (null) { null; };
            case (? v)  { ?(v, fromIter(i)); };
        };
    };

    public class toIter<T>(xs : List<T>) : Iter.Iter<T> {
        var list = xs;
        public func next() : ?T {
            switch (list) {
                case (null) { null; };
                case (? ys) {
                    let (x, xs) = ys;
                    list := xs;
                    ?x;
                };
            };
        };
    };
}