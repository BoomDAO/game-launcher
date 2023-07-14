/// Generic, extensible buffers
///
/// `StableBuffer<X>` is adapted directly from https://github.com/dfinity/motoko-base/blob/master/src/Buffer.mo,
/// ripping all functions and instance variables out of the `Buffer` class in order to make a stable, persistent 
/// buffer.
///
/// Generic, mutable sequences that grow to accommodate arbitrary numbers of elements.
///
/// `StableBuffer<X>` provides extensible, mutable sequences of elements of type `X`.
/// that can be efficiently produced and consumed with imperative code.
/// A buffer object can be extended by a single element or the contents of another buffer object.
///
/// When required, the current state of a buffer object can be converted to a fixed-size array of its elements.
///
/// Buffers complement Motoko's non-extensible array types
/// (arrays do not support efficient extension, because the size of an array is
/// determined at construction and cannot be changed).

import Prim "mo:⛔";

module {

  public type StableBuffer<X> = {
    initCapacity: Nat;
    var count: Nat;
    var elems: [var X];
  };

  /// Initializes a buffer of given initial capacity. Note that this capacity is not realized until an element
  /// is added to the buffer. 
  public func initPresized<X>(initCapacity: Nat): StableBuffer<X> = {
    initCapacity = initCapacity;
    var count = 0;
    var elems = [var];
  };

  /// Initializes a buffer of initial capacity 0. When the first element is added the size will grow to one
  public func init<X>(): StableBuffer<X> = {
    initCapacity = 0;
    var count = 0;
    var elems = [var];
  };

  /// Adds a single element to the buffer.
  public func add<X>(buffer: StableBuffer<X>, elem: X): () {
    if (buffer.count == buffer.elems.size()) {
      let size =
        if (buffer.count == 0) {
          if (buffer.initCapacity > 0) { buffer.initCapacity } else { 1 }
        } else {
          2 * buffer.elems.size()
        };
      let elems2 = Prim.Array_init<X>(size, elem);
      var i = 0;
      label l loop {
        if (i >= buffer.count) break l;
        elems2[i] := buffer.elems[i];
        i += 1;
      };
      buffer.elems := elems2;
    };
    buffer.elems[buffer.count] := elem;
    buffer.count += 1;
  };

  /// Removes the item that was inserted last and returns it or `null` if no
  /// elements had been added to the buffer.
  public func removeLast<X>(buffer: StableBuffer<X>) : ?X {
    if (buffer.count == 0) {
      null
    } else {
      buffer.count -= 1;
      ?buffer.elems[buffer.count]
    };
  };

  /// Adds all elements in buffer `b` to buffer `a`.
  public func append<X>(a: StableBuffer<X>, b : StableBuffer<X>): () {
    let i = vals(b);
    loop {
      switch (i.next()) {
        case null return;
        case (?x) { add(a, x) };
      };
    };
  };

  /// Returns the count of elements in the buffer
  public func size<X>(buffer: StableBuffer<X>) : Nat { buffer.count };

  /// Resets the buffer.
  public func clear<X>(buffer: StableBuffer<X>): () {
    buffer.count := 0;
  };

  /// Returns a copy of this buffer.
  public func clone<X>(buffer: StableBuffer<X>) : StableBuffer<X> {
    let c = initPresized<X>(buffer.elems.size());
    var i = 0;
    label l loop {
      if (i >= buffer.count) break l;
      add(c, buffer.elems[i]);
      i += 1;
    };
    c
  };

  /// Returns an `Iter` over the elements of this buffer.
  public func vals<X>(buffer: StableBuffer<X>) : { next : () -> ?X } = object {
    var pos = 0;
    public func next() : ?X {
      if (pos == buffer.count) { null } else {
        let elem = ?buffer.elems[pos];
        pos += 1;
        elem
      }
    }
  };

  /// Creates a Buffer from an Array
  public func fromArray<X>(xs: [X]): StableBuffer<X> {
    let ys: StableBuffer<X> = initPresized(xs.size());
    for (x in xs.vals()) {
      add(ys, x);
    };

    ys
  };

  /// Creates a new array containing this buffer's elements.
  public func toArray<X>(buffer: StableBuffer<X>) : [X] =
    // immutable clone of array
    Prim.Array_tabulate<X>(
      buffer.count,
      func(x : Nat) : X { buffer.elems[x] }
    );

  /// Creates a mutable array containing this buffer's elements.
  public func toVarArray<X>(buffer: StableBuffer<X>) : [var X] {
    if (buffer.count == 0) { [var] } else {
      let a = Prim.Array_init<X>(buffer.count, buffer.elems[0]);
      var i = 0;
      label l loop {
        if (i >= buffer.count) break l;
        a[i] := buffer.elems[i];
        i += 1;
      };
      a
    }
  };

  /// Gets the `i`-th element of this buffer. Traps if  `i >= count`. Indexing is zero-based.
  public func get<X>(buffer: StableBuffer<X>, i : Nat) : X {
    assert(i < buffer.count);
    buffer.elems[i]
  };

  /// Gets the `i`-th element of the buffer as an option. Returns `null` when `i >= count`. Indexing is zero-based.
  public func getOpt<X>(buffer: StableBuffer<X>, i : Nat) : ?X {
    if (i < buffer.count) {
      ?buffer.elems[i]
    }
    else {
      null
    }
  };

  /// Overwrites the current value of the `i`-entry of this buffer with `elem`. Traps if the
  /// index is out of bounds. Indexing is zero-based.
  public func put<X>(buffer: StableBuffer<X>, i : Nat, elem : X) {
    buffer.elems[i] := elem;
  };
}
