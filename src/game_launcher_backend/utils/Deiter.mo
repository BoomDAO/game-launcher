/// Double Ended Iterator
///
/// This type of iterator allows for both forward and backward iteration
/// Double Ended Iterators are useful for iterating over data structures in reverse without allocating extra space for the reverse iteration.
///
/// The `Deiter` type is an extension of the `Iter` type built in Motoko
/// so it is compatible with all the function defined for the `Iter` type.
///
///
/// The `Deiter` is intended to be used with functions for the `Iter` type to avoid rewriting similar functions for both types.
///
/// - An example reversing a list of integers and breaking them into chunks of size `n`:
///
/// ```motoko
///
///   import Itertools "mo:itertools/Iter";
///   import Deiter "mo:itertools/Deiter";
///
///   let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
///
///   // create a double ended iterator from an array
///   let deiter = Deiter.fromArray(arr);
///
///   // reverse double ended iterator
///   let revDeiter = Deiter.reverse(deiter);
///
///   // Double Ended Iter gets typecasted to an Iter typw
///   let chunks = Itertools.chunks(revDeiter, 3);
///
///   assert chunks.next() == ?[10, 9, 8];
///   assert chunks.next() == ?[7, 6, 5];
///   assert chunks.next() == ?[4, 3, 2];
///   assert chunks.next() == ?[1];
///   assert chunks.next() == null;
///
/// ```

import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import List "mo:base/List";
import Deque "mo:base/Deque";

module {
  /// Double Ended Iterator Type
  public type Deiter<T> = Iter.Iter<T> and {
    next_back : () -> ?T;
  };

  /// Returns a Double Ended Iterator over a range of natural, `Nat` numbers from [start, end)
  public func range(start : Nat, end : Nat) : Deiter<Nat> {
    let intIter = intRange(start, end);

    func optIntToNat(optInt : ?Int) : ?Nat {
      switch (optInt) {
        case (null) null;
        case (?val) ?Int.abs(val);
      };
    };

    return object {
      public func next() : ?Nat {
        optIntToNat(intIter.next());
      };
      public func next_back() : ?Nat {
        optIntToNat(intIter.next_back());
      };
    };
  };

  /// Returns a Double Ended Iterator over a range of integers (`Int`) from [start, end)
  public func intRange(start : Int, end : Int) : Deiter<Int> {
    var i = start;
    var j = end;

    return object {
      public func next() : ?Int {
        if (i < end and i < j) {
          let tmp = i;
          i += 1;
          return ?tmp;
        } else {
          return null;
        };
      };

      public func next_back() : ?Int {
        if (j > start and j > i) {
          j -= 1;
          return ?j;
        } else {
          return null;
        };
      };
    };
  };

  /// @deprecated in favor of `reverse`
  public func rev<T>(deiter : Deiter<T>) : Deiter<T> {
    reverse<T>(deiter);
  };

  /// Returns an iterator that iterates over the elements in reverse order.
  /// #### Example
  ///
  /// ```motoko
  ///
  ///   let arr = [1, 2, 3];
  ///   let deiter = Deiter.fromArray(arr);
  ///
  ///   assert deiter.next() == ?1;
  ///   assert deiter.next() == ?2;
  ///   assert deiter.next() == ?3;
  ///   assert deiter.next() == null;
  ///
  ///   let deiter2 = Deiter.fromArray(arr);
  ///   let revIter = Deiter.reverse(deiter2);
  ///
  ///   assert revIter.next() == ?3;
  ///   assert revIter.next() == ?2;
  ///   assert revIter.next() == ?1;
  ///   assert revIter.next() == null;
  ///
  /// ```
  public func reverse<T>(deiter : Deiter<T>) : Deiter<T> {
    return object {
      public func next() : ?T {
        deiter.next_back();
      };
      public func next_back() : ?T {
        deiter.next();
      };
    };
  };

  /// Creates an iterator for the elements of an array.
  ///
  /// #### Example
  ///
  /// ```motoko
  ///
  ///   let arr = [1, 2, 3];
  ///   let deiter = Deiter.fromArray(arr);
  ///
  ///   assert deiter.next() == ?1;
  ///   assert deiter.next_back() == ?3;
  ///   assert deiter.next_back() == ?2;
  ///   assert deiter.next_back() == null;
  ///   assert deiter.next() == null;
  ///
  /// ```
  public func fromArray<T>(array : [T]) : Deiter<T> {
    var left = 0;
    var right = array.size();

    return {
      next = func() : ?T {
        if (left < right) {
          left += 1;
          ?array[left - 1];
        } else {
          null;
        };
      };
      next_back = func() : ?T {
        if (left < right) {
          right -= 1;
          ?array[right];
        } else {
          null;
        };
      };
    };
  };

  public func toArray<T>(deiter : Deiter<T>) : [T] {
    Iter.toArray(deiter);
  };

  public func fromArrayMut<T>(array : [var T]) : Deiter<T> {
    fromArray<T>(Array.freeze<T>(array));
  };

  public func toArrayMut<T>(deiter : Deiter<T>) : [var T] {
    Iter.toArrayMut<T>(deiter);
  };

  /// Type Conversion from Deiter to Iter
  public func toIter<T>(iter : Iter.Iter<T>) : Iter.Iter<T> {
    iter;
  };

  /// Returns an iterator for a deque.
  public func fromDeque<T>(deque : Deque.Deque<T>) : Deiter<T> {

    var deq = deque;
    return object {
      public func next() : ?T {
        switch (Deque.popFront(deq)) {
          case (?(val, next)) {
            deq := next;
            ?val;
          };
          case (null) null;
        };
      };

      public func next_back() : ?T {
        switch (Deque.popBack(deq)) {
          case (?(prev, val)) {
            deq := prev;
            ?val;
          };
          case (null) null;
        };
      };
    };
  };

  /// Converts an iterator to a deque.
  public func toDeque<T>(deiter : Deiter<T>) : Deque.Deque<T> {
    var dq = Deque.empty<T>();

    for (item in deiter) {
      dq := Deque.pushBack(dq, item);
    };

    dq;
  };
};
