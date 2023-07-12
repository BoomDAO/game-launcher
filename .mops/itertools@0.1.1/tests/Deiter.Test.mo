import Debug "mo:base/Debug";
import Deque "mo:base/Deque";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import Deiter "../src/Deiter";
import Itertools "../src/Iter";

import DequeUtils "../src/Utils/Deque";

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
        "Double Ended Iter",
        [
            it(
                "fromArray",
                do {
                    let arr = [1, 2, 3, 4, 5];
                    let deiter = Deiter.fromArray<Nat>(arr);

                    assertAllTrue([
                        deiter.next() == ?1,
                        deiter.next() == ?2,
                        deiter.next_back() == ?5,
                        deiter.next_back() == ?4,
                        deiter.next() == ?3,
                        deiter.next_back() == null,
                        deiter.next() == null,
                    ]);
                },
            ),
            it(
                "fromArrayMut",
                do {
                    let arr = [var 1, 2, 3, 4, 5];
                    let deiter = Deiter.fromArrayMut<Nat>(arr);

                    assertAllTrue([
                        deiter.next() == ?1,
                        deiter.next() == ?2,
                        deiter.next_back() == ?5,
                        deiter.next_back() == ?4,
                        deiter.next() == ?3,
                        deiter.next_back() == null,
                        deiter.next() == null,
                    ]);
                },
            ),
            it(
                "fromDeque",
                do {
                    let deque = DequeUtils.fromArray([1, 2, 3, 4, 5]);
                    let deiter = Deiter.fromDeque<Nat>(deque);

                    assertAllTrue([
                        deiter.next() == ?1,
                        deiter.next() == ?2,
                        deiter.next_back() == ?5,
                        deiter.next_back() == ?4,
                        deiter.next() == ?3,
                        deiter.next_back() == null,
                        deiter.next() == null,
                    ]);
                },
            ),
            it(
                "reverse",
                do {
                    let deque = DequeUtils.fromArray([1, 2, 3, 4, 5]);
                    let deiter = Deiter.fromDeque<Nat>(deque);
                    let revIter = Deiter.reverse(deiter);

                    assertAllTrue([
                        revIter.next() == ?5,
                        revIter.next() == ?4,
                        revIter.next_back() == ?1,
                        revIter.next_back() == ?2,
                        revIter.next() == ?3,
                        revIter.next_back() == null,
                        revIter.next() == null,
                    ]);
                },
            ),
            it(
                "reverse chunks",
                do {
                    let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

                    let deiter = Deiter.fromArray(arr);
                    let revDeiter = Deiter.reverse(deiter);
                    let chunks = Itertools.chunks(revDeiter, 3);

                    assertAllTrue([
                        chunks.next() == ?[10, 9, 8],
                        chunks.next() == ?[7, 6, 5],
                        chunks.next() == ?[4, 3, 2],
                        chunks.next() == ?[1],
                        chunks.next() == null,
                    ])

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
