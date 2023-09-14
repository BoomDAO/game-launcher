import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import AU "../src/ArrayUtil";
import AUM "./ArrayUtilMatchers";


let insertAtPositionSuite = S.suite("insertAtPosition", [
  S.test("inserting at the first index of an array of all nulls inserts at the first element",
    do {
      let array: [var ?Nat] = [var null, null, null];
      AU.insertAtPosition<Nat>(array, ?3, 0, 0);
      array;
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?3, null, null]
    ))
  ),
  S.test("inserting into the last spot inserts correctly without shifting elements over",
    do {
      let array: [var ?Nat] = [var ?2, ?3, null];
      AU.insertAtPosition<Nat>(array, ?5, 2, 1);
      array;
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?2, ?3, ?5]
    ))
  ),
  S.test("inserting into the first index of the array with non-null elements correctly inserts the element and shifts all existing elements over",
    do {
      let array: [var ?Nat] = [var ?2, ?3, null];
      AU.insertAtPosition<Nat>(array, ?1, 0, 1);
      array;
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?1, ?2, ?3]
    ))
  ),
  S.test("inserting into a middle index of the array with non-null elements correctly inserts the element and shifts all latter elements over",
    do {
      let array: [var ?Nat] = [var ?2, ?5, null, null];
      AU.insertAtPosition<Nat>(array, ?3, 1, 1);
      array;
    },
    do {
      
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?2, ?3, ?5, null]
    ))
    }
  ),
]);

let insertOneAtIndexAndSplitArraySuite = S.suite("insertOneAtIndexAndSplitArray", [
  S.suite("odd sized array", [
    S.test("insert split with largest element", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 9, 3);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, null], 7, [var ?9, null, null])
        ),
      )
    ),
    S.test("insert split with element in right half/split", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9, ?13];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 10, 4);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, ?7, null, null], 9, [var ?10, ?13, null, null, null])
        ),
      )
    ),
    S.test("insert split with element in middle", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9, ?13];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 8, 3);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, ?7, null, null], 8, [var ?9, ?13, null, null, null])
        ),
      )
    ),
    S.test("insert split with element in left half/split", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9, ?13];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 6, 2);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, ?6, null, null], 7, [var ?9, ?13, null, null, null])
        ),
      )
    ),
    S.test("insert split with smallest element", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9, ?13];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 1, 0);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?1, ?2, ?5, null, null], 7, [var ?9, ?13, null, null, null])
        ),
      )
    ),
  ]),
  S.suite("even sized array", [
    S.test("insert split with largest element", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 10, 4);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, null, null], 7, [var ?9, ?10, null, null])
        ),
      )
    ),
    S.test("insert split with element in right half/split", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 8, 3);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, null, null], 7, [var ?8, ?9, null, null])
        ),
      )
    ),
    S.test("insert split with element in middle", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 6, 2);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?5, null, null], 6, [var ?7, ?9, null, null])
        ),
      )
    ),
    S.test("insert split with element in left half/split", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 4, 1);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?2, ?4, null, null], 5, [var ?7, ?9, null, null])
        ),
      )
    ),
    S.test("insert split with smallest element", 
      do {
        let array: [var ?Nat] = [var ?2, ?5, ?7, ?9];
        AU.insertOneAtIndexAndSplitArray<Nat>(array, 1, 0);
      },
      M.equals(
        AUM.tuple3<[var ?Nat], Nat, [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          T.natTestable,
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?1, ?2, null, null ], 5, [var ?7, ?9, null, null])
        ),
      )
    ),
  ]),
]);


