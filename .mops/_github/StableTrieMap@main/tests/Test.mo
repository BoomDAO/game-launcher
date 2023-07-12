import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import ActorSpec "./utils/ActorSpec";
import STM "../src/";

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
        "StableTrieMap Tests",
        [
            it(
                "new()",
                do {
                    let map : STM.StableTrieMap<Text, Nat> = STM.new();

                    assertAllTrue([
                        STM.size(map) == 0,
                        STM.remove(map, Text.equal, Text.hash, "apple") == null,
                        STM.size(map) == 0,
                    ]);
                },
            ),

            it(
                "put()",
                do {
                    let map : STM.StableTrieMap<Text, Nat> = STM.new();

                    STM.put(map, Text.equal, Text.hash, "apple", 1);

                    assertAllTrue([
                        STM.size(map) == 1,
                        STM.remove(map, Text.equal, Text.hash, "apple") == ?1,
                        STM.size(map) == 0,
                    ]);
                },
            ),
            it(
                "get()",
                do {
                    let map : STM.StableTrieMap<Text, Nat> = STM.new();

                    STM.put(map, Text.equal, Text.hash, "apple", 1);
                    STM.put(map, Text.equal, Text.hash, "banana", 2);
                    STM.put(map, Text.equal, Text.hash, "pear", 3);

                    assertAllTrue([
                        STM.get(map, Text.equal, Text.hash, "apple") == ?1,
                        STM.get(map, Text.equal, Text.hash, "banana") == ?2,
                        STM.replace(map, Text.equal, Text.hash, "apple", 1111) == ?1,
                        STM.replace(map, Text.equal, Text.hash, "banana", 2222) == ?2,
                        STM.get(map, Text.equal, Text.hash, "apple") == ?1111,
                        STM.get(map, Text.equal, Text.hash, "banana") == ?2222,
                        STM.remove(map, Text.equal, Text.hash, "apple") == ?1111,
                        STM.get(map, Text.equal, Text.hash, "apple") == null,
                    ]);
                },
            ),
            it(
                "entries()",
                do {
                    let map : STM.StableTrieMap<Text, Nat> = STM.new();

                    STM.put(map, Text.equal, Text.hash, "apple", 1);
                    STM.put(map, Text.equal, Text.hash, "banana", 2);
                    STM.put(map, Text.equal, Text.hash, "pear", 3);

                    assertAllTrue([
                        STM.size(map) == 3,
                        Iter.toArray(STM.entries(map)) == [
                            ("apple", 1),
                            ("banana", 2),
                            ("pear", 3),
                        ],
                    ]);
                },
            ),

            it(
                "fromEntries()",
                do {
                    let entries : [(Text, Nat)] = [
                        ("apple", 1),
                        ("banana", 2),
                        ("pear", 3),
                        ("avocado", 4),
                        ("Apple", 11),
                        ("Banana", 22),
                        ("Pear", 33),
                    ];

                    let map = STM.fromEntries<Text, Nat>(entries.vals(), Text.equal, Text.hash);

                    assertAllTrue([
                        STM.size(map) == 7,
                        STM.get(map, Text.equal, Text.hash, "Apple") == ?11,
                        Iter.toArray(STM.entries(map)) == entries,
                    ]);
                },
            ),

            it(
                "clone",
                do {
                    let entries : [(Text, Nat)] = [
                        ("apple", 1),
                        ("banana", 2),
                        ("pear", 3),
                        ("avocado", 4),
                        ("Apple", 11),
                        ("Banana", 22),
                        ("Pear", 33),
                    ];

                    let a = STM.fromEntries<Text, Nat>(entries.vals(), Text.equal, Text.hash);

                    let b = STM.clone<Text, Nat>(a, Text.equal, Text.hash);

                    assertAllTrue([
                        STM.size(a) == STM.size(b),
                        Iter.toArray(STM.entries(a)) == Iter.toArray(STM.entries(b)),
                    ]);
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
