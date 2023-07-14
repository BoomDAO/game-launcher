/// Peekable Iterator
///
/// An iterator equipped with a `peek` method that returns the next value without advancing the iterator.
///
/// The `PeekableIter` type is an extension of the `Iter` type built in Motoko
/// so it is compatible with all the function defined for the `Iter` type.
///
import Iter "mo:base/Iter";

module {
    /// Peekable Iterator Type.
    public type PeekableIter<T> = Iter.Iter<T> and {
        peek : () -> ?T;
    };

    /// Creates a `PeekableIter` from an `Iter`.
    ///
    /// #### Example:
    ///     let vals = [1, 2].vals();
    ///     let peekableIter = PeekableIter.fromIter(vals);
    ///
    ///     assert peekableIter.peek() == ?1;
    ///     assert peekableIter.peek() == ?1;
    ///     assert peekableIter.next() == ?1;
    ///
    ///     assert peekableIter.peek() == ?2;
    ///     assert peekableIter.peek() == ?2;
    ///     assert peekableIter.peek() == ?2;
    ///     assert peekableIter.next() == ?2;
    ///
    ///     assert peekableIter.peek() == null;
    ///     assert peekableIter.next() == null;
    /// ```
    public func fromIter<T>(iter : Iter.Iter<T>) : PeekableIter<T> {
        var next_item = iter.next();

        return object {
            public func peek() : ?T {
                next_item;
            };

            public func next() : ?T {
                switch (next_item) {
                    case (?val) {
                        next_item := iter.next();
                        ?val;
                    };
                    case (null) {
                        null;
                    };
                };
            };
        };
    };
};