let insertTwoAtIndexAndSplitArraySuite = S.suite("insertTwoAtIndexAndSplitArray", [
  S.suite("odd sized array", [
    S.test("Case 1, both rebalanced child halves are inserted into smallest index of the left split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 0, 9, 11)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          // Note: 10 does not appear, as it was replaced by 9 & 11 (think of 10 as a node splitting in two, with 9 and 11 as the new rebalanced halves)
          ([var ?9, ?11, ?20, ?30, null, null, null], [var ?40, ?50, ?60, ?70, null, null, null])
        )
      ),
    ),
    S.test("Case 1, both rebalanced child halves are inserted into the middle of the left split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 1, 19, 21)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?19, ?21, ?30, null, null, null], [var ?40, ?50, ?60, ?70, null, null, null])
        )
      ),
    ),
    S.test("Case 1, both rebalanced child halves are inserted into the left split with the right rebalanced child as the last index of the left split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 2, 29, 31)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?29, ?31, null, null, null], [var ?40, ?50, ?60, ?70, null, null, null])
        )
      ),
    ),
    S.test("Case 2, both rebalanced child halves are inserted into smallest index of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 4, 49, 51)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, null, null, null], [var ?49, ?51, ?60, ?70, null, null, null])
        )
      ),
    ),
    S.test("Case 2, both rebalanced child halves are inserted into the middle of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 5, 59, 61)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, null, null, null], [var ?50, ?59, ?61, ?70, null, null, null])
        )
      ),
    ),
    S.test("Case 2, both rebalanced child halves are inserted into the right split with the right rebalanced child as the last index of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 6, 69, 71)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, null, null, null], [var ?50, ?60, ?69, ?71, null, null, null])
        )
      ),
    ),
    S.test("Case 3, the left rebalanced child half is inserted into the last index of the left split and the right rebalanced child is inserted into the first index of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70];
        AU.splitArrayAndInsertTwo<Nat>(array, 3, 39, 41)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?39, null, null, null], [var ?41, ?50, ?60, ?70, null, null, null])
        )
      ),
    ),
  ]),
  S.suite("even sized array", [
    S.test("Case 1, both rebalanced child halves are inserted into smallest index of the left split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 0, 9, 11)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          // Note: 10 does not appear, as it was replaced by 9 & 11 (think of 10 as a node splitting in two, with 9 and 11 as the new rebalanced halves)
          ([var ?9, ?11, ?20, ?30, ?40, null, null, null], [var ?50, ?60, ?70, ?80, null, null, null, null])
        )
      ),
    ),
    S.test("Case 1, both rebalanced child halves are inserted into the middle of the left split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 1, 19, 21)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?19, ?21, ?30, ?40, null, null, null], [var ?50, ?60, ?70, ?80, null, null, null, null])
        )
      ),
    ),
    S.test("Case 1, both rebalanced child halves are inserted into the left split with the right rebalanced child as the last index of the left split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 3, 39, 41)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?39, ?41, null, null, null], [var ?50, ?60, ?70, ?80, null, null, null, null])
        )
      ),
    ),
    S.test("Case 2, both rebalanced child halves are inserted into smallest index of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 5, 59, 61)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, ?50, null, null, null], [var ?59, ?61, ?70, ?80, null, null, null, null])
        )
      ),
    ),
    S.test("Case 2, both rebalanced child halves are inserted into the middle of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 6, 69, 71)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, ?50, null, null, null], [var ?60, ?69, ?71, ?80, null, null, null, null])
        )
      ),
    ),
    S.test("Case 2, both rebalanced child halves are inserted into the right split with the right rebalanced child as the last index of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 7, 79, 81)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, ?50, null, null, null], [var ?60, ?70, ?79, ?81, null, null, null, null])
        )
      ),
    ),
    S.test("Case 3, the left rebalanced child half is inserted into the last index of the left split and the right rebalanced child is inserted into the first index of the right split, replacing the element at that index",
      do {
        let array: [var ?Nat] = [var ?10, ?20, ?30, ?40, ?50, ?60, ?70, ?80];
        AU.splitArrayAndInsertTwo<Nat>(array, 4, 49, 51)
      },
      M.equals(
        T.tuple2<[var ?Nat], [var ?Nat]>(
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          AUM.varArrayTestable<?Nat>(
            T.optionalTestable<Nat>(T.natTestable)
          ),
          ([var ?10, ?20, ?30, ?40, ?49, null, null, null], [var ?51, ?60, ?70, ?80, null, null, null, null])
        )
      ),
    ),
  ])
]);


