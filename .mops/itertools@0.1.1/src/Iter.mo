/// Main module with utility functions for working efficiently with iterators.
///
/// See the [`Iter`](https://internetcomputer.org/docs/current/references/motoko-ref/iter#iter-1) module from the base lib for more information on the `Iter` type.
///
///
/// ## Getting started
///
/// To get started, you'll need to import the `Iter` module from both the base library and this one.
///
/// ```motoko
///     import Iter "mo:base/Iter";
///     import Itertools "mo:itertools/Iter";
/// ```
///
/// Converting data types to iterators is the next step.
/// - Array
///     - `[1, 2, 3, 4, 5].vals()`
///     - `Iter.fromArray([1, 2, 3, 4, 5])`
///
/// - List
///     - `Iter.fromList(list)`
///
/// - Text
///     - `"Hello, world!".chars()`
///     - `Text.split("a,b,c", #char ',')`
///
/// - Buffer
///   - `Buffer.toArray(buffer).vals()`
///
/// - [HashMap](https://internetcomputer.org/docs/current/references/motoko-ref/hashmap#hashmap-1)
///        - `map.entries()`
///
/// For conversion of other data types to iterators, you can look in the [base library](https://internetcomputer.org/docs/current/references/motoko-ref/array) for the specific data type's documentation.
///
///
/// Here are some examples of using the functions in this library to create simple and
/// efficient iterators for solving different problems:
///
/// - An example, using `range` and `sum` to find the sum of values from 1 to 25:
///
/// ```motoko
///     let range = Itertools.range(1, 25 + 1);
///     let sum = Itertools.sum(range, Nat.add);
///
///     assert sum == ?325;
/// ```
///
///
/// - An example, using multiple functions to retrieve the indices of all even numbers in an array:
///
/// ```motoko
///     let vals = [1, 2, 3, 4, 5, 6].vals();
///     let iterWithIndices = Itertools.enumerate(vals);
///
///     let isEven = func ( x : (Int, Int)) : Bool { x.1 % 2 == 0 };
///     let mapIndex = func (x : (Int, Int)) : Int { x.0 };
///     let evenIndices = Itertools.mapFilter(iterWithIndices, isEven, mapIndex);
///
///     assert Iter.toArray(evenIndices) == [1, 3, 5];
/// ```
///
///
/// - An example to find the difference between consecutive elements in an array:
///
/// ```motoko
///     let vals = [5, 3, 3, 7, 8, 10].vals();
///
///     let tuples = Itertools.slidingTuples(vals);
///     // Iter.toArray(tuples) == [(5, 3), (3, 3), (3, 7), (7, 8), (8, 10)]
///
///     let diff = func (x : (Int, Int)) : Int { x.1 - x.0 };
///     let iter = Iter.map(tuples, diff);
///
///     assert Iter.toArray(iter) == [-2, 0, 4, 1, 2];
/// ```

import Order "mo:base/Order";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import Func "mo:base/Func";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Heap "mo:base/Heap";
import TrieMap "mo:base/TrieMap";
import Stack "mo:base/Stack";
import List "mo:base/List";
import Deque "mo:base/Deque";
import Prelude "mo:base/Prelude";

import PeekableIter "PeekableIter";
import Deiter "Deiter";

import ArrayMut_Utils "Utils/ArrayMut";
import Nat_Utils "Utils/Nat";
import TrieMap_Utils "Utils/TrieMap";

