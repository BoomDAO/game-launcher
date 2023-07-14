import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Deque "mo:base/Deque";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Float "mo:base/Float";
import Func "mo:base/Func";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import ActorSpec "./utils/ActorSpec";

import DoubleEndedIter "../src/Deiter";
import Itertools "../src/Iter";
import PeekableIter "../src/PeekableIter";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

let success = run([
    describe(
        "Custom Iterators",
        [
            it(
                "sum of 1 to 25",
                do {
                    let range = Itertools.range(1, 25 + 1);
                    let sum = Itertools.sum(range, Nat.add);

                    assertTrue(sum == ?325);
                },
            ),
            it(
                "find indices of elem that match a predicate",
                do {
                    let arr = [1, 2, 3, 4, 5, 6];
                    let iterWithIndices = Itertools.enumerate<Int>(arr.vals());

                    let mapIndicesOfEvenVals = func(x : (Int, Int)) : ?Int {
                        if (x.1 % 2 == 0) {
                            ?x.0;
                        } else {
                            null;
                        };
                    };

                    let evenIndices = Itertools.mapFilter(iterWithIndices, mapIndicesOfEvenVals);

                    assertTrue(Iter.toArray(evenIndices) == [1, 3, 5]);
                },
            ),
            it(
                "diff between consecutive elem in an arr",
                do {
                    let vals = [5, 3, 3, 7, 8, 10].vals();

                    let tuples = Itertools.slidingTuples(vals);

                    let diff = func(x : (Int, Int)) : Int { x.1 - x.0 };
                    let iter = Iter.map(tuples, diff);

                    assertTrue(Iter.toArray(iter) == [-2, 0, 4, 1, 2]);
                },
            ),
        ],
    ),
    describe(
        "Iter",
        [
            describe(
                "accumulate",
                [
                    it(
                        "sum",
                        do {
                            let vals = [1, 2, 3, 4].vals();
                            let it = Itertools.accumulate<Nat>(vals, func(a, b) { a + b });

                            assertAllTrue([
                                it.next() == ?1,
                                it.next() == ?3,
                                it.next() == ?6,
                                it.next() == ?10,
                                it.next() == null,
                            ]);
                        },
                    ),
                    it(
                        "product",
                        do {
                            let vals = [1, 2, 3, 4].vals();
                            let it = Itertools.accumulate<Int>(
                                vals,
                                func(a, b) { a * b },
                            );

                            assertAllTrue([
                                it.next() == ?1,
                                it.next() == ?2,
                                it.next() == ?6,
                                it.next() == ?24,
                                it.next() == null,
                            ]);
                        },
                    ),
                    it(
                        "complex record type",
                        do {
                            type Point = { x : Int; y : Int };

                            let points = [
                                { x = 1; y = 2 },
                                { x = 3; y = 4 },
                            ].vals();

                            let it = Itertools.accumulate<Point>(
                                points,
                                func(a, b) {
                                    return { x = a.x + b.x; y = a.y + b.y };
                                },
                            );

                            assertAllTrue([
                                it.next() == ?{ x = 1; y = 2 },
                                it.next() == ?{ x = 4; y = 6 },
                                it.next() == null,
                            ]);
                        },
                    ),
                ],
            ),
            it(
                "add",
                do {
                    let a = "moto";

                    let iter = Itertools.add(Itertools.add(a.chars(), 'k'), 'o');
                    let motoko = Itertools.toText(iter);

                    assertTrue(
                        motoko == "motoko",
                    );
                },
            ),
            it(
                "all",
                do {

                    let a = [1, 2, 3, 4].vals();
                    let b = [2, 4, 6, 8].vals();

                    let isEven = func(a : Int) : Bool { a % 2 == 0 };

                    assertAllTrue([
                        Itertools.all(a, isEven) == false,
                        Itertools.all(b, isEven) == true,
                    ]);
                },
            ),
            it(
                "any",
                do {
                    let a = [1, 2, 3, 4].vals();
                    let b = [1, 3, 5, 7].vals();

                    let isEven = func(a : Nat) : Bool { a % 2 == 0 };

                    assertAllTrue([
                        Itertools.any(a, isEven) == true,
                        Itertools.any(b, isEven) == false,
                    ]);
                },
            ),
            it(
                "cartesianProduct",
                do {
                    let a = [1, 2, 3, 4, 5].vals();
                    let b = "abcdefghijklmnopqrstuvwxyz".chars();

                    let it = Itertools.cartesianProduct(a, b);
                    let res = Iter.toArray(it);

                    assertTrue(
                        res == [
                            (1, 'a'),
                            (1, 'b'),
                            (1, 'c'),
                            (1, 'd'),
                            (1, 'e'),
                            (1, 'f'),
                            (1, 'g'),
                            (1, 'h'),
                            (1, 'i'),
                            (1, 'j'),
                            (1, 'k'),
                            (1, 'l'),
                            (1, 'm'),
                            (1, 'n'),
                            (1, 'o'),
                            (1, 'p'),
                            (1, 'q'),
                            (1, 'r'),
                            (1, 's'),
                            (1, 't'),
                            (1, 'u'),
                            (1, 'v'),
                            (1, 'w'),
                            (1, 'x'),
                            (1, 'y'),
                            (1, 'z'),
                            (2, 'a'),
                            (2, 'b'),
                            (2, 'c'),
                            (2, 'd'),
                            (2, 'e'),
                            (2, 'f'),
                            (2, 'g'),
                            (2, 'h'),
                            (2, 'i'),
                            (2, 'j'),
                            (2, 'k'),
                            (2, 'l'),
                            (2, 'm'),
                            (2, 'n'),
                            (2, 'o'),
                            (2, 'p'),
                            (2, 'q'),
                            (2, 'r'),
                            (2, 's'),
                            (2, 't'),
                            (2, 'u'),
                            (2, 'v'),
                            (2, 'w'),
                            (2, 'x'),
                            (2, 'y'),
                            (2, 'z'),
                            (3, 'a'),
                            (3, 'b'),
                            (3, 'c'),
                            (3, 'd'),
                            (3, 'e'),
                            (3, 'f'),
                            (3, 'g'),
                            (3, 'h'),
                            (3, 'i'),
                            (3, 'j'),
                            (3, 'k'),
                            (3, 'l'),
                            (3, 'm'),
                            (3, 'n'),
                            (3, 'o'),
                            (3, 'p'),
                            (3, 'q'),
                            (3, 'r'),
                            (3, 's'),
                            (3, 't'),
                            (3, 'u'),
                            (3, 'v'),
                            (3, 'w'),
                            (3, 'x'),
                            (3, 'y'),
                            (3, 'z'),
                            (4, 'a'),
                            (4, 'b'),
                            (4, 'c'),
                            (4, 'd'),
                            (4, 'e'),
                            (4, 'f'),
                            (4, 'g'),
                            (4, 'h'),
                            (4, 'i'),
                            (4, 'j'),
                            (4, 'k'),
                            (4, 'l'),
                            (4, 'm'),
                            (4, 'n'),
                            (4, 'o'),
                            (4, 'p'),
                            (4, 'q'),
                            (4, 'r'),
                            (4, 's'),
                            (4, 't'),
                            (4, 'u'),
                            (4, 'v'),
                            (4, 'w'),
                            (4, 'x'),
                            (4, 'y'),
                            (4, 'z'),
                            (5, 'a'),
                            (5, 'b'),
                            (5, 'c'),
                            (5, 'd'),
                            (5, 'e'),
                            (5, 'f'),
                            (5, 'g'),
                            (5, 'h'),
                            (5, 'i'),
                            (5, 'j'),
                            (5, 'k'),
                            (5, 'l'),
                            (5, 'm'),
                            (5, 'n'),
                            (5, 'o'),
                            (5, 'p'),
                            (5, 'q'),
                            (5, 'r'),
                            (5, 's'),
                            (5, 't'),
                            (5, 'u'),
                            (5, 'v'),
                            (5, 'w'),
                            (5, 'x'),
                            (5, 'y'),
                            (5, 'z'),
                        ],
                    );
                },
            ),
            it(
                "chain",
                do {
                    let iter1 = [1, 2].vals();
                    let iter2 = [3, 4].vals();
                    let chained = Itertools.chain(iter1, iter2);

                    assertAllTrue([
                        chained.next() == ?1,
                        chained.next() == ?2,
                        chained.next() == ?3,
                        chained.next() == ?4,
                        chained.next() == null,
                    ]);
                },
            ),
            it(
                "chunks",
                do {
                    let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();
                    let it = Itertools.chunks<Nat>(vals, 3);

                    assertAllTrue([
                        it.next() == ?[1, 2, 3],
                        it.next() == ?[4, 5, 6],
                        it.next() == ?[7, 8, 9],
                        it.next() == ?[10],
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "chunksExact",
                do {
                    let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();
                    let it = Itertools.chunksExact(vals, 3);

                    assertAllTrue([
                        it.next() == ?[1, 2, 3],
                        it.next() == ?[4, 5, 6],
                        it.next() == ?[7, 8, 9],
                        it.next() == null,
                    ]);
                },
            ),

            describe(
                "combinations",
                [
                    it(
                        "size 2, range 1 - 4",
                        do {
                            let vals = [1, 2, 3, 4].vals();
                            let it = Itertools.combinations(vals, 2);

                            let res = Iter.toArray(it);
                            assertTrue(
                                res == [
                                    [1, 2],
                                    [1, 3],
                                    [1, 4],
                                    [2, 3],
                                    [2, 4],
                                    [3, 4],
                                ],
                            );
                        },
                    ),
                    it(
                        "size 3, range 1 - 9",
                        do {
                            let vals = Iter.range(1, 9);
                            let it = Itertools.combinations(vals, 3);

                            let res = Iter.toArray(it);

                            assertTrue(
                                res == [
                                    [1, 2, 3],
                                    [1, 2, 4],
                                    [1, 2, 5],
                                    [1, 2, 6],
                                    [1, 2, 7],
                                    [1, 2, 8],
                                    [1, 2, 9],
                                    [1, 3, 4],
                                    [1, 3, 5],
                                    [1, 3, 6],
                                    [1, 3, 7],
                                    [1, 3, 8],
                                    [1, 3, 9],
                                    [1, 4, 5],
                                    [1, 4, 6],
                                    [1, 4, 7],
                                    [1, 4, 8],
                                    [1, 4, 9],
                                    [1, 5, 6],
                                    [1, 5, 7],
                                    [1, 5, 8],
                                    [1, 5, 9],
                                    [1, 6, 7],
                                    [1, 6, 8],
                                    [1, 6, 9],
                                    [1, 7, 8],
                                    [1, 7, 9],
                                    [1, 8, 9],
                                    [2, 3, 4],
                                    [2, 3, 5],
                                    [2, 3, 6],
                                    [2, 3, 7],
                                    [2, 3, 8],
                                    [2, 3, 9],
                                    [2, 4, 5],
                                    [2, 4, 6],
                                    [2, 4, 7],
                                    [2, 4, 8],
                                    [2, 4, 9],
                                    [2, 5, 6],
                                    [2, 5, 7],
                                    [2, 5, 8],
                                    [2, 5, 9],
                                    [2, 6, 7],
                                    [2, 6, 8],
                                    [2, 6, 9],
                                    [2, 7, 8],
                                    [2, 7, 9],
                                    [2, 8, 9],
                                    [3, 4, 5],
                                    [3, 4, 6],
                                    [3, 4, 7],
                                    [3, 4, 8],
                                    [3, 4, 9],
                                    [3, 5, 6],
                                    [3, 5, 7],
                                    [3, 5, 8],
                                    [3, 5, 9],
                                    [3, 6, 7],
                                    [3, 6, 8],
                                    [3, 6, 9],
                                    [3, 7, 8],
                                    [3, 7, 9],
                                    [3, 8, 9],
                                    [4, 5, 6],
                                    [4, 5, 7],
                                    [4, 5, 8],
                                    [4, 5, 9],
                                    [4, 6, 7],
                                    [4, 6, 8],
                                    [4, 6, 9],
                                    [4, 7, 8],
                                    [4, 7, 9],
                                    [4, 8, 9],
                                    [5, 6, 7],
                                    [5, 6, 8],
                                    [5, 6, 9],
                                    [5, 7, 8],
                                    [5, 7, 9],
                                    [5, 8, 9],
                                    [6, 7, 8],
                                    [6, 7, 9],
                                    [6, 8, 9],
                                    [7, 8, 9],
                                ],
                            );
                        },
                    ),
                    it(
                        "size equal to range length",
                        do {
                            let vals = Iter.range(1, 5);
                            let it = Itertools.combinations(vals, 5);

                            let res = Iter.toArray(it);
                            assertTrue(
                                res == [[1, 2, 3, 4, 5]],
                            );
                        },
                    ),
                    it(
                        "size greater than range length",
                        do {
                            let vals = Iter.range(1, 5);
                            let it = Itertools.combinations(vals, 6);

                            let res = Iter.toArray(it);

                            assertTrue(res == []);
                        },
                    ),
                    it(
                        "size 1, range 1 - 5",
                        do {
                            let vals = Iter.range(1, 5);
                            let it = Itertools.combinations(vals, 1);

                            let res = Iter.toArray(it);

                            assertTrue(
                                res == [
                                    [1],
                                    [2],
                                    [3],
                                    [4],
                                    [5],
                                ],
                            );
                        },
                    ),
                ],
            ),
            it(
                "count",
                do {
                    let a = [1, 2, 3, 1, 2].vals();
                    let freq = Itertools.count(a, 1, Nat.equal);

                    assertTrue(freq == 2);
                },
            ),
            it(
                "countAll",
                do {
                    let iter = Iter.map("motoko".chars(), Char.toText);

                    let freqMap = Itertools.countAll(iter, Text.hash, Text.equal);

                    let res = Iter.toArray(freqMap.entries());

                    assertTrue(
                        res == [
                            ("m", 1),
                            ("o", 3),
                            ("t", 1),
                            ("k", 1),
                        ],
                    );
                },
            ),
            it(
                "cycle",
                do {
                    let chars = "abc".chars();
                    let it = Itertools.cycle(chars, 2);

                    assertAllTrue([
                        it.next() == ?'a',
                        it.next() == ?'b',
                        it.next() == ?'c',

                        it.next() == ?'a',
                        it.next() == ?'b',
                        it.next() == ?'c',

                        it.next() == ?'a',
                        it.next() == ?'b',
                        it.next() == ?'c',

                        it.next() == null,
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "enumerate",
                do {
                    let chars = "abc".chars();
                    let iter = Itertools.enumerate(chars);

                    assertAllTrue([
                        iter.next() == ?(0, 'a'),
                        iter.next() == ?(1, 'b'),
                        iter.next() == ?(2, 'c'),
                        iter.next() == null,
                    ]);
                },
            ),
            it(
                "empty",
                do {

                    let it = Itertools.empty();
                    assertTrue(it.next() == null);
                },
            ),

            describe(
                "equal",
                [
                    it(
                        "two equal iters",
                        do {
                            let it1 = Iter.range(1, 5);
                            let it2 = Iter.range(1, 5);

                            assertTrue(
                                Itertools.equal(it1, it2, Nat.equal),
                            );
                        },
                    ),

                    it(
                        "two unequal iters ",
                        do {
                            let it1 = Iter.range(1, 5);
                            let it2 = Iter.range(1, 10);

                            assertFalse(
                                Itertools.equal(it1, it2, Nat.equal),
                            );
                        },
                    ),
                ],
            ),
            it(
                "find",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();

                    let isEven = func(x : Int) : Bool { x % 2 == 0 };
                    let res = Itertools.find<Int>(vals, isEven);

                    assertTrue(res == ?2);
                },
            ),
            it(
                "findIndex",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();

                    let isEven = func(x : Int) : Bool { x % 2 == 0 };
                    let res = Itertools.findIndex<Int>(vals, isEven);

                    assertTrue(res == ?1);
                },
            ),
            it(
                "findIndices",
                do {
                    let vals = [1, 2, 3, 4, 5, 6, 7, 9].vals();

                    let isEven = func(x : Int) : Bool { x % 2 == 0 };
                    let iter = Itertools.findIndices(vals, isEven);

                    let res = Iter.toArray(iter);

                    assertTrue(res == [1, 3, 5]);
                },
            ),
            it(
                "fold",
                do {
                    let arr : [Nat8] = [1, 2, 3, 4, 5];

                    let sumToNat = func(acc : Nat, n : Nat8) : Nat {
                        acc + Nat8.toNat(n);
                    };

                    let sum = Itertools.fold<Nat8, Nat>(arr.vals(), 200, sumToNat);

                    assertTrue(sum == 215);
                },
            ),

            it(
                "flatten",
                do {
                    let nestedIter = [
                        [1].vals(),
                        [2, 3].vals(),
                        [4, 5, 6].vals(),
                    ].vals();

                    let flattened = Itertools.flatten(nestedIter);
                    let res = Iter.toArray(flattened);

                    assertTrue(res == [1, 2, 3, 4, 5, 6])

                },
            ),

            it(
                "flattenArray",
                do {
                    let arr = [
                        [1, 2, 3],
                        [4, 5, 6],
                        [7, 8, 9],
                    ];

                    let flattened = Itertools.flattenArray(arr);
                    let res = Iter.toArray(flattened);

                    assertTrue(res == [1, 2, 3, 4, 5, 6, 7, 8, 9])

                },
            ),

            it(
                "groupBy",
                do {
                    let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();

                    let isFactorOf30 = func(n : Int) : Bool {
                        30.0 % Float.fromInt(n) == 0;
                    };
                    let groups = Itertools.groupBy(vals, isFactorOf30);

                    let res = Iter.toArray(groups);

                    assertTrue(
                        res == [
                            ([1, 2, 3], true),
                            ([4], false),
                            ([5, 6], true),
                            ([7, 8, 9], false),
                            ([10], true),
                        ],
                    );
                },
            ),
            it(
                "inspect",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let debugRes = Buffer.Buffer<Text>(5);

                    let printIfEven = func(n : Nat) {
                        if (n % 2 == 0) {
                            debugRes.add(
                                "This value [ " # debug_show n # " ] is even.",
                            );
                        };
                    };

                    let iter = Itertools.inspect(vals, printIfEven);
                    let res = Iter.toArray(iter);

                    assertAllTrue([
                        res == [1, 2, 3, 4, 5],
                        Buffer.toArray(debugRes) == [
                            "This value [ 2 ] is even.",
                            "This value [ 4 ] is even.",
                        ],
                    ]);
                },
            ),
            it(
                "interleave",
                do {
                    let vals = [1, 2, 3, 4].vals();
                    let vals2 = [10, 20].vals();

                    let iter = Itertools.interleave(vals, vals2);
                    let res = Iter.toArray(iter);

                    assertTrue(res == [1, 10, 2, 20]);
                },
            ),
            it(
                "interleaveLongest",
                do {
                    let vals = [1, 2, 3, 4].vals();
                    let vals2 = [10, 20].vals();

                    let iter = Itertools.interleaveLongest(vals, vals2);
                    let res = Iter.toArray(iter);

                    assertTrue(res == [1, 10, 2, 20, 3, 4]);
                },
            ),
            it(
                "intersperse",
                do {
                    let vals = [1, 2, 3].vals();
                    let iter = Itertools.intersperse(vals, 10);

                    assertTrue(
                        Iter.toArray(iter) == [1, 10, 2, 10, 3],
                    );
                },
            ),
            it(
                "isSorted",
                do {
                    let a = [1, 2, 3, 4];
                    let b = [1, 4, 2, 3];
                    let c = [4, 3, 2, 1];

                    assertAllTrue([
                        Itertools.isSorted(a.vals(), Nat.compare),
                        not Itertools.isSorted(b.vals(), Nat.compare),
                        not Itertools.isSorted(c.vals(), Nat.compare),
                    ]);
                },
            ),
            it(
                "isSortedDesc",
                do {
                    let a = [1, 2, 3, 4];
                    let b = [1, 4, 2, 3];
                    let c = [4, 3, 2, 1];

                    assertAllTrue([
                        not Itertools.isSortedDesc(a.vals(), Nat.compare),
                        not Itertools.isSortedDesc(b.vals(), Nat.compare),
                        Itertools.isSortedDesc(c.vals(), Nat.compare),
                    ]);
                },
            ),
            it(
                "mapEntries",
                do {
                    let vals = [2, 2, 2, 2, 2].vals();

                    let mulWithIndex = func(i : Nat, val : Nat) : Nat {
                        i * val;
                    };

                    let iter = Itertools.mapEntries(vals, mulWithIndex);

                    let res = Iter.toArray(iter);

                    assertTrue(res == [0, 2, 4, 6, 8]);
                },
            ),
            it(
                "mapFilter",
                do {
                    let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();

                    let filterOddSquareEven = func(x : Nat) : ?Nat {
                        if (x % 2 == 1) {
                            null;
                        } else {
                            ?(x * x);
                        };
                    };

                    let it = Itertools.mapFilter<Nat, Nat>(vals, filterOddSquareEven);

                    assertAllTrue([
                        it.next() == ?4,
                        it.next() == ?16,
                        it.next() == ?36,
                        it.next() == ?64,
                        it.next() == ?100,
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "mapReduce",
                do {
                    let vals = [13, 15, 20, 15, 11, 15].vals();

                    let natToChar = func(x : Nat) : Text {
                        Char.toText(
                            Char.fromNat32(
                                Nat32.fromNat(x) + 96,
                            ),
                        );
                    };

                    let concat = func(a : Text, b : Text) : Text {
                        a # b;
                    };

                    let res = Itertools.mapReduce(vals, natToChar, concat);

                    assertTrue(res == ?"motoko");
                },
            ),

            it(
                "mapWhile",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();

                    let squareIntLessThan4 = func(x : Int) : ?Int {
                        if (x < 4) {
                            return ?(x * x);
                        } else {
                            return null;
                        };
                    };

                    let it = Itertools.mapWhile(vals, squareIntLessThan4);

                    assertAllTrue([
                        it.next() == ?1,
                        it.next() == ?4,
                        it.next() == ?9,
                        it.next() == null,
                        it.next() == null,
                    ]);
                },
            ),
            describe(
                "max",
                [
                    it(
                        "find max",
                        do {
                            let vals = [1, 2, 3, 4, 5].vals();
                            let max = Itertools.max<Nat>(vals, Nat.compare);

                            assertTrue(max == ?5);
                        },
                    ),
                    it(
                        "empty iter return null",
                        do {
                            let vals = [].vals();
                            let max = Itertools.max(vals, Nat.compare);

                            assertTrue(max == null);
                        },
                    ),
                ],
            ),
            describe(
                "min",
                [
                    it(
                        "find min",
                        do {
                            let vals = [8, 4, 6, 9].vals();
                            let min = Itertools.min(vals, Nat.compare);

                            assertTrue(min == ?4);
                        },
                    ),
                    it(
                        "empty iter return null",
                        do {
                            let vals = [].vals();
                            let res = Itertools.min(vals, Nat.compare);

                            assertTrue(res == null);
                        },
                    ),
                ],
            ),
            describe(
                "minmax",
                [
                    it(
                        "find min and max",
                        do {
                            let vals = [8, 4, 6, 9].vals();
                            let minmax = Itertools.minmax(vals, Nat.compare);

                            assertTrue(minmax == ?(4, 9));
                        },
                    ),
                    it(
                        "empty iter return null",
                        do {
                            let vals = [].vals();
                            let minmax = Itertools.minmax(vals, Nat.compare);

                            assertTrue(minmax == null);
                        },
                    ),
                    it(
                        "minmax for iter with one element",
                        do {
                            let vals = [8].vals();
                            let minmax = Itertools.minmax(vals, Nat.compare);

                            assertTrue(minmax == ?(8, 8));
                        },
                    ),
                ],
            ),
            describe(
                "merge",
                [
                    it(
                        "two unsorted iters",
                        do {
                            let vals1 = [5, 2, 3].vals();
                            let vals2 = [8, 4, 1].vals();
                            let merged = Itertools.merge(vals1, vals2, Nat.compare);

                            let res = Iter.toArray(merged);

                            assertTrue(
                                res == [5, 2, 3, 8, 4, 1],
                            );
                        },
                    ),
                    it(
                        "two sorted iters",
                        do {
                            let vals1 = [5, 6, 7].vals();
                            let vals2 = [1, 3, 4].vals();
                            let merged = Itertools.merge(vals1, vals2, Nat.compare);

                            let res = Iter.toArray(merged);

                            assertTrue(
                                res == [1, 3, 4, 5, 6, 7],
                            );
                        },
                    ),
                ],
            ),
            describe(
                "kmerge",
                [
                    it(
                        "three unsorted lists",
                        do {
                            let vals1 = [5, 2, 3].vals();
                            let vals2 = [8, 4, 1].vals();
                            let vals3 = [2, 1, 6].vals();

                            let merged = Itertools.kmerge([vals1, vals2, vals3], Nat.compare);
                            let res = Iter.toArray(merged);

                            assertTrue(
                                res == [2, 1, 5, 2, 3, 6, 8, 4, 1],
                            );
                        },
                    ),
                    it(
                        "three sorted lists",
                        do {
                            let vals1 = [1, 4, 8].vals();
                            let vals2 = [2, 7, 9].vals();
                            let vals3 = [3, 5, 6].vals();

                            let merged = Itertools.kmerge([vals1, vals2, vals3], Nat.compare);
                            let res = Iter.toArray(merged);

                            assertTrue(
                                res == [1, 2, 3, 4, 5, 6, 7, 8, 9],
                            );
                        },
                    ),
                    it(
                        "five sorted lists",
                        do {
                            let vals1 = [5, 2, 3].vals();
                            let vals2 = [8, 4, 1].vals();
                            let vals3 = [1, 15, 11].vals();
                            let vals4 = [7, 14, 13].vals();
                            let vals5 = [9, 12, 6].vals();

                            let merged = Itertools.kmerge(
                                [vals1, vals2, vals3, vals4, vals5],
                                Nat.compare,
                            );

                            let res = Iter.toArray(merged);

                            assertTrue(
                                res == [1, 5, 2, 3, 7, 8, 4, 1, 9, 12, 6, 14, 13, 15, 11],
                            )

                        },
                    ),
                ],
            ),

            it(
                "runLength",
                do {
                    let text = "aaaabbbccd";

                    let iter = Itertools.runLength(text.chars(), Char.equal);
                    let res = Iter.toArray(iter);

                    assertTrue(
                        res == [('a', 4), ('b', 3), ('c', 2), ('d', 1)],
                    );
                },
            ),

            describe(
                "notEqual",
                [
                    it(
                        "two equal iters",
                        do {
                            let it1 = Iter.range(1, 5);
                            let it2 = Iter.range(1, 5);

                            assertFalse(
                                Itertools.notEqual(it1, it2, Nat.equal),
                            );
                        },
                    ),

                    it(
                        "two unequal iters ",
                        do {
                            let it1 = Iter.range(1, 5);
                            let it2 = Iter.range(1, 10);

                            assertTrue(
                                Itertools.notEqual(it1, it2, Nat.equal),
                            );
                        },
                    ),
                ],
            ),

            it(
                "nth",
                do {
                    let vals = [0, 1, 2, 3, 4, 5].vals();
                    let nth = Itertools.nth(vals, 3);

                    assertTrue(nth == ?3);
                },
            ),
            it(
                "nthOrDefault (-1)",
                do {
                    let vals = [0, 1, 2, 3, 4, 5].vals();

                    assertAllTrue([
                        Itertools.nthOrDefault(vals, 3, -1) == 3,
                        Itertools.nthOrDefault(vals, 3, -1) == -1,
                    ]);
                },
            ),
            it(
                "pad",
                do {
                    let vals = [1, 2, 3].vals();
                    let padded = Itertools.pad(vals, 6, 0);

                    assertTrue(
                        Iter.toArray(padded) == [1, 2, 3, 0, 0, 0],
                    );
                },
            ),

            it(
                "padWithFn",
                do {
                    let vals = [1, 2, 3].vals();
                    let incrementIndex = func(i : Nat) : Nat { i + 1 };

                    let padded = Itertools.padWithFn(vals, 6, incrementIndex);

                    assertTrue(
                        Iter.toArray(padded) == [1, 2, 3, 4, 5, 6],
                    );
                },
            ),
            it(
                "partition",
                do {
                    let vals = [0, 1, 2, 3, 4, 5].vals();

                    let isEven = func(n : Nat) : Bool { n % 2 == 0 };

                    let (even, odd) = Itertools.partition(vals, isEven);

                    assertAllTrue([
                        even == [0, 2, 4],
                        odd == [1, 3, 5],
                    ]);
                },
            ),

            it(
                "partitionInPlace",
                do {
                    let vals = [0, 1, 2, 3, 4, 5].vals();

                    let isEven = func(n : Nat) : Bool { n % 2 == 0 };

                    let iter = Itertools.partitionInPlace<Nat>(vals, isEven);
                    let res = Iter.toArray(iter);

                    assertTrue(res == [0, 2, 4, 1, 3, 5]);
                },
            ),

            it(
                "isPartitioned",
                do {
                    let vals = [0, 2, 4, 1, 3, 5].vals();

                    let isEven = func(n : Nat) : Bool { n % 2 == 0 };

                    let res = Itertools.isPartitioned(vals, isEven);

                    assertTrue(res == true);
                },
            ),

            it(
                "peekable",
                do {
                    let vals = [1, 2].vals();
                    let peekIter = Itertools.peekable(vals);

                    assertAllTrue([
                        peekIter.peek() == ?1,
                        peekIter.next() == ?1,

                        peekIter.peek() == ?2,
                        peekIter.peek() == ?2,
                        peekIter.next() == ?2,

                        peekIter.peek() == null,
                        peekIter.next() == null,
                    ]);
                },
            ),

            describe(
                "permutations",
                [
                    it(
                        "with 3 vals",
                        do {
                            let vals = [1, 2, 3].vals();
                            let permutations = Itertools.permutations(vals, Nat.compare);
                            let res = Iter.toArray(permutations);

                            assertTrue(
                                res == [
                                    [1, 2, 3],
                                    [1, 3, 2],
                                    [2, 1, 3],
                                    [2, 3, 1],
                                    [3, 1, 2],
                                    [3, 2, 1],
                                ],
                            );
                        },
                    ),

                    it(
                        "with 5 vals",
                        do {
                            let vals = [1, 2, 3, 4, 5].vals();
                            let permutations = Itertools.permutations(vals, Nat.compare);
                            let res = Iter.toArray(permutations);

                            assertTrue(
                                res == [
                                    [1, 2, 3, 4, 5],
                                    [1, 2, 3, 5, 4],
                                    [1, 2, 4, 3, 5],
                                    [1, 2, 4, 5, 3],
                                    [1, 2, 5, 3, 4],
                                    [1, 2, 5, 4, 3],
                                    [1, 3, 2, 4, 5],
                                    [1, 3, 2, 5, 4],
                                    [1, 3, 4, 2, 5],
                                    [1, 3, 4, 5, 2],
                                    [1, 3, 5, 2, 4],
                                    [1, 3, 5, 4, 2],
                                    [1, 4, 2, 3, 5],
                                    [1, 4, 2, 5, 3],
                                    [1, 4, 3, 2, 5],
                                    [1, 4, 3, 5, 2],
                                    [1, 4, 5, 2, 3],
                                    [1, 4, 5, 3, 2],
                                    [1, 5, 2, 3, 4],
                                    [1, 5, 2, 4, 3],
                                    [1, 5, 3, 2, 4],
                                    [1, 5, 3, 4, 2],
                                    [1, 5, 4, 2, 3],
                                    [1, 5, 4, 3, 2],
                                    [2, 1, 3, 4, 5],
                                    [2, 1, 3, 5, 4],
                                    [2, 1, 4, 3, 5],
                                    [2, 1, 4, 5, 3],
                                    [2, 1, 5, 3, 4],
                                    [2, 1, 5, 4, 3],
                                    [2, 3, 1, 4, 5],
                                    [2, 3, 1, 5, 4],
                                    [2, 3, 4, 1, 5],
                                    [2, 3, 4, 5, 1],
                                    [2, 3, 5, 1, 4],
                                    [2, 3, 5, 4, 1],
                                    [2, 4, 1, 3, 5],
                                    [2, 4, 1, 5, 3],
                                    [2, 4, 3, 1, 5],
                                    [2, 4, 3, 5, 1],
                                    [2, 4, 5, 1, 3],
                                    [2, 4, 5, 3, 1],
                                    [2, 5, 1, 3, 4],
                                    [2, 5, 1, 4, 3],
                                    [2, 5, 3, 1, 4],
                                    [2, 5, 3, 4, 1],
                                    [2, 5, 4, 1, 3],
                                    [2, 5, 4, 3, 1],
                                    [3, 1, 2, 4, 5],
                                    [3, 1, 2, 5, 4],
                                    [3, 1, 4, 2, 5],
                                    [3, 1, 4, 5, 2],
                                    [3, 1, 5, 2, 4],
                                    [3, 1, 5, 4, 2],
                                    [3, 2, 1, 4, 5],
                                    [3, 2, 1, 5, 4],
                                    [3, 2, 4, 1, 5],
                                    [3, 2, 4, 5, 1],
                                    [3, 2, 5, 1, 4],
                                    [3, 2, 5, 4, 1],
                                    [3, 4, 1, 2, 5],
                                    [3, 4, 1, 5, 2],
                                    [3, 4, 2, 1, 5],
                                    [3, 4, 2, 5, 1],
                                    [3, 4, 5, 1, 2],
                                    [3, 4, 5, 2, 1],
                                    [3, 5, 1, 2, 4],
                                    [3, 5, 1, 4, 2],
                                    [3, 5, 2, 1, 4],
                                    [3, 5, 2, 4, 1],
                                    [3, 5, 4, 1, 2],
                                    [3, 5, 4, 2, 1],
                                    [4, 1, 2, 3, 5],
                                    [4, 1, 2, 5, 3],
                                    [4, 1, 3, 2, 5],
                                    [4, 1, 3, 5, 2],
                                    [4, 1, 5, 2, 3],
                                    [4, 1, 5, 3, 2],
                                    [4, 2, 1, 3, 5],
                                    [4, 2, 1, 5, 3],
                                    [4, 2, 3, 1, 5],
                                    [4, 2, 3, 5, 1],
                                    [4, 2, 5, 1, 3],
                                    [4, 2, 5, 3, 1],
                                    [4, 3, 1, 2, 5],
                                    [4, 3, 1, 5, 2],
                                    [4, 3, 2, 1, 5],
                                    [4, 3, 2, 5, 1],
                                    [4, 3, 5, 1, 2],
                                    [4, 3, 5, 2, 1],
                                    [4, 5, 1, 2, 3],
                                    [4, 5, 1, 3, 2],
                                    [4, 5, 2, 1, 3],
                                    [4, 5, 2, 3, 1],
                                    [4, 5, 3, 1, 2],
                                    [4, 5, 3, 2, 1],
                                    [5, 1, 2, 3, 4],
                                    [5, 1, 2, 4, 3],
                                    [5, 1, 3, 2, 4],
                                    [5, 1, 3, 4, 2],
                                    [5, 1, 4, 2, 3],
                                    [5, 1, 4, 3, 2],
                                    [5, 2, 1, 3, 4],
                                    [5, 2, 1, 4, 3],
                                    [5, 2, 3, 1, 4],
                                    [5, 2, 3, 4, 1],
                                    [5, 2, 4, 1, 3],
                                    [5, 2, 4, 3, 1],
                                    [5, 3, 1, 2, 4],
                                    [5, 3, 1, 4, 2],
                                    [5, 3, 2, 1, 4],
                                    [5, 3, 2, 4, 1],
                                    [5, 3, 4, 1, 2],
                                    [5, 3, 4, 2, 1],
                                    [5, 4, 1, 2, 3],
                                    [5, 4, 1, 3, 2],
                                    [5, 4, 2, 1, 3],
                                    [5, 4, 2, 3, 1],
                                    [5, 4, 3, 1, 2],
                                    [5, 4, 3, 2, 1],
                                ],
                            );
                        },
                    ),
                ],
            ),
            it(
                "prepend",
                do {
                    let vals = [2, 3].vals();
                    let it1 = Itertools.prepend(1, vals);
                    let it2 = Itertools.prepend(0, it1);

                    assertTrue(
                        Iter.toArray(it2) == [0, 1, 2, 3],
                    );
                },
            ),
            it(
                "product",
                do {
                    let vals = [1, 2, 3, 4].vals();
                    let product = Itertools.product(vals, Nat.mul);

                    assertTrue(product == ?24);
                },
            ),
            it(
                "range",
                do {
                    let iter = DoubleEndedIter.range(0, 5);

                    assertAllTrue([
                        iter.next() == ?0,
                        iter.next() == ?1,
                        iter.next() == ?2,
                        iter.next() == ?3,
                        iter.next() == ?4,
                        iter.next() == null,
                    ]);
                },
            ),
            it(
                "intRange",
                do {
                    let iter = DoubleEndedIter.intRange(0, 5);

                    assertAllTrue([
                        iter.next() == ?0,
                        iter.next() == ?1,
                        iter.next() == ?2,
                        iter.next() == ?3,
                        iter.next() == ?4,
                        iter.next() == null,
                    ]);
                },
            ),
            it(
                "reduce",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let add = func(a : Int, b : Int) : Int { a + b };

                    let sum = Itertools.reduce(vals, add);

                    assertTrue(sum == ?15);
                },
            ),
            it(
                "repeat",
                do {
                    let iter = Itertools.repeat(1, 3);

                    assertAllTrue([
                        iter.next() == ?1,
                        iter.next() == ?1,
                        iter.next() == ?1,
                        iter.next() == null,
                    ]);
                },
            ),
            it(
                "skip",
                do {
                    let iter = [1, 2, 3, 4, 5].vals();
                    let skippedIter = Itertools.skip(iter, 3);

                    assertAllTrue([
                        skippedIter.next() == ?4,
                        skippedIter.next() == ?5,
                        skippedIter.next() == null,
                    ]);
                },
            ),
            it(
                "skipWhile",
                do {
                    let iter = [1, 2, 3, 4, 5].vals();
                    let lessThan3 = func(a : Int) : Bool { a < 3 };

                    let skippedIter = Itertools.skipWhile(iter, lessThan3);

                    let res = Iter.toArray(skippedIter);
                    assertTrue(
                        res == [3, 4, 5],
                    );
                },
            ),
            it(
                "slidingTuples",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let it = Itertools.slidingTuples(vals);

                    assertAllTrue([
                        it.next() == ?(1, 2),
                        it.next() == ?(2, 3),
                        it.next() == ?(3, 4),
                        it.next() == ?(4, 5),
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "slidingTriples",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let triples = Itertools.slidingTriples(vals);

                    assertAllTrue([
                        triples.next() == ?(1, 2, 3),
                        triples.next() == ?(2, 3, 4),
                        triples.next() == ?(3, 4, 5),
                        triples.next() == null,
                    ])

                },
            ),
            it(
                "sort",
                do {
                    let chars = "daecb".chars();
                    let sorted = Itertools.sort(chars, Char.compare);

                    let res = Text.join("", Iter.map(sorted, Char.toText));

                    assertTrue(res == "abcde");
                },
            ),
            it(
                "splitAt",
                do {
                    let iter = [1, 2, 3, 4, 5].vals();
                    let (leftIter, rightIter) = Itertools.splitAt(iter, 3);

                    let (left, right) = (
                        Iter.toArray(leftIter),
                        Iter.toArray(rightIter),
                    );

                    assertAllTrue([
                        left == [1, 2, 3],
                        right == [4, 5],
                    ]);
                },
            ),
            it(
                "spy",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let (copy, fullIter) = Itertools.spy(vals, 3);

                    assertAllTrue([
                        copy.next() == ?1,
                        copy.next() == ?2,
                        copy.next() == ?3,
                        copy.next() == null,

                        fullIter.next() == ?1,
                        fullIter.next() == ?2,
                        fullIter.next() == ?3,
                        fullIter.next() == ?4,
                        fullIter.next() == ?5,
                        fullIter.next() == null,
                    ])

                },
            ),
            it(
                "stepBy",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let iter = Itertools.stepBy(vals, 2);

                    assertAllTrue([
                        iter.next() == ?1,
                        iter.next() == ?3,
                        iter.next() == ?5,
                        iter.next() == null,
                    ]);
                },
            ),
            it(
                "successor",
                do {
                    let optionSquaresOfSquares = func(n : Nat) : ?Nat {
                        let square = n * n;

                        if (square <= Nat.pow(2, 64)) {
                            return ?square;
                        };

                        return null;
                    };

                    let succIter = Itertools.successor(2, optionSquaresOfSquares);
                    let res = Iter.toArray(succIter);

                    assertTrue(
                        res == [
                            2,
                            4,
                            16,
                            256,
                            65_536,
                            4_294_967_296,
                        ],
                    );
                },
            ),
            it(
                "sum",
                do {
                    let vals = [1, 2, 3, 4].vals();
                    let sum = Itertools.sum(vals, Nat.add);

                    assertTrue(sum == ?10);
                },
            ),
            it(
                "take",
                do {
                    let iter = Iter.fromArray([1, 2, 3, 4, 5]);
                    let it = Itertools.take(iter, 3);

                    assertAllTrue([
                        it.next() == ?1,
                        it.next() == ?2,
                        it.next() == ?3,
                        it.next() == null,

                        iter.next() == ?4,
                        iter.next() == ?5,
                        iter.next() == null,
                    ]);
                },
            ),
            it(
                "takeWhile",
                do {
                    let iter = [1, 2, 3, 4, 5].vals();
                    let lessThan3 = func(x : Nat) : Bool { x < 3 };
                    let it = Itertools.takeWhile(iter, lessThan3);

                    assertAllTrue([
                        it.next() == ?1,
                        it.next() == ?2,
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "tuples",
                do {
                    let vals = [1, 2, 3, 4, 5].vals();
                    let it = Itertools.tuples(vals);

                    assertAllTrue([
                        it.next() == ?(1, 2),
                        it.next() == ?(3, 4),
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "triples",
                do {
                    let vals = [1, 2, 3, 4, 5, 6, 7].vals();
                    let it = Itertools.triples(vals);

                    assertAllTrue([
                        it.next() == ?(1, 2, 3),
                        it.next() == ?(4, 5, 6),
                        it.next() == null,
                    ]);
                },
            ),
            it(
                "tee",
                do {
                    let iter = [1, 2, 3].vals();
                    let (iter1, iter2) = Itertools.tee(iter);

                    assertAllTrue([
                        iter1.next() == ?1,
                        iter1.next() == ?2,
                        iter1.next() == ?3,
                        iter1.next() == null,

                        iter2.next() == ?1,
                        iter2.next() == ?2,
                        iter2.next() == ?3,
                        iter2.next() == null,
                    ]);
                },
            ),

            it(
                "unique",
                do {
                    let vals = [1, 1, 2, 2, 3, 3].vals();
                    let it = Itertools.unique<Nat>(vals, Hash.hash, Nat.equal);

                    let res = Iter.toArray(it);

                    assertTrue(res == [1, 2, 3]);
                },
            ),

            it(
                "uniqueCheck",
                do {
                    let vals = [1, 1, 2, 2, 3, 3].vals();
                    let iter = Itertools.uniqueCheck(vals, Hash.hash, Nat.equal);

                    let res = Iter.toArray(iter);

                    assertTrue(
                        res == [
                            (1, true),
                            (1, false),
                            (2, true),
                            (2, false),
                            (3, true),
                            (3, false),
                        ],
                    );
                },
            ),

            describe(
                "isUnique",
                [
                    it(
                        "duplicate values ",
                        do {
                            let vals = [1, 1, 2, 2, 3, 3].vals();

                            assertTrue(not Itertools.isUnique(vals, Hash.hash, Nat.equal));
                        },
                    ),

                    it(
                        "unique values",
                        do {
                            let vals = [1, 2, 3].vals();

                            assertTrue(Itertools.isUnique(vals, Hash.hash, Nat.equal));
                        },
                    ),
                ],
            ),

            it(
                "unzip",
                do {
                    let iter = [(1, 'a'), (2, 'b'), (3, 'c')].vals();
                    let (arr1, arr2) = Itertools.unzip(iter);

                    assertAllTrue([
                        arr1 == [1, 2, 3],
                        arr2 == ['a', 'b', 'c'],
                    ]);
                },
            ),

            it(
                "zip",
                do {
                    let iter1 = [1, 2, 3, 4, 5].vals();
                    let iter2 = "abc".chars();
                    let zipped = Itertools.zip(iter1, iter2);

                    assertAllTrue([
                        zipped.next() == ?(1, 'a'),
                        zipped.next() == ?(2, 'b'),
                        zipped.next() == ?(3, 'c'),
                        zipped.next() == null,
                    ]);
                },
            ),

            it(
                "zip3",
                do {
                    let iter1 = [1, 2, 3, 4, 5].vals();
                    let iter2 = "abc".chars();
                    let iter3 = [1.35, 2.92, 3.74, 4.12, 5.93].vals();

                    let zipped = Itertools.zip3(iter1, iter2, iter3);

                    assertAllTrue([
                        zipped.next() == ?(1, 'a', 1.35),
                        zipped.next() == ?(2, 'b', 2.92),
                        zipped.next() == ?(3, 'c', 3.74),
                        zipped.next() == null,
                    ]);
                },
            ),

            describe(
                "zipLongest",
                [
                    it(
                        "left iter is longest",
                        do {
                            let iter1 = [1, 2, 3, 4, 5].vals();
                            let iter2 = "abc".chars();
                            let zipped = Itertools.zipLongest(iter1, iter2);

                            let res = Iter.toArray(zipped);

                            assertTrue(
                                res == [
                                    #both(1, 'a'),
                                    #both(2, 'b'),
                                    #both(3, 'c'),
                                    #left(4),
                                    #left(5),
                                ],
                            );
                        },
                    ),

                    it(
                        "right iter is longest",
                        do {
                            let iter1 = [1, 2, 3].vals();
                            let iter2 = "abcde".chars();
                            let zipped = Itertools.zipLongest(iter1, iter2);

                            let res = Iter.toArray(zipped);

                            assertTrue(
                                res == [
                                    #both(1, 'a'),
                                    #both(2, 'b'),
                                    #both(3, 'c'),
                                    #right('d'),
                                    #right('e'),
                                ],
                            );
                        },
                    ),
                ],
            ),

            it(
                "fromArraySlice",
                do {
                    let arr = [1, 2, 3, 4, 5];
                    let slicedIter = Itertools.fromArraySlice(arr, 2, arr.size());

                    assertTrue(
                        Iter.toArray(slicedIter) == [3, 4, 5],
                    );
                },
            ),
            it(
                "toBuffer",
                do {
                    let chars = "abc".chars();
                    let buffer = Itertools.toBuffer<Char>(chars);

                    assertTrue(Buffer.toArray(buffer) == ['a', 'b', 'c']);
                },
            ),

            it(
                "toDeque",
                do {
                    let chars = "abc".chars();
                    let deque = Itertools.toDeque<Char>(chars);

                    assertTrue(DequeUtils.toArray(deque) == ['a', 'b', 'c']);
                },
            ),

            it(
                "toText",
                do {
                    let chars = "abc".chars();
                    let text = Itertools.toText(chars);

                    assertTrue(text == "abc");
                },
            ),

            it(
                "toTrieSet",
                do {
                    let chars = "abbcacd".chars();
                    let trieSet = Itertools.toTrieSet<Char>(chars, Char.toNat32, Char.equal);
                    let setIter = Iter.map(
                        Trie.iter<Char, ()>(trieSet),
                        func((c, _) : (Char, ())) : Char { c },
                    );

                    assertTrue(Iter.toArray(setIter) == ['a', 'b', 'c', 'd']);
                },
            ),

            it(
                "fromTrieSet",
                do {
                    let set = Itertools.toTrieSet([1, 1, 3, 2, 3, 4].vals(), Hash.hash, Nat.equal);
                    let iter = Itertools.fromTrieSet(set);

                    assertTrue(Iter.toArray(iter) == [1, 3, 2, 4]);
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