let deleteAndShiftValuesOverSuite = S.suite("deleteAndShiftValuesOverSuite", [
  S.test("if the array has a single element, deletes it, making the empty array",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), null, null, null];
      ignore AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 0);
      array;
    },
    M.equals(AUM.varArray<?(Nat, Nat)>(
      T.optionalTestable<(Nat, Nat)>(
        T.tuple2Testable<Nat, Nat>(T.natTestable, T.natTestable)
      ),
      [var null, null, null, null]
    ))
  ),
  S.test("Returns the value corresponding to the key that was deleted",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), ?(20, 20), ?(30, 30), ?(40, 40)];
      AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 2);
    },
    M.equals(T.tuple2(T.natTestable, T.natTestable, (30, 30)))
  ),
  S.test("with a full array if the delete index is at the end, removes it and makes the last value null",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), ?(20, 20), ?(30, 30), ?(40, 40)];
      ignore AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 3);
      array;
    },
    M.equals(AUM.varArray<?(Nat, Nat)>(
      T.optionalTestable<(Nat, Nat)>(
        T.tuple2Testable<Nat, Nat>(T.natTestable, T.natTestable)
      ),
      [var ?(10, 10), ?(20, 20), ?(30, 30), null]
    ))
  ),
  S.test("with a non-full array if the delete index is at the last non-null element, removes it and makes that value null",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), ?(20, 20), ?(30, 30), null];
      ignore AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 2);
      array;
    },
    M.equals(AUM.varArray<?(Nat, Nat)>(
      T.optionalTestable<(Nat, Nat)>(
        T.tuple2Testable<Nat, Nat>(T.natTestable, T.natTestable)
      ),
      [var ?(10, 10), ?(20, 20), null, null]
    ))
  ),
  S.test("with a full array if the deleted value is in the middle, removes it and moves all elements to the right over to the left 1",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), ?(20, 20), ?(30, 30), ?(40, 40)];
      ignore AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 1);
      array;
    },
    M.equals(AUM.varArray<?(Nat, Nat)>(
      T.optionalTestable<(Nat, Nat)>(
        T.tuple2Testable<Nat, Nat>(T.natTestable, T.natTestable)
      ),
      [var ?(10, 10), ?(30, 30), ?(40, 40), null]
    ))
  ),
  S.test("with a non-full array if the deleted value is in the middle, removes it and moves all elements to the right over to the left 1",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), ?(20, 20), ?(30, 30), null];
      ignore AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 1);
      array;
    },
    M.equals(AUM.varArray<?(Nat, Nat)>(
      T.optionalTestable<(Nat, Nat)>(
        T.tuple2Testable<Nat, Nat>(T.natTestable, T.natTestable)
      ),
      [var ?(10, 10), ?(30, 30), null, null]
    ))
  ),
  S.test("if the deleted value is at the beginning, removes it and moves all elements to the right over to the left 1",
    do {
      let array: [var ?(Nat, Nat)] = [var ?(10, 10), ?(20, 20), ?(30, 30), null];
      ignore AU.deleteAndShiftValuesOver<(Nat, Nat)>(array, 0);
      array;
    },
    M.equals(AUM.varArray<?(Nat, Nat)>(
      T.optionalTestable<(Nat, Nat)>(
        T.tuple2Testable<Nat, Nat>(T.natTestable, T.natTestable)
      ),
      [var ?(20, 20), ?(30, 30), null, null]
    ))
  ),
]);

let replaceTwoWithElementAndShiftSuite = S.suite("replaceTwoWithElementAndShiftSuite", [
  S.test("if replacing a full array at the first element, shifts everything over",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      AU.replaceTwoWithElementAndShift(array, 15, 0);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?15, ?30, ?40, ?50, null]
    ))
  ),
  S.test("if replacing a non-full array at the first element, shifts everything over until the first null is hit",
    do {
      let array = [var ?10, ?20, ?30, ?40, null];
      AU.replaceTwoWithElementAndShift(array, 15, 0);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?15, ?30, ?40, null, null]
    ))
  ),
  S.test("if replacing full array at the middle element, shifts everything after the element over",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      AU.replaceTwoWithElementAndShift(array, 25, 1);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?10, ?25, ?40, ?50, null]
    ))
  ),
  S.test("if replacing full array at the second to last element, just replaces it with the element",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      AU.replaceTwoWithElementAndShift(array, 45, 3);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?10, ?20, ?30, ?45, null]
    ))
  ),
]);

let insertAtPositionAndDeleteAtPositionSuite = S.suite("insertAtPostionAndDeleteAtPositionSuite", [
  S.test("if inserting at first index and deleting at last index",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      ignore AU.insertAtPostionAndDeleteAtPosition(array, ?5, 0, 4);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?5, ?10, ?20, ?30, ?40]
    ))
  ),
  S.test("if inserting at last index and deleting at first index",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      ignore AU.insertAtPostionAndDeleteAtPosition(array, ?60, 4, 0);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?20, ?30, ?40, ?50, ?60]
    ))
  ),
  S.test("if insertion index < deletion index, returns correct value of deleted index",
    AU.insertAtPostionAndDeleteAtPosition([var ?10, ?20, ?30, ?40, ?50], ?15, 1, 3),
    M.equals(T.nat(40))
  ),
  S.test("if insertion index < deletion index",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      ignore AU.insertAtPostionAndDeleteAtPosition(array, ?15, 1, 3);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?10, ?15, ?20, ?30, ?50]
    ))
  ),
  S.test("if insertion index > deletion index, returns correct value of deleted index",
    AU.insertAtPostionAndDeleteAtPosition([var ?10, ?20, ?30, ?40, ?50], ?15, 3, 1),
    M.equals(T.nat(20))
  ),
  S.test("if insertion index > deletion index",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      ignore AU.insertAtPostionAndDeleteAtPosition(array, ?45, 3, 1);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?10, ?30, ?40, ?45, ?50]
    ))
  ),
  S.test("if insertion index == deletion index, returns correct value of deleted index",
    AU.insertAtPostionAndDeleteAtPosition([var ?10, ?20, ?30, ?40, ?50], ?25, 2, 2),
    M.equals(T.nat(30))
  ),
  S.test("if insertion index == deletion index",
    do {
      let array = [var ?10, ?20, ?30, ?40, ?50];
      ignore AU.insertAtPostionAndDeleteAtPosition(array, ?25, 2, 2);
      array
    },
    M.equals(AUM.varArray<?Nat>(
      T.optionalTestable<Nat>(T.natTestable),
      [var ?10, ?20, ?25, ?40, ?50]
    ))
  ),
]);