module {

    /// Returns a reference to a modified iterator that returns the accumulated values based on the given predicate.
    ///
    /// ### Example
    /// - An example calculating the running sum of a iterator:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let it = Itertools.accumulate(vals, func(a, b) { a + b });
    ///
    ///     assert it.next() == ?1;
    ///     assert it.next() == ?3;
    ///     assert it.next() == ?6;
    ///     assert it.next() == ?10;
    ///     assert it.next() == ?null;
    /// ```

    public func accumulate<A>(iter : Iter.Iter<A>, predicate : (A, A) -> A) : Iter.Iter<A> {
        var acc = iter.next();

        return object {
            public func next() : ?A {
                switch (acc, iter.next()) {
                    case (?_acc, ?n) {
                        let tmp = acc;
                        acc := ?predicate(_acc, n);
                        return tmp;
                    };
                    case (?_acc, null) {
                        acc := null;
                        return ?_acc;
                    };
                    case (_, _) {
                        return null;
                    };
                };
            };
        };
    };

    /// Checks if all elements in the iterable satisfy the predicate.
    ///
    /// ### Example
    /// - An example checking if all elements in a iterator of integers are even:
    ///
    /// ```motoko
    ///
    ///     let a = [1, 2, 3, 4].vals();
    ///     let b = [2, 4, 6, 8].vals();
    ///
    ///     let isEven = func(a: Int): Bool { a % 2 == 0 };
    ///
    ///     assert Itertools.all(a, isEven) == false;
    ///     assert Itertools.all(b, isEven) == true;
    /// ```
    public func all<A>(iter : Iter.Iter<A>, predicate : (A) -> Bool) : Bool {
        for (item in iter) {
            if (not predicate(item)) {
                return false;
            };
        };
        return true;
    };

    /// Checks if at least one element in the iterator satisfies the predicate.
    ///
    /// ### Example
    /// - An example checking if any element in a iterator of integers is even:
    ///
    /// ```motoko
    ///
    ///     let a = [1, 2, 3, 4].vals();
    ///     let b = [1, 3, 5, 7].vals();
    ///
    ///     let isEven = func(a: Nat) : Bool { a % 2 == 0 };
    ///
    ///     assert Itertools.any(a, isEven) == true;
    ///     assert Itertools.any(b, isEven) == false;
    /// ```
    public func any<A>(iter : Iter.Iter<A>, predicate : (A) -> Bool) : Bool {
        for (item in iter) {
            if (predicate(item)) {
                return true;
            };
        };
        return false;
    };

    /// Adds an element to the end of an iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let iter = [1, 2, 3, 4].vals();
    ///     let new_iter = Itertools.add(iter, 5);
    ///
    ///     assert Iter.toArray(new_iter) == [1, 2, 3, 4, 5]
    ///
    public func add<A>(iter : Iter.Iter<A>, elem : A) : Iter.Iter<A> {
        var popped = false;

        object {
            public func next() : ?A {
                switch (iter.next()) {
                    case (?val) {
                        ?val;
                    };
                    case (_) {
                        if (popped) {
                            null;
                        } else {
                            popped := true;
                            ?elem;
                        };
                    };
                };
            };
        };
    };

    /// Returns the cartesian product of the given iterables as an iterator of tuples.
    ///
    /// The resulting iterator contains all the combinations between elements in the two given iterators.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let a = [1, 2, 3].vals();
    ///     let b = "abc".chars();
    ///
    ///     let it = Itertools.cartesianProduct(a, b);
    ///
    ///     assert Iter.toArray(it) == [
    ///         (1, 'a'), (1, 'b'), (1, 'c'),
    ///         (2, 'a'), (2, 'b'), (2, 'c'),
    ///         (3, 'a'), (3, 'b'), (3, 'c')
    ///     ];
    ///
    /// ```
    public func cartesianProduct<A, B>(iterA : Iter.Iter<A>, iterB : Iter.Iter<B>) : Iter.Iter<(A, B)> {
        var optionA = iterA.next();

        let buffer = Buffer.Buffer<B>(8);
        var i = 0;

        return object {
            public func next() : ?(A, B) {
                switch (optionA, iterB.next()) {
                    case (?a, ?b) {
                        buffer.add(b);
                        return ?(a, b);
                    };
                    case (?a, _) {
                        if (i == buffer.size() or i == 0) {
                            switch (iterA.next()) {
                                case (?a) {
                                    i := 1;
                                    optionA := ?a;
                                    return ?(a, buffer.get(0));
                                };
                                case (null) {
                                    return null;
                                };
                            };
                        } else {
                            let tmp = buffer.get(i);
                            i += 1;
                            ?(a, tmp);
                        };
                    };
                    case (_) {
                        return null;
                    };
                };
            };
        };
    };

    /// Counts the frequency of an element in the iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let a = [1, 2, 3, 1, 2, 3].vals();
    ///
    ///     let freq = Itertools.count(a, 1, Nat.equal);
    ///
    ///     assert freq == 2;
    /// ```
    public func count<A>(iter : Iter.Iter<A>, element : A, isEq : (A, A) -> Bool) : Nat {
        var count = 0;

        for (item in iter) {
            if (isEq(element, item)) {
                count += 1;
            };
        };

        count;
    };

    /// Returns a TrieMap where the elements in the iterator are stored
    /// as keys and the frequency of the elements are values
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let a = "motoko".chars();
    ///
    ///     let freqMap = Itertools.countAll(a, Char.hash, Char.equal);
    ///     let res = Iter.toArray(freqMap.entries());
    ///
    ///     assert res == [('k', 1), ('m', 1), ('o', 3), ('t', 1)];
    /// ```
    public func countAll<A>(iter : Iter.Iter<A>, hashFn : (A) -> Hash.Hash, isEq : (A, A) -> Bool) : TrieMap.TrieMap<A, Nat> {
        var map = TrieMap.TrieMap<A, Nat>(isEq, hashFn);

        func increment(n : Nat) : Nat {
            n + 1;
        };

        for (item in iter) {
            TrieMap_Utils.putOrUpdate(map, item, 1, increment);
        };

        map;
    };

    /// Chains two iterators of the same type together, so that all the
    /// elements in the first iterator come before the second one.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///    let iter1 = [1, 2].vals();
    ///    let iter2 = [3, 4].vals();
    ///    let chained = Itertools.chain(iter1, iter2);
    ///
    ///     assert chained.next() == ?1
    ///     assert chained.next() == ?2
    ///     assert chained.next() == ?3
    ///     assert chained.next() == ?4
    ///     assert chained.next() == null
    /// ```
    public func chain<A>(a : Iter.Iter<A>, b : Iter.Iter<A>) : Iter.Iter<A> {
        return object {
            public func next() : ?A {
                switch (a.next()) {
                    case (?x) {
                        ?x;
                    };
                    case (null) {
                        b.next();
                    };
                };
            };
        };
    };

    /// Returns an iterator that accumulates elements into arrays with a size less that or equal to the given `size`.
    ///
    /// ### Example
    /// - An example grouping a iterator of integers into arrays of size `3`:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();
    ///     let it = Itertools.chunks(vals, 3);
    ///
    ///     assert it.next() == ?[1, 2, 3];
    ///     assert it.next() == ?[4, 5, 6];
    ///     assert it.next() == ?[7, 8, 9];
    ///     assert it.next() == ?[10];
    ///     assert it.next() == null;
    /// ```
    public func chunks<A>(iter : Iter.Iter<A>, size : Nat) : Iter.Iter<[A]> {
        assert size > 0;
        var buf = Buffer.Buffer<A>(size);

        object {
            public func next() : ?[A] {
                var i = 0;

                label l while (i < size) {
                    switch (iter.next()) {
                        case (?val) {
                            buf.add(val);
                            i := i + 1;
                        };
                        case (_) {
                            break l;
                        };
                    };
                };

                if (buf.size() == 0) {
                    null;
                } else {
                    let tmp = ?Buffer.toArray(buf);
                    buf.clear();
                    tmp;
                };
            };
        };
    };

    /// Returns an iterator that accumulates elements into arrays with sizes exactly equal to the given one.
    /// If the iterator is shorter than `n` elements, `null` is returned.
    ///
    /// ### Example
    /// - An example grouping a iterator of integers into arrays of size `3`:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();
    ///     let it = Itertools.chunksExact(vals, 3);
    ///
    ///     assert it.next() == ?[1, 2, 3];
    ///     assert it.next() == ?[4, 5, 6];
    ///     assert it.next() == ?[7, 8, 9];
    ///     assert it.next() == null;
    /// ```
    public func chunksExact<A>(iter : Iter.Iter<A>, size : Nat) : Iter.Iter<[A]> {
        assert size > 0;

        let chunksIter = chunks(iter, size);

        object {
            public func next() : ?[A] {
                switch (chunksIter.next()) {
                    case (?chunk) {
                        if (chunk.size() == size) {
                            ?chunk;
                        } else {
                            null;
                        };
                    };
                    case (null) {
                        null;
                    };
                };
            };
        };
    };

    /// Returns all the combinations of a given iterator.
    ///
    /// ### Example
    /// - An example grouping a iterator of integers into arrays of size `3`:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let it = Itertools.combinations(vals, 3);
    ///
    ///     assert it.next() == ?[1, 2, 3];
    ///     assert it.next() == ?[1, 2, 4];
    ///     assert it.next() == ?[1, 3, 4];
    ///     assert it.next() == ?[2, 3, 4];
    ///     assert it.next() == null;
    /// ```
    ///
    /// - An example grouping a iterator of integers into arrays of size `2`:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let it = Itertools.combinations(vals, 2);
    ///
    ///     assert it.next() == ?[1, 2];
    ///     assert it.next() == ?[1, 3];
    ///     assert it.next() == ?[1, 4];
    ///     assert it.next() == ?[2, 3];
    ///     assert it.next() == ?[2, 4];
    ///     assert it.next() == ?[3, 4];
    ///     assert it.next() == null;
    /// ```
    public func combinations(iter : Iter.Iter<Nat>, size : Nat) : Iter.Iter<[Nat]> {
        assert size > 0;

        let buffer = Buffer.Buffer<Nat>(8);
        let cbns = Buffer.Buffer<Nat>(size);

        let indices = Buffer.Buffer<Nat>(size);
        for (i in range(0, size)) {
            indices.add(i);
        };

        var bufferIsFilled = false;

        object {
            public func next() : ?[Nat] {
                // fill buffer incrementally
                if (not bufferIsFilled) {
                    switch (iter.next()) {
                        case (?n) {
                            buffer.add(n);
                        };
                        case (_) {
                            bufferIsFilled := true;
                        };
                    };
                };

                // recursively build combinations
                if (indices.size() == 0) {
                    null;
                } else if (cbns.size() == size) {
                    let res = Buffer.toArray(cbns);
                    ignore cbns.removeLast();
                    ?res;
                } else {
                    if (indices.size() > cbns.size()) {
                        let i = indices.get(cbns.size());

                        if (i >= buffer.size()) {
                            if (cbns.size() == 0) {
                                null;
                            } else {

                                ignore indices.removeLast();

                                if (indices.size() == 0) {
                                    return null;
                                };

                                ignore cbns.removeLast();
                                next();
                            };
                        } else {
                            indices.put(cbns.size(), i + 1);
                            cbns.add(buffer.get(i));

                            next();
                        };
                    } else {
                        indices.add(
                            indices.get(indices.size() - 1),
                        );
                        next();
                    };
                };
            };
        };
    };

    /// Creates an iterator that loops over the values of a
    /// given iterator `n` times.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let chars = "abc".chars();
    ///     let it = Itertools.cycle(chars, 3);
    ///
    ///     assert it.next() == ?'a';
    ///     assert it.next() == ?'b';
    ///     assert it.next() == ?'c';
    ///
    ///     assert it.next() == ?'a';
    ///     assert it.next() == ?'b';
    ///     assert it.next() == ?'c';
    ///
    ///     assert it.next() == ?'a';
    ///     assert it.next() == ?'b';
    ///     assert it.next() == ?'c';
    ///
    ///     assert it.next() == null;
    /// ```
    public func cycle<A>(iter : Iter.Iter<A>, n : Nat) : Iter.Iter<A> {
        var buf = Buffer.Buffer<A>(1);
        var buf_index = 0;
        var i = 0;

        return object {
            public func next() : ?A {
                if (i == n) {
                    null;
                } else {
                    switch (iter.next()) {
                        case (?x) {
                            buf.add(x);
                            ?x;
                        };
                        case (null) {
                            if (buf.size() == 0) {
                                null;
                            } else {
                                if (buf_index < buf.size()) {
                                    buf_index += 1;
                                    ?buf.get(buf_index - 1);
                                } else {
                                    i += 1;
                                    if (i < n) {
                                        buf_index := 1;
                                        ?buf.get(buf_index - 1);
                                    } else {
                                        null;
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };

    /// Returns an iterator that returns tuples with the index of the element
    /// and the element.
    ///
    /// The index starts at 0 and is the first item in the tuple.
    ///
    /// ```motoko
    ///
    ///     let chars = "abc".chars();
    ///     let iter = Itertools.enumerate(chars);
    ///
    ///     for ((i, c) in iter){
    ///         Debug.print((i, c));
    ///     };
    ///
    ///     // (0, 'a')
    ///     // (1, 'b')
    ///     // (2, 'c')
    /// ```
    public func enumerate<A>(iter : Iter.Iter<A>) : Iter.Iter<(Nat, A)> {
        var i = 0;
        return object {
            public func next() : ?(Nat, A) {
                let nextVal = iter.next();

                switch nextVal {
                    case (?v) {
                        let val = ?(i, v);
                        i += 1;

                        return val;
                    };
                    case (_) null;
                };
            };
        };
    };

    /// Creates an empty iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let it = Itertools.empty();
    ///     assert it.next() == null;
    ///
    /// ```
    public func empty<A>() : Iter.Iter<A> {
        return object {
            public func next() : ?A {
                null;
            };
        };
    };

    /// Checks if two iterators are equal.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let it1 = Itertools.range(1, 10);
    ///     let it2 = Itertools.range(1, 10);
    ///
    ///     assert Itertools.equal(it1, it2, Nat.equal);
    ///
    ///     let it3 = Itertools.range(1, 5);
    ///     let it4 = Itertools.range(1, 10);
    ///
    ///     assert not Itertools.equal(it3, it4, Nat.equal);
    /// ```
    public func equal<A>(iter1 : Iter.Iter<A>, iter2 : Iter.Iter<A>, isEq : (A, A) -> Bool) : Bool {

        switch ((iter1.next(), iter2.next())) {
            case ((?a, ?b)) {
                if (isEq(a, b)) {
                    equal<A>(iter1, iter2, isEq);
                } else {
                    false;
                };
            };
            case ((null, ?b)) false;
            case ((?a, null)) false;
            case ((null, null)) true;
        };

    };

    /// Looks for an element in an iterator that matches a predicate.
    ///
    /// ### Example
    /// - An example finding the first even number in an iterator:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///
    ///     let isEven = func( x : Int ) : Bool {x % 2 == 0};
    ///     let res = Itertools.find(vals, isEven);
    ///
    ///     assert res == ?2
    /// ```
    public func find<A>(iter : Iter.Iter<A>, predicate : (A) -> Bool) : ?A {
        for (val in iter) {
            if (predicate(val)) {
                return ?val;
            };
        };
        return null;
    };

    /// Return the index of an element in an iterator that matches a predicate.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///
    ///     let isEven = func( x : Int ) : Bool {x % 2 == 0};
    ///     let res = Itertools.findIndex(vals, isEven);
    ///
    ///     assert res == ?1;
    /// ```
    public func findIndex<A>(iter : Iter.Iter<A>, predicate : (A) -> Bool) : ?Nat {
        var i = 0;
        for (val in iter) {
            if (predicate(val)) {
                return ?i;
            };
            i += 1;
        };
        return null;
    };

    /// Returns an iterator with the indices of all the elements that match the predicate.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5, 6].vals();
    ///
    ///     let isEven = func( x : Int ) : Bool {x % 2 == 0};
    ///     let res = Itertools.findIndices(vals, isEven);
    ///
    ///     assert Iter.toArray(res) == [1, 3, 5];
    ///
    /// ```
    public func findIndices<A>(iter : Iter.Iter<A>, predicate : (A) -> Bool) : Iter.Iter<Nat> {
        var i = 0;
        return object {
            public func next() : ?Nat {
                for (val in iter) {
                    i += 1;

                    if (predicate(val)) {
                        return ?(i - 1);
                    };

                };

                return null;
            };
        };
    };

    /// Returns the accumulated result of applying of the given
    /// function to each element and the previous result starting with
    /// the initial value.
    ///
    /// This method is similar to [reduce](#reduce) but it takes an initial
    /// value and does not return an optional value.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///     import Nat8 "mo:base/Nat8";
    ///
    ///     let arr : [Nat8] = [1, 2, 3, 4, 5];
    ///     let sumToNat = func(acc: Nat, n: Nat8): Nat {
    ///         acc + Nat8.toNat(n)
    ///     };
    ///
    ///     let sum = Itertools.fold<Nat8, Nat>(
    ///         arr.vals(),
    ///         200,
    ///         sumToNat
    ///     );
    ///
    ///     assertTrue(sum == 215)
    /// ```
    ///
    /// You can easily fold from the right to left using a
    /// [`Deiter`](Deiter.html) to reverse the iterator before folding.

    public func fold<A, B>(iter : Iter.Iter<A>, initial : B, f : (B, A) -> B) : B {
        var res = initial;
        for (val in iter) {
            res := f(res, val);
        };

        return res;
    };

    /// Flattens nested iterators into a single iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let nestedIter = [
    ///         [1].vals(),
    ///         [2, 3].vals(),
    ///         [4, 5, 6].vals()
    ///     ].vals();
    ///
    ///     let flattened = Itertools.flatten(nestedIter);
    ///     assert Iter.toArray(flattened) == [1, 2, 3, 4, 5, 6];
    /// ```

    public func flatten<A>(nestedIter : Iter.Iter<Iter.Iter<A>>) : Iter.Iter<A> {
        var iter : Iter.Iter<A> = switch (nestedIter.next()) {
            case (?_iter) {
                _iter;
            };
            case (_) {
                return empty<A>();
            };
        };

        object {
            public func next() : ?A {
                switch (iter.next()) {
                    case (?val) ?val;
                    case (_) {
                        switch (nestedIter.next()) {
                            case (?_iter) {
                                iter := _iter;
                                iter.next();
                            };
                            case (_) null;
                        };
                    };
                };
            };
        };
    };

    /// Returns an flattened iterator with all the values in a nested array
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let arr = [[1], [2, 3], [4, 5, 6]];
    ///     let flattened = Itertools.flatten(arr);
    ///
    ///     assert Iter.toArray(flattened) == [1, 2, 3, 4, 5, 6];
    /// ```
    public func flattenArray<A>(nestedArray : [[A]]) : Iter.Iter<A> {
        flatten(
            Iter.map(
                nestedArray.vals(),
                func(arr : [A]) : Iter.Iter<A> {
                    arr.vals();
                },
            ),
        );
    };

    /// Groups nearby elements into arrays based on result from the given function and returns them along with the result of elements in that group.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();
    ///
    ///     let isFactorOf30 = func( x : Int ) : Bool {x % 30 == 0};
    ///     let groups = Itertools.groupBy(vals, isFactorOf30);
    ///
    ///     assert Iter.toArray(groups) == [
    ///         ([1, 2, 3], true),
    ///         ([4], false),
    ///         ([5, 6], true),
    ///         ([7, 8, 9], false),
    ///         ([10], true)
    ///     ];
    ///
    /// ```
    public func groupBy<A, B>(iter : Iter.Iter<A>, pred : (A) -> Bool) : Iter.Iter<([A], Bool)> {
        let group = Buffer.Buffer<A>(8);

        func nextGroup() : ?([A], Bool) {
            switch (iter.next()) {
                case (?val) {
                    if (group.size() == 0) {
                        group.add(val);
                        return nextGroup();
                    };

                    if (pred(group.get(0)) == pred(val)) {
                        group.add(val);
                        nextGroup();
                    } else {
                        let arr = Buffer.toArray(group);

                        group.clear();
                        group.add(val);

                        ?(arr, pred(arr[0]));
                    };
                };
                case (_) {
                    if (group.size() == 0) {
                        null;
                    } else {
                        let arr = Buffer.toArray(group);

                        group.clear();

                        ?(arr, pred(arr[0]));
                    };
                };
            };
        };

        return object {
            public func next() : ?([A], Bool) {
                nextGroup();
            };
        };
    };

    /// Pass in a callback function to the iterator that performs a task every time the iterator is advanced.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///     import Debug "mo:base/Debug";
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///
    ///     let printIfEven = func(n: Int) {
    ///         if (n % 2 == 0){
    ///             Debug.print("This value [ " # debug_show n # " ] is even.");
    ///         }
    ///     };
    ///
    ///     let iter = Itertools.inspect(vals, printIfEven);
    ///
    ///     assert Iter.toArray(iter) == [1, 2, 3, 4, 5];
    /// ```
    ///
    /// - console:
    /// ```bash
    ///     This value [ +2 ] is even.
    ///     This value [ +4 ] is even.
    /// ```
    public func inspect<A>(iter : Iter.Iter<A>, callback : (A) -> ()) : Iter.Iter<A> {

        object {
            public func next() : ?A {
                switch (iter.next()) {
                    case (?a) {
                        callback(a);
                        ?a;
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Alternates between two iterators of the same type until one is exhausted.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let vals2 = [10, 20].vals();
    ///
    ///     let iter = Itertools.interleave(vals, vals2);
    ///
    ///     assert iter.next() == ?1
    ///     assert iter.next() == ?10
    ///     assert iter.next() == ?2
    ///     assert iter.next() == ?20
    ///     assert iter.next() == null
    /// ```

    public func interleave<A>(_iter1 : Iter.Iter<A>, _iter2 : Iter.Iter<A>) : Iter.Iter<A> {
        var iter1 = _iter1;
        var iter2 = _iter2;

        return object {
            public func next() : ?A {

                switch (iter1.next(), iter2.next()) {
                    case (?val, ?val2) {

                        let tmp = iter1;
                        iter1 := prepend(val2, iter2);
                        iter2 := tmp;

                        return ?val;
                    };

                    case (_) null;
                };
            };
        };
    };

    /// Alternates between two iterators of the same type until both are exhausted.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let vals2 = [10, 20].vals();
    ///
    ///     let iter = Itertools.interleave(vals, vals2);
    ///
    ///     assert iter.next() == ?1
    ///     assert iter.next() == ?10
    ///     assert iter.next() == ?2
    ///     assert iter.next() == ?20
    ///     assert iter.next() == ?3
    ///     assert iter.next() == ?4
    ///     assert iter.next() == null
    /// ```
    public func interleaveLongest<A>(_iter1 : Iter.Iter<A>, _iter2 : Iter.Iter<A>) : Iter.Iter<A> {
        var iter1 = _iter1;
        var iter2 = _iter2;

        return object {
            public func next() : ?A {

                switch (iter1.next()) {
                    case (?val) {
                        let tmp = iter1;
                        iter1 := iter2;
                        iter2 := tmp;

                        return ?val;
                    };

                    case (_) iter2.next();
                };
            };
        };
    };

    /// Returns an iterator that inserts a value between each pair
    /// of values in an iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3].vals();
    ///     let iter = Itertools.intersperse(vals, 10);
    ///
    ///     assert Iter.toArray(iter) == [1, 10, 2, 10, 3];
    ///
    /// ```
    public func intersperse<A>(_iter : Iter.Iter<A>, val : A) : Iter.Iter<A> {
        let iter = peekable(_iter);
        var even = true;

        return object {
            public func next() : ?A {
                switch (iter.peek()) {
                    case (?item) {
                        if (even) {
                            even := false;
                            return iter.next();
                        } else {
                            even := true;
                            return ?val;
                        };
                    };
                    case (_) null;
                };
            };
        };
    };

    /// Checks if all the elements in an iterator are sorted in ascending order
    /// that for every element `a` ans its proceding element `b`, `a <= b`.
    ///
    /// Returns true if iterator is empty
    ///
    /// #Example
    ///
    /// ```motoko
    /// import Nat "mo:base/Nat";
    ///
    ///     let a = [1, 2, 3, 4];
    ///     let b = [1, 4, 2, 3];
    ///     let c = [4, 3, 2, 1];
    ///
    /// assert Itertools.isSorted(a.vals(), Nat.compare) == true;
    /// assert Itertools.isSorted(b.vals(), Nat.compare) == false;
    /// assert Itertools.isSorted(c.vals(), Nat.compare) == false;
    ///
    /// ```
    public func isSorted<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : Bool {
        var prev = switch (iter.next()) {
            case (?n) { n };
            case (null) return true;
        };

        for (item in iter) {
            if (cmp(prev, item) == #greater) {
                return false;
            };
            prev := item;
        };

        true;
    };

    /// Checks if all the elements in an iterator are sorted in descending order
    ///
    /// Returns true if iterator is empty
    ///
    /// #Example
    ///
    /// ```motoko
    /// import Nat "mo:base/Nat";
    ///
    ///     let a = [1, 2, 3, 4];
    ///     let b = [1, 4, 2, 3];
    ///     let c = [4, 3, 2, 1];
    ///
    /// assert Itertools.isSortedDesc(a.vals(), Nat.compare) == false;
    /// assert Itertools.isSortedDesc(b.vals(), Nat.compare) == false;
    /// assert Itertools.isSortedDesc(c.vals(), Nat.compare) == true;
    ///
    /// ```
    public func isSortedDesc<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : Bool {
        var prev = switch (iter.next()) {
            case (?n) { n };
            case (null) return true;
        };

        for (item in iter) {
            if (cmp(prev, item) == #less) {
                return false;
            };
            prev := item;
        };

        true;
    };

    /// Returns an iterator adaptor that mutates elements of an iterator by applying the given function to each entry.
    /// Each entry consists of the index of the element and the element itself.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [2, 2, 2, 2, 2].vals();
    ///     let mulWithIndex = func(i: Nat, val: Nat) {
    ///         i * val;
    ///     };
    ///
    ///     let iter = Itertools.mapEntries(vals, mulWithIndex);
    ///
    ///     assert Iter.toArray(iter) == [0, 2, 4, 6, 8];
    ///
    /// ```
    public func mapEntries<A, B>(iter : Iter.Iter<A>, f : (Nat, A) -> B) : Iter.Iter<B> {
        let entries = enumerate(iter);

        return object {
            public func next() : ?B {
                switch (entries.next()) {
                    case (?(i, val)) {
                        return ?f(i, val);
                    };
                    case (_) null;
                };
            };
        };
    };

    /// Returns an iterator that filters elements based on a predicate and
    /// maps them to a new value based on the second argument.
    ///
    /// ### Example
    /// - An example filtering odd numbers and squaring them:
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].vals();
    ///
    ///     let filterOddSquareEven = func( x : Nat ) : Nat {
    ///         if (x % 2 == 1){
    ///             null
    ///         }else{
    ///             ?(x * x)
    ///         }
    ///      };
    ///
    ///     let it = Itertools.mapFilter(vals, filterOddSquareEven);
    ///
    ///     assert it.next() == ?4
    ///     assert it.next() == ?16
    ///     assert it.next() == ?36
    ///     assert it.next() == ?64
    ///     assert it.next() == ?100
    ///     assert it.next() == null
    /// ```
    public func mapFilter<A, B>(iter : Iter.Iter<A>, optMapFn : (A) -> ?B) : Iter.Iter<B> {

        func getNext() : ?B {
            switch (iter.next()) {
                case (?val) {
                    switch (optMapFn(val)) {
                        case (?newVal) { ?newVal };
                        case (_) { getNext() };
                    };
                };
                case (_) null;
            };
        };

        object {
            public func next() : ?B {
                getNext();
            };
        };
    };

    /// Maps the elements of an iterator and accumulates them into a single value.
    ///
    /// ### Example
    ///
    /// - decode numeric representation of characters into a string
    /// ```motoko
    ///
    ///     let vals = [13, 15, 20, 15, 11, 15].vals();
    ///
    ///     let natToChar = func (x : Nat) : Text {
    ///         Char.toText(
    ///             Char.fromNat32(
    ///                 Nat32.fromNat(x) + 96
    ///             )
    ///         )
    ///     };
    ///
    ///     let concat = func (a : Text, b : Text) : Text {
    ///         a # b
    ///     };
    ///
    ///     let res = Itertools.mapReduce(vals, natToChar, concat);
    ///
    ///     assert res == ?"motoko";
    ///
    /// ```
    public func mapReduce<A, B>(iter : Iter.Iter<A>, f : (A) -> B, accFn : (B, B) -> B) : ?B {
        reduce(Iter.map<A, B>(iter, f), accFn);
    };

    /// Returns an iterator that maps and yields elements while the
    /// predicate is true.
    /// The predicate is true if it returns an optional value and
    /// false if it
    /// returns null.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///
    ///     let squareIntLessThan4 = func( x : Int ) : ?Int {
    ///         if (x < 4){
    ///             return ?(x * x);
    ///         }else{
    ///             return null;
    ///         };
    ///     };
    ///
    ///     let it = Itertools.mapWhile(vals, squareIntLessThan4);
    ///
    ///     assert it.next() == ?1;
    ///     assert it.next() == ?4;
    ///     assert it.next() == ?9;
    ///     assert it.next() == null;
    ///     assert it.next() == null;
    ///
    /// ```
    public func mapWhile<A, B>(iter : Iter.Iter<A>, pred : (A) -> ?B) : Iter.Iter<B> {
        var ctrl = true;
        return object {
            public func next() : ?B {
                if (ctrl == false) {
                    return null;
                };

                switch (iter.next()) {
                    case (?n) {
                        switch (pred(n)) {
                            case (?v) {
                                ?v;
                            };
                            case (null) {
                                ctrl := false;
                                null;
                            };
                        };
                    };
                    case (_) null;
                };
            };
        };
    };

    /// Returns the maximum value in an iterator.
    /// A null value is returned if the iterator is empty.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let max = Itertools.max(vals, Nat.compare);
    ///
    ///     assert max == ?5;
    /// ```
    ///
    /// - max on an empty iterator
    ///
    /// ```motoko
    ///
    ///     let vals = [].vals();
    ///     let max = Itertools.max(vals, Nat.compare);
    ///
    ///     assert max == null;
    /// ```
    public func max<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : ?A {
        var max : ?A = null;

        for (val in iter) {
            switch (max) {
                case (?m) {
                    if (cmp(val, m) == #greater) {
                        max := ?val;
                    };
                };
                case (null) {
                    max := ?val;
                };
            };
        };

        return max;
    };

    /// Returns the minimum value in an iterator.
    /// A null value is returned if the iterator is empty.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [8, 4, 6, 9].vals();
    ///     let min = Itertools.min(vals, Nat.compare);
    ///
    ///     assert min == ?4;
    /// ```
    ///
    /// - min on an empty iterator
    ///
    /// ```motoko
    ///
    ///     let vals: [Nat] = [].vals();
    ///     let min = Itertools.min(vals, Nat.compare);
    ///
    ///     assert min == null;
    /// ```
    public func min<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : ?A {
        var min : ?A = null;

        for (val in iter) {
            switch (min) {
                case (?m) {
                    if (cmp(val, m) == #less) {
                        min := ?val;
                    };
                };
                case (null) {
                    min := ?val;
                };
            };
        };

        return min;
    };

    /// Returns a tuple of the minimum and maximum value in an iterator.
    /// The first element is the minimum, the second the maximum.
    ///
    /// A null value is returned if the iterator is empty.
    ///
    /// If the iterator contains only one element, then it is returned as both
    /// the minimum and the maximum.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [8, 4, 6, 9].vals();
    ///     let minmax = Itertools.minmax(vals);
    ///
    ///     assert minmax == ?(4, 9);
    /// ```
    ///
    /// - minmax on an empty iterator
    ///
    /// ```motoko
    ///
    ///     let vals = [].vals();
    ///     let minmax = Itertools.minmax(vals);
    ///
    ///     assert minmax == null;
    /// ```
    /// - minmax on an iterator with one element
    ///
    /// ```motoko
    ///
    ///     let vals = [8].vals();
    ///     let minmax = Itertools.minmax(vals);
    ///
    ///     assert minmax == ?(8, 8);
    /// ```
    public func minmax<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : ?(A, A) {
        let (_min, _max) = switch (iter.next()) {
            case (?a) {
                switch (iter.next()) {
                    case (?b) {
                        switch (cmp(a, b)) {
                            case (#less) { (a, b) };
                            case (_) { (b, a) };
                        };
                    };
                    case (_) { (a, a) };
                };
            };
            case (_) {
                return null;
            };
        };

        var min = _min;
        var max = _max;

        for (val in iter) {
            if (cmp(val, min) == #less) {
                min := val;
            };

            if (cmp(val, max) == #greater) {
                max := val;
            };
        };

        ?(min, max)

    };

    /// Returns an iterator that merges two iterators in order.
    ///
    /// The two iterators must have be of the same type
    ///
    /// ### Example
    ///
    /// - merge two sorted lists
    ///
    /// ```motoko
    ///
    ///     let vals1 = [5, 6, 7].vals();
    ///     let vals2 = [1, 3, 4].vals();
    ///     let merged = Itertools.merge(vals1, vals2, Nat.compare);
    ///
    ///     assert Iter.toArray(merged) == [1, 3, 4, 5, 6, 7];
    /// ```
    ///
    /// - merge two unsorted lists
    ///
    /// ```motoko
    ///
    ///     let vals1 = [5, 2, 3].vals();
    ///     let vals2 = [8, 4, 1].vals();
    ///     let merged = Itertools.merge(vals1, vals2, Nat.compare);
    ///
    ///     assert Iter.toArray(merged) == [5, 2, 3, 8, 4, 1];
    /// ```
    public func merge<A>(iter1 : Iter.Iter<A>, iter2 : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : Iter.Iter<A> {
        let p1 = peekable(iter1);
        let p2 = peekable(iter2);

        object {
            public func next() : ?A {
                switch (p1.peek(), p2.peek()) {
                    case (?a, ?b) {
                        if (cmp(a, b) == #less) {
                            p1.next();
                        } else {
                            p2.next();
                        };
                    };
                    case (_, ?b) {
                        p2.next();
                    };
                    case (?a, _) {
                        p1.next();
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Returns an iterator that merges `k` iterators in order based on the `cmp` function.
    ///
    /// > Note: The iterators must have be of the same type
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals1 = [5, 6, 7].vals();
    ///     let vals2 = [1, 3, 4].vals();
    ///     let vals3 = [8, 4, 1].vals();
    ///     let merged = Itertools.kmerge([vals1, vals2, vals3], Nat.compare);
    ///
    ///     assert Iter.toArray(merged) == [1, 3, 4, 5, 6, 7, 8, 4, 1];
    /// ```

    public func kmerge<A>(iters : [Iter.Iter<A>], cmp : (A, A) -> Order.Order) : Iter.Iter<A> {
        type Index<A> = (A, Nat);

        let cmpIters = func(a : Index<A>, b : Index<A>) : Order.Order {
            cmp(a.0, b.0);
        };

        let heap = Heap.Heap<Index<A>>(cmpIters);

        for ((i, iter) in enumerate(iters.vals())) {
            switch (iter.next()) {
                case (?a) {
                    heap.put((a, i));
                };
                case (_) {

                };
            };
        };

        object {
            public func next() : ?A {
                switch (heap.removeMin()) {
                    case (?(min, i)) {
                        switch (iters[i].next()) {
                            case (?a) {
                                heap.put((a, i));
                            };
                            case (_) {};
                        };

                        ?min;
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Returns the run-length encoding of an Iterator
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let chars = "aaaabbbccd".chars();
    ///
    ///     let iter = Itertools.runLength(text.chars(), Char.equal);
    ///     let res = Iter.toArray(iter);
    ///
    ///     assert res == [('a', 4), ('b', 3), ('c', 2), ('d', 1)]
    ///
    /// ```
    public func runLength<A>(iter : Iter.Iter<A>, isEqual : (A, A) -> Bool) : Iter.Iter<(A, Nat)> {
        var cnt = 1;
        var curr = switch (iter.next()) {
            case (?a) { ?a };
            case (_) { return empty() };
        };

        object {
            public func next() : ?(A, Nat) {
                switch (curr, iter.next()) {
                    case (?a, ?b) {
                        if (isEqual(a, b)) {
                            cnt += 1;
                            next();
                        } else {
                            let tmp = (a, cnt);
                            curr := ?b;
                            cnt := 1;

                            ?tmp;
                        };
                    };
                    case (?a, _) {
                        curr := null;

                        ?(a, cnt);
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Checks if two iterators are not equal.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals1 = [5, 6, 7].vals();
    ///     let vals2 = [1, 3, 4].vals();
    ///
    ///     assert Itertools.notEqual(vals1, vals2, Nat.equal);
    ///
    ///     let vals3 = [1, 3, 4].vals();
    ///     let vals4 = [1, 3, 4].vals();
    ///
    ///     assert not Itertools.notEqual(vals3, vals4, Nat.equal));
    /// ```
    public func notEqual<A>(iter1 : Iter.Iter<A>, iter2 : Iter.Iter<A>, isEq : (A, A) -> Bool) : Bool {
        switch (iter1.next(), iter2.next()) {
            case (?a, ?b) {
                if (not isEq(a, b)) {
                    true;
                } else {
                    notEqual(iter1, iter2, isEq);
                };
            };
            case (_, ?b) true;
            case (?a, _) true;
            case (_, _) false;
        };
    };

    /// Returns the nth element of an iterator.
    /// Consumes the first n elements of the iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [0, 1, 2, 3, 4, 5].vals();
    ///     let nth = Itertools.nth(vals, 3);
    ///
    ///     assert nth == ?3;
    /// ```
    ///
    public func nth<A>(iter : Iter.Iter<A>, n : Nat) : ?A {
        let skippedIter = skip<A>(iter, n);
        return skippedIter.next();
    };

    /// Returns the nth elements of an iterator or a given default value.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [0, 1, 2, 3, 4, 5].vals();
    ///
    ///     assert Itertools.nthOrDefault(vals, 3, -1) == ?3;
    ///     assert Itertools.nthOrDefault(vals, 3, -1) == ?-1;
    /// ```
    public func nthOrDefault<A>(iter : Iter.Iter<A>, n : Nat, defaultValue : A) : A {
        switch (nth<A>(iter, n)) {
            case (?a) {
                return a;
            };
            case (_) {
                return defaultValue;
            };
        };
    };

    /// Pads an iterator with a given value until it is of a certain length.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3].vals();
    ///     let padded = Itertools.pad(vals, 6, 0);
    ///
    ///     assert Iter.toArray(padded) == [1, 2, 3, 0, 0, 0];
    /// ```
    public func pad<A>(iter : Iter.Iter<A>, length : Nat, value : A) : Iter.Iter<A> {
        var count = 0;

        object {
            public func next() : ?A {
                switch (iter.next()) {
                    case (?a) {
                        count += 1;
                        ?a;
                    };
                    case (_) {
                        if (count < length) {
                            count += 1;
                            ?value;
                        } else {
                            null;
                        };
                    };
                };
            };
        };
    };

    /// Pads an iterator with the result of a given function until it is of a certain length.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///
    ///     let vals = [1, 2, 3].vals();
    ///     let incrementIndex = func (i: Nat) { i + 1 };
    ///
    ///     let padded = Itertools.padWithFn(vals, 6, incrementIndex);
    ///assert Iter.toArray(padded) == [1, 2, 3, 4, 5, 6];
    /// ```
    public func padWithFn<A>(iter : Iter.Iter<A>, length : Nat, f : (Nat) -> A) : Iter.Iter<A> {
        var count : Nat = 0;

        object {
            public func next() : ?A {
                switch (iter.next()) {
                    case (?a) {
                        count += 1;
                        ?a;
                    };
                    case (_) {
                        if (count < length) {
                            count += 1;
                            ?f(count - 1);
                        } else {
                            null;
                        };
                    };
                };
            };
        };
    };

    /// Takes a partition function that returns `true` or `false`
    /// for each element in the iterator.
    /// The iterator is partitioned into a tuple of two arrays.
    /// The first array contains the elements all elements that
    /// returned `true` and the second array contains the elements
    /// that returned `false`.
    ///
    /// If the iterator is empty, it returns a tuple of two empty arrays.
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [0, 1, 2, 3, 4, 5].vals();
    ///     let isEven = func (n: Nat) : Bool { n % 2 == 0 };
    ///
    ///     let (even, odd) = Itertools.partition(vals, isEven);
    ///
    ///     assert even == [0, 2, 4];
    ///     assert odd == [1, 3, 5];
    ///
    /// ```
    public func partition<A>(iter : Iter.Iter<A>, f : (A) -> Bool) : ([A], [A]) {
        let firstGroup = Buffer.Buffer<A>(8);
        let secondGroup = Buffer.Buffer<A>(8);

        for (val in iter) {
            if (f(val)) {
                firstGroup.add(val);
            } else {
                secondGroup.add(val);
            };
        };

        (Buffer.toArray(firstGroup), Buffer.toArray(secondGroup));
    };

    /// Partitions an iterator in place so that the values that
    /// return `true` from the `predicate` are on the left and the
    /// values that return `false` are on the right.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [0, 1, 2, 3, 4, 5].vals();
    ///     let isEven = func (n: Nat) : Bool { n % 2 == 0 };
    ///
    ///     let iter = Itertools.partitionInPlace(vals, isEven);
    ///
    ///     assert Iter.toArray(iter) == [0, 2, 4, 1, 3, 5];
    ///
    /// ```
    public func partitionInPlace<A>(iter : Iter.Iter<A>, f : (A) -> Bool) : Iter.Iter<A> {
        let secondGroup = Buffer.Buffer<A>(8);
        var i = 0;

        object {
            public func next() : ?A {
                label l loop {
                    switch (iter.next()) {
                        case (?a) {
                            if (f(a)) {
                                return ?a;
                            } else {
                                secondGroup.add(a);
                            };
                        };
                        case (_) {
                            if (i >= secondGroup.size()) {
                                return null;
                            } else {
                                break l;
                            };
                        };
                    };
                };

                let tmp_index = i;
                i += 1;
                return ?secondGroup.get(tmp_index);
            };
        };
    };

    /// Checks if an iterator is partitioned by a predicate into
    /// two consecutive groups.
    /// The first n elements of the iterator return `true` when
    /// passed to the predicate, and the rest return `false`.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [0, 2, 4, 1, 3, 5].vals();
    ///     let isEven = func (n: Nat) : Bool { n % 2 == 0 };
    ///
    ///     let res = Itertools.isPartitioned(vals, isEven);
    ///
    ///     assert res == true;
    /// ```

    public func isPartitioned<A>(iter : Iter.Iter<A>, f : (A) -> Bool) : Bool {
        var inFirstGroup = true;

        for (val in iter) {
            if (f(val)) {
                if (not inFirstGroup) {
                    return false;
                };
            } else {
                if (inFirstGroup) {
                    inFirstGroup := false;
                };
            };
        };

        return true;
    };

    /// Returns a peekable iterator.
    /// The iterator has a `peek` method that returns the next value
    /// without consuming the iterator.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = Iter.fromArray([1, 2]);
    ///     let peekIter = Itertools.peekable(vals);
    ///
    ///     assert peekIter.peek() == ?1;
    ///     assert peekIter.next() == ?1;
    ///
    ///     assert peekIter.peek() == ?2;
    ///     assert peekIter.peek() == ?2;
    ///     assert peekIter.next() == ?2;
    ///
    ///     assert peekIter.peek() == null;
    ///     assert peekIter.next() == null;
    /// ```
    public func peekable<T>(iter : Iter.Iter<T>) : PeekableIter.PeekableIter<T> {
        PeekableIter.fromIter<T>(iter);
    };

    /// Returns an iterator that yeilds all the permutations of the
    /// elements of the iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3].vals();
    ///     let perms = Itertools.permutations(vals, Nat.compare);
    ///
    ///     assert Iter.toArray(perms) == [
    ///         [1, 2, 3], [1, 3, 2],
    ///         [2, 1, 3], [2, 3, 1],
    ///         [3, 1, 2], [3, 2, 1]
    ///     ];
    /// ```
    public func permutations<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : Iter.Iter<[A]> {
        let arr = Iter.toArrayMut<A>(iter);
        let n = arr.size();

        let totalPermutations = Nat_Utils.factorial(n);
        var permutationsLeft = totalPermutations;

        object {
            public func next() : ?[A] {
                if (permutationsLeft == totalPermutations) {
                    permutationsLeft -= 1;
                    return ?Array.freeze(arr);
                };

                if (permutationsLeft == 0) {
                    return null;
                };

                permutationsLeft -= 1;

                var i = Int.abs(n - 2);

                while (i > 0 and not (cmp(arr[i], arr[i + 1]) == #less)) {
                    i -= 1;
                };

                var j = i +1;

                for (k in range(i + 1, n)) {
                    if (cmp(arr[k], arr[i]) == #greater) {
                        if (cmp(arr[k], arr[j]) == #less) {
                            j := k;
                        };
                    };
                };

                ArrayMut_Utils.swap(arr, i, j);
                ArrayMut_Utils.reverseFrom(arr, i + 1);

                ?Array.freeze(arr);
            };
        };
    };

    /// Add a value to the front of an iterator.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [2, 3].vals();
    ///     let iter = Itertools.prepend(1, vals);
    ///
    ///     assert Iter.toArray(iter) == [1, 2, 3];
    /// ```
    public func prepend<A>(value : A, iter : Iter.Iter<A>) : Iter.Iter<A> {
        var popped = false;
        object {
            public func next() : ?A {
                if (popped) {
                    iter.next();
                } else {
                    popped := true;
                    ?value;
                };
            };
        };
    };

    /// Consumes an iterator of integers and returns the product of all values.
    /// An empty iterator returns null.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let prod = Itertools.product(vals, Nat.mul);
    ///
    ///     assert prod == ?24;
    /// ```
    public func product<A>(iter : Iter.Iter<A>, mul : (A, A) -> A) : ?A {
        var acc : A = switch (iter.next()) {
            case (?n) n;
            case (_) return null;
        };

        for (n in iter) {
            acc := mul(acc, n);
        };

        ?acc;
    };

    /// Returns a `Nat` iterator that yields numbers in range [start, end).
    /// The base library provides a `range` function that returns an iterator from with start and end both inclusive.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let iter = Itertools.range(1, 5);
    ///
    ///     assert iter.next() == ?1;
    ///     assert iter.next() == ?2;
    ///     assert iter.next() == ?3;
    ///     assert iter.next() == ?4;
    ///     assert iter.next() == null;
    /// ```
    public func range(start : Nat, end : Nat) : Iter.Iter<Nat> {
        var i : Int = start;

        return object {
            public func next() : ?Nat {
                if (i < end) {
                    i += 1;
                    return ?Int.abs(i - 1);
                } else {
                    return null;
                };
            };
        };
    };

    /// Returns a `Int` iterator that yields numbers in range [start, end).
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let iter = Itertools.intRange(1, 4);
    ///
    ///     assert iter.next() == ?1;
    ///     assert iter.next() == ?2;
    ///     assert iter.next() == ?3;
    ///     assert iter.next() == null;
    /// ```
    public func intRange(start : Int, end : Int) : Iter.Iter<Int> {
        var i : Int = start;

        return object {
            public func next() : ?Int {
                if (i < end) {
                    i += 1;
                    return ?i;
                } else {
                    return null;
                };
            };
        };
    };

    /// Returns an optional value representing the application of the given
    /// function to each element and the accumulated result.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let add = func (a: Int, b: Int) : Int { a + b };
    ///
    ///     let sum = Itertools.reduce(vals, add);
    ///
    ///     assert sum == ?15;
    /// ```
    public func reduce<A>(iter : Iter.Iter<A>, f : (A, A) -> A) : ?A {
        switch (iter.next()) {
            case (?a) {
                var acc = a;

                for (val in iter) {
                    acc := f(acc, val);
                };

                ?acc;
            };
            case (_) {
                return null;
            };
        };
    };

    /// Returns an iterator that repeats a given value `n` times.
    /// To repeat a value infinitely, use `Iter.make` from the base library.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = Itertools.repeat(1, 3);
    ///
    ///     assert iter.next() == ?1;
    ///     assert iter.next() == ?1;
    ///     assert iter.next() == ?1;
    ///     assert iter.next() == null;
    /// ```
    public func repeat<A>(item : A, n : Nat) : Iter.Iter<A> {
        var i = 0;
        return object {
            public func next() : ?A {
                if (i < n) {
                    i += 1;
                    return ?item;
                } else {
                    null;
                };
            };
        };
    };

    /// Skips the first n elements of the iter
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = [1, 2, 3, 4, 5].vals();
    ///     Itertools.skip(iter, 2);
    ///
    ///     assert iter.next() == ?3;
    ///     assert iter.next() == ?4;
    ///     assert iter.next() == ?5;
    ///     assert iter.next() == null;
    /// ```
    public func skip<A>(iter : Iter.Iter<A>, n : Nat) : Iter.Iter<A> {
        var i = 0;
        label l while (i < n) {
            switch (iter.next()) {
                case (?val) {
                    i := i + 1;
                };
                case (_) {
                    break l;
                };
            };
        };

        iter;
    };

    /// Skips elements continuously while the predicate is true.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = [1, 2, 3, 4, 5].vals();
    ///     let lessThan3 = func (a: Int) : Bool { a < 3 };
    ///
    ///     Itertools.skipWhile(iter, lessThan3);
    ///
    ///     assert Iter.toArray(iter) == [3, 4, 5];
    ///
    /// ```
    public func skipWhile<A>(iter : Iter.Iter<A>, pred : (A) -> Bool) : Iter.Iter<A> {
        let peekableIter = peekable(iter);

        label l loop {
            switch (peekableIter.peek()) {
                case (?val) {
                    if (not pred(val)) {
                        break l;
                    };

                    ignore peekableIter.next();
                };
                case (_) {
                    break l;
                };
            };
        };

        peekableIter;
    };

    /// Returns overlapping tuple pairs from the given iterator.
    /// The first element of the iterator is paired with the second element, and the
    /// second is paired with the third element, and so on.
    /// ?(a, b), ?(b, c), ?(c, d), ...
    ///
    /// If the iterator has fewer than two elements, an null value is returned.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let pairs = Itertools.slidingTuples(vals);
    ///
    ///     assert pairs.next() == ?(1, 2);
    ///     assert pairs.next() == ?(2, 3);
    ///     assert pairs.next() == ?(3, 4);
    ///     assert pairs.next() == ?(4, 5);
    ///     assert pairs.next() == null;
    /// ```
    public func slidingTuples<A>(iter : Iter.Iter<A>) : Iter.Iter<(A, A)> {
        var prev = iter.next();

        return object {
            public func next() : ?(A, A) {
                switch (prev, iter.next()) {
                    case (?_prev, ?curr) {
                        let tmp = (_prev, curr);
                        prev := ?curr;
                        ?tmp;
                    };
                    case (_) {
                        return null;
                    };
                };
            };
        };
    };

    /// Returns consecutive, overlapping triplets from the given iterator.
    /// The iterator returns a tuple of three elements, which include the current element and the two proceeding ones.
    /// ?(a, b, c), ?(b, c, d), ?(c, d, e), ...
    ///
    /// If the iterator has fewer than three elements, an null value is returned.
    ///
    /// ### Example
    ///
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let triples = Itertools.slidingTriples(vals);
    ///
    ///     assert triples.next() == ?(1, 2, 3);
    ///     assert triples.next() == ?(2, 3, 4);
    ///     assert triples.next() == ?(3, 4, 5);
    ///     assert triples.next() == null;
    /// ```
    public func slidingTriples<A>(iter : Iter.Iter<A>) : Iter.Iter<(A, A, A)> {
        var a = iter.next();
        var b = iter.next();

        return object {
            public func next() : ?(A, A, A) {
                switch (a, b, iter.next()) {
                    case (?_a, ?_b, ?curr) {
                        let tmp = (_a, _b, curr);
                        a := b;
                        b := ?curr;
                        ?tmp;
                    };
                    case (_) {
                        return null;
                    };
                };
            };
        };
    };

    /// Returns an iterator where all the elements are sorted in ascending order.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [8, 3, 5, 4, 1].vals();
    ///     let sorted = Itertools.sort(vals);
    ///
    ///     assert Iter.toArray(sorted) == [1, 3, 4, 5, 8];
    /// ```
    public func sort<A>(iter : Iter.Iter<A>, cmp : (A, A) -> Order.Order) : Iter.Iter<A> {
        let heap = Heap.Heap<A>(cmp);

        for (val in iter) {
            heap.put(val);
        };

        object {
            public func next() : ?A {
                heap.removeMin();
            };
        };
    };

    /// Returns a tuple of iterators where the first element is the first n elements of the iterator, and the second element is the remaining elements.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = [1, 2, 3, 4, 5].vals();
    ///     let (left, right) = Itertools.splitAt(iter, 3);
    ///
    ///     assert left.next() == ?1;
    ///     assert right.next() == ?4;
    ///
    ///     assert left.next() == ?2;
    ///     assert right.next() == ?5;
    ///
    ///     assert left.next() == ?3;
    ///
    ///     assert left.next() == null;
    ///     assert right.next() == null;
    /// ```
    public func splitAt<A>(iter : Iter.Iter<A>, n : Nat) : (Iter.Iter<A>, Iter.Iter<A>) {
        var left = Iter.toArray(take(iter, n)).vals();
        (left, iter);
    };

    /// Returns a tuple of iterators where the first element is an iterator with a copy of
    /// the first n elements of the iterator, and the second element is the original iterator
    /// with all the elements
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let (copy, iter) = Itertools.spy(vals, 3);
    ///
    ///     assert copy.next() == ?1;
    ///     assert copy.next() == ?2;
    ///     assert copy.next() == ?3;
    ///     assert copy.next() == null;
    ///
    ///     assert vals.next() == ?1;
    ///     assert vals.next() == ?2;
    ///     assert vals.next() == ?3;
    ///     assert vals.next() == ?4;
    ///     assert vals.next() == ?5;
    ///     assert vals.next() == null;
    /// ```

    public func spy<A>(iter : Iter.Iter<A>, n : Nat) : (Iter.Iter<A>, Iter.Iter<A>) {
        // let firstN =
        var copy = Iter.toArray(take(iter, n));
        (copy.vals(), chain(copy.vals(), iter));
    };

    /// Returns every nth element of the iterator.
    /// n must be greater than zero.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let iter = Itertools.stepBy(vals, 2);
    ///
    ///     assert iter.next() == ?1;
    ///     assert iter.next() == ?3;
    ///     assert iter.next() == ?5;
    ///     assert iter.next() == null;
    /// ```
    public func stepBy<A>(iter : Iter.Iter<A>, n : Nat) : Iter.Iter<A> {
        assert n > 0;

        return object {
            public func next() : ?A {
                switch (iter.next()) {
                    case (?item) {
                        ignore skip(iter, Int.abs(n - 1));
                        ?item;
                    };
                    case (_) {
                        return null;
                    };
                };
            };
        };
    };

    /// Creates an iterator from the given value a where the next
    /// elements are the results of the given function applied to
    /// the previous element.
    ///
    /// The function takes the previous value and returns an Optional
    /// value.  If the function returns null when the function
    /// returns null.
    ///
    /// ### Example
    /// ```motoko
    ///     import Nat "mo:base/Nat";
    ///
    ///     let optionSquaresOfSquares = func(n: Nat) : ?Nat{
    ///         let square = n * n;
    ///
    ///         if (square <= Nat.pow(2, 64)) {
    ///             return ?square;
    ///         };
    ///
    ///         return null;
    ///     };
    ///
    ///     let succIter = Itertools.successor(
    ///          2,
    ///          optionSquaresOfSquares
    ///     );
    ///
    ///     let res = Iter.toArray(succIter);
    ///
    ///     assert res == [
    ///         2, 4, 16, 256, 65_536, 4_294_967_296,
    ///     ];
    ///
    /// ```
    public func successor<A>(start : A, f : (A) -> ?A) : Iter.Iter<A> {
        var curr = start;

        object {
            public func next() : ?A {
                switch (f(curr)) {
                    case (?n) {
                        let prev = curr;
                        curr := n;

                        ?prev;
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Consumes an iterator of integers and returns the sum of all values.
    /// An empty iterator returns `null`.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4].vals();
    ///     let sum = Itertools.sum(vals, Nat.add);
    ///
    ///     assert sum == ?10;
    /// ```
    public func sum<A>(iter : Iter.Iter<A>, add : (A, A) -> A) : ?A {
        var acc : A = switch (iter.next()) {
            case (?n) n;
            case (_) return null;
        };

        for (n in iter) {
            acc := add(acc, n);
        };

        ?acc;
    };

    /// Returns an iterator with the first n elements of the given iter
    /// > Be aware that this returns a reference to the original iterator so
    /// > using it will cause the original iterator to be skipped.
    ///
    /// If you want to keep the original iterator, use `spy` instead.
    ///
    /// Note that using the returned iterator and the given iterator at the same time will cause the values in both iterators to be skipped.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = Iter.fromArray([1, 2, 3, 4, 5]);
    ///     let it = Itertools.take(iter, 3);
    ///
    ///     assert it.next() == ?1;
    ///     assert it.next() == ?2;
    ///     assert it.next() == ?3;
    ///     assert it.next() == null;
    ///
    ///     // the first n elements of the original iterator are skipped
    ///     assert iter.next() == ?4;
    ///     assert iter.next() == ?5;
    ///     assert iter.next() == null;
    /// ```

    public func take<A>(iter : Iter.Iter<A>, n : Nat) : Iter.Iter<A> {
        var i = 0;
        return object {
            public func next() : ?A {
                if (i < n) {
                    i := i + 1;
                    iter.next();
                } else {
                    null;
                };
            };
        };
    };

    /// Creates an iterator that returns returns elements from the given iter while the predicate is true.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = Iter.fromArray([1, 2, 3, 4, 5]);
    ///
    ///     let lessThan3 = func (x: Int) : Bool { x < 3 };
    ///     let it = Itertools.takeWhile(vals, lessThan3);
    ///
    ///     assert it.next() == ?1;
    ///     assert it.next() == ?2;
    ///     assert it.next() == null;
    /// ```
    public func takeWhile<A>(iter : Iter.Iter<A>, predicate : A -> Bool) : Iter.Iter<A> {
        var iterate = true;
        return object {
            public func next() : ?A {
                if (iterate) {
                    switch (iter.next()) {
                        case (?item) {
                            if (predicate(item)) {
                                ?item;
                            } else {
                                iterate := false;
                                null;
                            };
                        };
                        case (_) {
                            iterate := false;
                            return null;
                        };
                    };
                } else {
                    return null;
                };
            };
        };
    };

    /// Consumes an iterator and returns a tuple of cloned iterators.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = [1, 2, 3].vals();
    ///     let (iter1, iter2) = Itertools.tee(iter);
    ///
    ///     assert iter1.next() == ?1;
    ///     assert iter1.next() == ?2;
    ///     assert iter1.next() == ?3;
    ///     assert iter1.next() == null;
    ///
    ///     assert iter2.next() == ?1;
    ///     assert iter2.next() == ?2;
    ///     assert iter2.next() == ?3;
    ///     assert iter2.next() == null;
    /// ```
    public func tee<A>(iter : Iter.Iter<A>) : (Iter.Iter<A>, Iter.Iter<A>) {
        let array = Iter.toArray(iter);

        return (array.vals(), array.vals());
    };

    /// Returns an iterator of consecutive, non-overlapping tuple pairs of elements from a single iter.
    /// The first element is paired with the second element, the third element with the fourth, and so on.
    /// ?(a, b), ?(c, d), ?(e, f) ...
    ///
    /// If the iterator has less than two elements, it will return a null.
    /// > For overlappping pairs use slidingTuples.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let it = Itertools.tuples(vals);
    ///
    ///     assert it.next() == ?(1, 2);
    ///     assert it.next() == ?(3, 4);
    ///     assert it.next() == null;
    ///
    /// ```
    public func tuples<A>(iter : Iter.Iter<A>) : Iter.Iter<(A, A)> {
        return object {
            public func next() : ?(A, A) {
                switch (iter.next(), iter.next()) {
                    case (?a, ?b) {
                        ?(a, b);
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Returns an iterator of consecutive, non-overlapping triplets of elements from a single iter.
    /// ?(a, b, c), ?(d, e, f) ...
    ///
    /// If the iterator has less than three elements, it will return a null.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5, 6, 7].vals();
    ///     let it = Itertools.triples(vals);
    ///
    ///     assert it.next() == ?(1, 2, 3);
    ///     assert it.next() == ?(4, 5, 6);
    ///     assert it.next() == null;
    ///
    /// ```
    public func triples<A>(iter : Iter.Iter<A>) : Iter.Iter<(A, A, A)> {
        return object {
            public func next() : ?(A, A, A) {
                switch (iter.next(), iter.next(), iter.next()) {
                    case (?a, ?b, ?c) {
                        ?(a, b, c);
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Returns an iterator with unique elements from the given iter.
    ///
    /// ### Example
    /// ```motoko
    ///     import Nat "mo:base/Nat";
    ///     import Hash "mo:base/Hash";
    ///
    ///     let vals = [1, 2, 3, 1, 2, 3].vals();
    ///     let it = Itertools.unique(vals, Hash.hash, Nat.equal);
    ///
    ///     assert it.next() == ?1;
    ///     assert it.next() == ?2;
    ///     assert it.next() == ?3;
    ///     assert it.next() == null;
    ///
    /// ```
    public func unique<A>(iter : Iter.Iter<A>, hashFn : (A) -> Hash.Hash, isEq : (A, A) -> Bool) : Iter.Iter<A> {
        var set = TrieSet.empty<A>();

        return object {
            public func next() : ?A {
                var res : ?A = null;

                label l loop {
                    switch (iter.next()) {
                        case (?item) {
                            let hash = hashFn(item);

                            if (TrieSet.mem<A>(set, item, hash, isEq)) {
                                continue l;
                            };

                            set := TrieSet.put<A>(set, item, hash, isEq);
                            res := ?item;

                            break l;
                        };
                        case (_) {
                            break l;
                        };
                    };
                };

                return res;
            };
        };
    };

    /// Returns an iterator with the elements of the given iter and a boolean
    /// indicating if the element is unique.
    ///
    /// ### Example
    /// ```motoko
    ///     import Nat "mo:base/Nat";
    ///     import Hash "mo:base/Hash";
    ///
    ///     let vals = [1, 2, 3, 1, 2, 3].vals();
    ///     let it = Itertools.uniqueCheck(vals, Hash.hash, Nat.equal);
    ///
    ///     assert Iter.toArray(it) == [
    ///         (1, true), (2, true), (3, true),
    ///         (1, false), (2, false), (3, false)
    ///     ];
    ///
    /// ```
    public func uniqueCheck<A>(
        iter : Iter.Iter<A>,
        hashFn : (A) -> Hash.Hash,
        isEq : (A, A) -> Bool,
    ) : Iter.Iter<(A, Bool)> {
        var set = TrieSet.empty<A>();

        return object {
            public func next() : ?(A, Bool) {
                var res : ?(A, Bool) = null;

                switch (iter.next()) {
                    case (?item) {
                        let hash = hashFn(item);
                        if (TrieSet.mem<A>(set, item, hash, isEq)) {
                            ?(item, false);
                        } else {
                            set := TrieSet.put<A>(set, item, hash, isEq);
                            ?(item, true);
                        };
                    };
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    /// Returns `true` if all the elements in the given iter are unique.
    /// The hash function and equality function are used to compare elements.
    ///
    /// > Note: If the iterator is empty, it will return `true`.
    /// ### Example
    ///
    /// ```motoko
    ///     import Nat "mo:base/Nat";
    ///     import Hash "mo:base/Hash";
    ///
    ///     let vals = [1, 2, 3, 1, 2, 3].vals();
    ///     let res = Itertools.isUnique(vals, Hash.hash, Nat.equal);
    ///
    ///     assert res == false;
    ///
    /// ```
    public func isUnique<A>(iter : Iter.Iter<A>, hashFn : (A) -> Hash.Hash, isEq : (A, A) -> Bool) : Bool {
        var set = TrieSet.empty<A>();

        for (item in iter) {
            let hash = hashFn(item);

            if (TrieSet.mem<A>(set, item, hash, isEq)) {
                return false;
            };

            set := TrieSet.put<A>(set, item, hash, isEq);
        };

        return true;
    };

    /// Unzips an iterator of tuples into a tuple of arrays.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter = [(1, 'a'), (2, 'b'), (3, 'c')].vals();
    ///     let (arr1, arr2) = Itertools.unzip(iter);
    ///
    ///     assert arr1 == [1, 2, 3];
    ///     assert arr2 == ['a', 'b', 'c'];
    /// ```
    public func unzip<A>(iter : Iter.Iter<(A, A)>) : ([A], [A]) {
        var buf1 = Buffer.Buffer<A>(1);
        var buf2 = Buffer.Buffer<A>(1);

        for ((a, b) in iter) {
            buf1.add(a);
            buf2.add(b);
        };

        (Buffer.toArray(buf1), Buffer.toArray(buf2));
    };

    /// Zips two iterators into one iterator of tuples
    /// The length of the zipped iterator is equal to the length
    /// of the shorter iterator
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter1 = [1, 2, 3, 4, 5].vals();
    ///     let iter2 = "abc".chars();
    ///     let zipped = Itertools.zip(iter1, iter2);
    ///
    ///     assert zipped.next() == ?(1, 'a');
    ///     assert zipped.next() == ?(2, 'b');
    ///     assert zipped.next() == ?(3, 'c');
    ///     assert zipped.next() == null;
    /// ```

    public func zip<A, B>(a : Iter.Iter<A>, b : Iter.Iter<B>) : Iter.Iter<(A, B)> {
        object {
            public func next() : ?(A, B) {
                switch (a.next(), b.next()) {
                    case (?valueA, ?valueB) ?(valueA, valueB);
                    case (_, _) null;
                };
            };
        };
    };

    /// Zips three iterators into one iterator of tuples
    /// The length of the zipped iterator is equal to the length
    /// of the shorter iterator
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter1 = [1, 2, 3, 4, 5].vals();
    ///     let iter2 = "abc".chars();
    ///     let iter3 = [1.35, 2.92, 3.74, 4.12, 5.93].vals();
    ///
    ///     let zipped = Itertools.zip3(iter1, iter2, iter3);
    ///
    ///     assert zipped.next() == ?(1, 'a', 1.35);
    ///     assert zipped.next() == ?(2, 'b', 2.92);
    ///     assert zipped.next() == ?(3, 'c', 3.74);
    ///     assert zipped.next() == null;
    /// ```
    public func zip3<A, B, C>(a : Iter.Iter<A>, b : Iter.Iter<B>, c : Iter.Iter<C>) : Iter.Iter<(A, B, C)> {
        object {
            public func next() : ?(A, B, C) {
                switch (a.next(), b.next(), c.next()) {
                    case (?valueA, ?valueB, ?valueC) ?(valueA, valueB, valueC);
                    case (_) null;
                };
            };
        };
    };

    public type Either<A, B> = {
        #left : A;
        #right : B;
    };

    public type EitherOr<A, B> = Either<A, B> or {
        #both : (A, B);
    };

    /// Zips two iterators until both iterators are exhausted.
    /// The length of the zipped iterator is equal to the length
    /// of the longest iterator.
    ///
    /// The iterator returns a [`EitherOr`](#EitherOr) type of the two iterators.
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let iter1 = [1, 2, 3, 4, 5].vals();
    ///     let iter2 = "abc".chars();
    ///     let zipped = Itertools.zipLongest(iter1, iter2);
    ///
    ///     assert zipped.next() == ?#both(1, 'a');
    ///     assert zipped.next() == ?#both(2, 'b');
    ///     assert zipped.next() == ?#both(3, 'c');
    ///     assert zipped.next() == ?#left(4);
    ///     assert zipped.next() == ?#left(5);
    ///     assert zipped.next() == null;
    /// ```
    public func zipLongest<A, B>(iterA : Iter.Iter<A>, iterB : Iter.Iter<B>) : Iter.Iter<EitherOr<A, B>> {
        object {
            public func next() : ?EitherOr<A, B> {
                switch (iterA.next(), iterB.next()) {
                    case (?a, ?b) ?#both(a, b);
                    case (?a, _) ?#left(a);
                    case (_, ?b) ?#right(b);
                    case (_, _) null;
                };
            };
        };
    };

    // ==============================================================================================
    // =============================== Iterator Collection Methods ===============================
    // ==============================================================================================

    /// Transforms a slice of an array into an iterator
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let arr = [1, 2, 3, 4, 5];
    ///     let slicedIter = Itertools.fromArraySlice(arr, 2, arr.size());
    ///
    ///     assert Iter.toArray(slicedIter) == [3, 4, 5];
    /// ```
    public func fromArraySlice<A>(arr : [A], start : Nat, end : Nat) : Iter.Iter<A> {
        var i = start;
        var j = Nat.min(end, arr.size());

        object {
            public func next() : ?A {
                if (i < j) {
                    i += 1;
                    ?arr[i - 1];
                } else {
                    null;
                };
            };
        };
    };

    /// Collects an iterator of any type into a buffer
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let vals = [1, 2, 3, 4, 5].vals();
    ///     let buf = Itertools.toBuffer(vals);
    ///
    ///     assert buf.toArray() == [1, 2, 3, 4, 5];
    /// ```
    public func toBuffer<A>(iter : Iter.Iter<A>) : Buffer.Buffer<A> {
        let buf = Buffer.Buffer<A>(8);
        for (item in iter) {
            buf.add(item);
        };

        return buf;
    };

    /// Converts an iterator to a deque.
    public func toDeque<T>(iter : Iter.Iter<T>) : Deque.Deque<T> {
        var dq = Deque.empty<T>();

        for (item in iter) {
            dq := Deque.pushBack(dq, item);
        };

        dq;
    };

    /// Converts an Iter into a List
    public func toList<A>(iter : Iter.Iter<A>) : List.List<A> {
        var list = List.nil<A>();

        for (item in iter) {
            list := List.push(item, list);
        };

        list;
    };

    /// Collects an iterator of characters into a text
    ///
    /// ### Example
    /// ```motoko
    ///
    ///     let chars = "abc".chars();
    ///     let text = Itertools.toText(chars);
    ///
    ///     assert text == "abc";
    /// ```
    public func toText(charIter : Iter.Iter<Char>) : Text {
        let textIter = Iter.map<Char, Text>(charIter, func(c) { Char.toText(c) });
        Text.join("", textIter);
    };

    /// Converts a TrieSet into an Iter
    public func fromTrieSet<A>(set : TrieSet.Set<A>) : Iter.Iter<A> {
        Iter.map<(A, ()), A>(
            Trie.iter<A, ()>(set),
            func((item, _)) { item },
        );
    };

    /// Collects an iterator into a TrieSet
    ///
    /// ### Example
    /// ```motoko
    ///     import Hash "mo:base/Hash";
    ///     import TrieSet "mo:base/TrieSet";
    ///
    ///     let vals = [1, 1, 2, 3, 4, 4, 5].vals();
    ///     let set = Itertools.toTrieSet(vals, Hash.hash, Nat.equal);
    ///
    ///     let setIter = Itertools.fromTrieSet(set);
    ///     assert Iter.toArray(setIter) == [1, 2, 3, 4, 5];
    ///
    /// ```
    public func toTrieSet<A>(iter : Iter.Iter<A>, hashFn : (A) -> Hash.Hash, isEq : (A, A) -> Bool) : TrieSet.Set<A> {
        var set = TrieSet.empty<A>();

        label l for (item in iter) {
            let hash = hashFn(item);

            if (TrieSet.mem(set, item, hash, isEq)) {
                continue l;
            } else {
                set := TrieSet.put(set, item, hash, isEq);
            };
        };

        set;
    };
};
