import Char "mo:base/Char";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";

import P "Parser";
import L "List";

import D "mo:base/Debug";

module {
    private type List<T> = List.List<T>;
    private type Parser<T, A> = P.Parser<T, A>;

    // Integrates the sequencing of parsers with the processing of their result values.
    public func bind<T, A, B>(
        parserA : Parser<T, A>,
        function : A -> Parser<T, B>,
    ) : Parser<T, B> {
        func (xs : List<T>) {
            switch (parserA(xs)) {
                case (null) { null };
                case (? (a, xs)) {
                    function(a)(xs);
                };
            };
        };
    };

    // Applies one parser after another, with the results from the two parsers being combined as pairs. 
    public func seq<T, A, B>(
        parserA : Parser<T, A>,
        parserB : Parser<T, B>,
    ) : Parser<T, (A, B)> {
        bind(
            parserA,
            func (a : A) : Parser<T, (A, B)> {
                bind(
                    parserB,
                    func (b : B) : Parser<T, (A, B)> { 
                        P.result((a, b));
                    },
                );
            },
        );
    };

    // Yields a parser that consumes a single item if it satisfies the predicate, and fails otherwise.
    public func sat<T>(
        ok : T -> Bool,
    ) : Parser<T, T> {
        bind(
            P.item<T>(),
            func (t : T) : Parser<T, T> {
                if (ok(t)) {
                    return P.result(t);
                };
                P.zero();
            },
        );
    };

    // Decides between parsing a single item and recursing, or parsing nothing further and terminating.
    public func choose<T, A>(
        parser1 : Parser<T, A>,
        parser2 : Parser<T, A>,
    ) : Parser<T, A> {
        func (xs : List<T>) {
            switch (parser1(xs)) {
                case (? x) { ?x; };
                case (null) {
                    parser2(xs);
                };
            };
        };
    };

    // =>
    public func map<T, A, B>(
        parserA : Parser<T, A>,
        function : A -> B,
    ) : Parser<T, B>{
        bind(
            parserA,
            func (a : A) : Parser<T, B> {
                P.result<T, B>(function(a));
            },
        );
    };

    // >>
    public func right<T, A, B>(
        parserA : Parser<T, A>,
        parserB : Parser<T, B>,
    ) : Parser<T, B> {
        bind(
            parserA,
            func (_ : A) : Parser<T, B> {
                parserB;
            },
        );
    };

    // <<
    public func left<T, A, B>(
        parserA : Parser<T, A>,
        parserB : Parser<T, B>,
    ) : Parser<T, A> {
        bind(
            parserA,
            func (a : A) : Parser<T, A> {
                bind(
                    parserB,
                    func (_ : B) : Parser<T, A> {
                        P.result<T, A>(a);
                    },
                );
            },
        );
    };

    // <~>
    public func cons<T, A>(
        parserA : Parser<T, A>,
        parserAs : Parser<T, List<A>>,
    ) : Parser<T, List<A>> {
        bind(
            parserA,
            func (a : A) : Parser<T, List<A>> {
                bind(
                    parserAs,
                    func (as : List<A>) : Parser<T, List<A>> {
                        P.result<T, List<A>>(List.push(a, as));
                    },
                );
            },
        );
    };

    // Applies a parser p zero or more times to the input.
    public func many<T, A>(
        parserA : Parser<T, A>,
    ) : Parser<T, List<A>> {
        choose(
            // Same as <~> parserA (many parserA), but not 
            // possible because of recursive call.
            bind(
                parserA,
                func (a : A) : Parser<T, List<A>> {
                    bind(
                        many(parserA),
                        func (as : List<A>) : Parser<T, List<A>> {
                            P.result<T, List<A>>(List.push(a, as));
                        },
                    );
                },
            ),
            P.result<T, List<A>>(List.nil()),
        );
    };

    // Non-empty sequences of items.
    public func many1<T, A>(
        parserA : Parser<T, A>,
    ) : Parser<T, List<A>> {
        cons(
            parserA, 
            many(parserA),
        );
    };

    // Recognises non-empty sequences of a given parser p, but different in that the instances of p are separated by a 
    // parser sep whose result values are ignored.
    public func sepBy1<T, A, B>(
        parserA : Parser<T, A>,
        parserB : Parser<T, B>, // sep
    ) : Parser<T, List<A>> {
        cons(
            parserA, 
            many(right(parserB, parserA)),
        );
    };

    // Bracketing of parsers by other parsers whose results are ignored.
    public func bracket<T, A, B, C>(
        parserA : Parser<T, A>, // left bracket
        parserB : Parser<T, B>,
        parserC : Parser<T, C>, // right bracket
    ) : Parser<T, B> {
        right(
            parserA, 
            left(parserB, parserC),
        );
    };

    // Parses sequences of a given parser p, separated by a parser sep whose result values are ignored.
    public func sepBy<T, A, B>(
        parserA : Parser<T, A>,
        parserB : Parser<T, B>, // sep
    ) : Parser<T, List<A>> {
        choose(
            sepBy1(parserA, parserB),
            P.result<T, List<A>>(List.nil()),
        );
    };

    public func oneOf<T, A>(
        parsers : [Parser<T, A>],
    ) : Parser<T, A> {
        func (xs : List<T>) {
            for (parser in parsers.vals()) {
                switch (parser(xs)) {
                    case (? v) { return ?v; };
                    case (_) {};
                };
            };
            null;
        };
    };

    public module Character {
        private type CharParser = Parser<Char, Char>;

        public func char(x : Char) : CharParser {
            sat(func (y : Char) : Bool { x == y });
        };

        public func digit() : CharParser {
            sat(func (x : Char) : Bool {
                '0' <= x and x <= '9';
            });
        };

        public func lower() : CharParser {
            sat(func (x : Char) : Bool {
                'a' <= x and x <= 'z';
            });
        };

        public func upper() : CharParser {
            sat(func (x : Char) : Bool {
                'A' <= x and x <= 'Z';
            });
        };

        public func letter() : CharParser {
            choose(lower(), upper());
        };

        public func alphanum() : CharParser {
            choose(letter(), digit());
        };

        public func oneOf(
            xs : [Char]
        ) : CharParser {
            sat(func(c : Char) : Bool {
                for (x in xs.vals()) {
                    if (c == x) { return true; };
                };
                false;
            });
        };

        public func space() : CharParser {
            oneOf([' ', '\n', '\t', '\r']);
        };
    };

    public module String {
        private type StringParser = Parser<Char, Text>;

        public func word() : StringParser {
            map(
                many(Character.letter()),
                func (xs : List<Char>) : Text {
                    Text.fromIter(L.toIter(xs));
                },
            );
        };

        public func string(t : Text) : StringParser {
            func iter(i : Iter.Iter<Char>) : StringParser {
                switch (i.next()) {
                    case (null) { P.result(t); };
                    case (? v)  {
                        right(
                            Character.char(v),
                            iter(i),
                        );
                    };
                };
            };
            iter(t.chars());
        };
    };

    public module Nat {
        func toNat(xs : List<Char>) : Nat {
            let ord0 = Char.toNat32('0');
            let n = List.foldLeft<Char, Nat>(
                xs,
                0,
                func (n : Nat, c : Char) : Nat {
                    10 * n + Nat32.toNat((Char.toNat32(c) - ord0));
                },
            );
            n;
        };

        public func nat() : Parser<Char, Nat> {
            map(
                many1(Character.digit()),
                toNat,
            );
        };
    };

    public module Int {
        public func int() : Parser<Char, Int> {
            func (xs : List<Char>) {
                let (op, ys) = switch(Character.char('-')(xs)) {
                    case (null)      { (func (n : Nat) : Int {  n; }, xs); };
                    case (? (_, xs)) { (func (n : Nat) : Int { -n; }, xs); };
                };
                map<Char, Nat, Int>(
                    Nat.nat(),
                    op,
                )(ys);
            }
        };
    };
};