let mergeParentWithChildrenAndDeleteSuite = S.suite("mergeParentWithChildrenAndDeleteSuite", [
  S.suite("if left deletion side", [
    S.test("if deleteIndex is 0",
      AU.mergeParentWithChildrenAndDelete<Nat>(
        ?10,
        3,
        [var ?2, ?5, ?8, null, null, null],
        [var ?15, ?20, ?30, null, null, null],
        0,
        #left
      ),
      M.equals(T.tuple2<[var ?Nat], Nat>(
        AUM.varArrayTestable<?Nat>(
          T.optionalTestable<Nat>(T.natTestable)
        ),
        T.natTestable,
        ([var ?5, ?8, ?10, ?15, ?20, ?30], 2)
      ))
    ),
    S.test("if deleteIndex is in the middle",
      AU.mergeParentWithChildrenAndDelete<Nat>(
        ?10,
        3,
        [var ?2, ?5, ?8, null, null, null],
        [var ?15, ?20, ?30, null, null, null],
        1,
        #left
      ),
      M.equals(T.tuple2<[var ?Nat], Nat>(
        AUM.varArrayTestable<?Nat>(
          T.optionalTestable<Nat>(T.natTestable)
        ),
        T.natTestable,
        ([var ?2, ?8, ?10, ?15, ?20, ?30], 5)
      ))
    ),
    S.test("if deleteIndex is at the end",
      AU.mergeParentWithChildrenAndDelete<Nat>(
        ?10,
        3,
        [var ?2, ?5, ?8, null, null, null],
        [var ?15, ?20, ?30, null, null, null],
        2,
        #left
      ),
      M.equals(T.tuple2<[var ?Nat], Nat>(
        AUM.varArrayTestable<?Nat>(
          T.optionalTestable<Nat>(T.natTestable)
        ),
        T.natTestable,
        ([var ?2, ?5, ?10, ?15, ?20, ?30], 8)
      ))
    )
  ]),
  S.suite("if right deletion side", [
    S.test("if deleteIndex is 0",
      AU.mergeParentWithChildrenAndDelete<Nat>(
        ?10,
        3,
        [var ?2, ?5, ?8, null, null, null],
        [var ?15, ?20, ?30, null, null, null],
        0,
        #right
      ),
      M.equals(T.tuple2<[var ?Nat], Nat>(
        AUM.varArrayTestable<?Nat>(
          T.optionalTestable<Nat>(T.natTestable)
        ),
        T.natTestable,
        ([var ?2, ?5, ?8, ?10, ?20, ?30], 15)
      ))
    ),
    S.test("if deleteIndex is in the middle",
      AU.mergeParentWithChildrenAndDelete<Nat>(
        ?10,
        3,
        [var ?2, ?5, ?8, null, null, null],
        [var ?15, ?20, ?30, null, null, null],
        1,
        #right
      ),
      M.equals(T.tuple2<[var ?Nat], Nat>(
        AUM.varArrayTestable<?Nat>(
          T.optionalTestable<Nat>(T.natTestable)
        ),
        T.natTestable,
        ([var ?2, ?5, ?8, ?10, ?15, ?30], 20)
      ))
    ),
    S.test("if deleteIndex is at the end",
      AU.mergeParentWithChildrenAndDelete<Nat>(
        ?10,
        3,
        [var ?2, ?5, ?8, null, null, null],
        [var ?15, ?20, ?30, null, null, null],
        2,
        #right
      ),
      M.equals(T.tuple2<[var ?Nat], Nat>(
        AUM.varArrayTestable<?Nat>(
          T.optionalTestable<Nat>(T.natTestable)
        ),
        T.natTestable,
        ([var ?2, ?5, ?8, ?10, ?15, ?20], 30)
      ))
    )
  ])
]);


S.run(S.suite("ArrayUtil",
  [
    insertAtPositionSuite,
    insertOneAtIndexAndSplitArraySuite,
    insertTwoAtIndexAndSplitArraySuite,
    deleteAndShiftValuesOverSuite,
    replaceTwoWithElementAndShiftSuite,
    insertAtPositionAndDeleteAtPositionSuite,
    mergeParentWithChildrenAndDeleteSuite,
  ] 
));