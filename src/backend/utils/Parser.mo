import List "mo:base/List";

module Parser {
    private type List<T> = List.List<T>;
    public type Parser<T, A> = List<T> -> ?(A, List<T>);

    // Succeeds without consuming any of the input, and returns the single result x.
    public func result<T, A>(a : A) : Parser<T, A> {
        func (xs : List<T>) { ?(a, xs); };
    };

    // Always fails, regardless of the input.
    public func zero<T, A>() : Parser<T, A> {
        func (_ : List<T>) { null; };
    };

    // Successfully consumes the first item if the input is non-empty, and fails otherwise.
    public func item<T>() : Parser<T, T> {
        func (xs : List<T>) {
            switch(xs) {
                case (null) { null; };
                case (? (x, xs)) {
                    ?(x, xs);
                };
            };
        };
    };

    // Delays the recursion.
    public func delay<T, A>(
        function : () -> Parser<T, A>,
    ) : Parser<T, A> {
        func (xs : List<T>) { function()(xs); };
    };
};
