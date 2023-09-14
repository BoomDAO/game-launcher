import HM "mo:base/HashMap";
import Text "mo:base/Text";
import Matchers "../src/Matchers";
import HMMatchers "../src/matchers/Hashmap";
import T "../src/Testable";
import Suite "../src/Suite";

let equals10 = Matchers.equals(T.nat(10));
let equals20 = Matchers.equals(T.nat(20));
let greaterThan10 : Matchers.Matcher<Nat> = Matchers.greaterThan(10);
let greaterThan20 : Matchers.Matcher<Nat> = Matchers.greaterThan(20);
let map : HM.HashMap<Text, Nat> = HM.HashMap<Text, Nat>(5, Text.equal, Text.hash);
map.put("key1", 20);
map.put("key2", 10);

func shouldFailWith<A>(matcher : Matchers.Matcher<A>, message : Text) : Matchers.Matcher<A> {
    return {
        matches = func(item : A) : Bool {
            if (matcher.matches(item)) {
                return false;
            };

            let description = Matchers.Description();
            matcher.describeMismatch(item, description);
            return description.toText() == message;
        };
        describeMismatch = func(item : A, description : Matchers.Description) {
            if (matcher.matches(item)) {
                description.appendText("Should've failed, but passed instead");
                return;
            };

            let actualDescription = Matchers.Description();
            matcher.describeMismatch(item, actualDescription);

            description.appendText("Should've failed with \"");
            description.appendText(message);
            description.appendText("\" but failed with \"");
            description.appendText(actualDescription.toText());
            description.appendText("\" instead");
        };
    };
};

let suite = Suite.suite(
    "Testing the testing",
    [
        Suite.suite(
            "equality",
            [
                Suite.test("nats1", 10, equals10),
                Suite.test("nats2", 20, shouldFailWith(equals10, "20 was expected to be 10")),
                Suite.test(
                    "Chars",
                    'a',
                    shouldFailWith(Matchers.equals(T.char('b')), "'a' was expected to be 'b'"),
                ),
            ],
        ),
        Suite.testLazy("Lazy test execution", func() : Nat = 20, shouldFailWith(equals10, "20 was expected to be 10")),
        Suite.test(
            "Described as",
            20,
            shouldFailWith(
                Matchers.describedAs("20's a lot mate.", equals10),
                "20's a lot mate.",
            ),
        ),
        Suite.suite(
            "Combining matchers",
            [
                Suite.test("anything", 10, Matchers.anything<Nat>()),

                Suite.test("anyOf1", 20, Matchers.anyOf([equals10, equals20])),
                Suite.test(
                    "anyOf2",
                    15,
                    shouldFailWith(Matchers.anyOf([equals10, equals20]), "15 was expected to be 10\nor 15 was expected to be 20"),
                ),

                Suite.test("allOf1", 30, Matchers.allOf([greaterThan10, greaterThan20])),
                Suite.test(
                    "allOf2",
                    15,
                    shouldFailWith(
                        Matchers.allOf([greaterThan10, greaterThan20]),
                        "20 was expected to be greater than 15",
                    ),
                ),
                Suite.test(
                    "allOf2",
                    8,
                    shouldFailWith(
                        Matchers.allOf([greaterThan10, greaterThan20]),
                        "10 was expected to be greater than 8\nand 20 was expected to be greater than 8",
                    ),
                ),
            ],
        ),

        Suite.suite(
            "Comparing numbers",
            [
                Suite.test("greaterThan1", 20, greaterThan10),
                Suite.test(
                    "greaterThan2",
                    5,
                    shouldFailWith(greaterThan10, "10 was expected to be greater than 5"),
                ),
            ],
        ),
        Suite.suite(
            "Array matchers",
            [
                Suite.test("Should match", [10, 20], Matchers.array([equals10, equals20])),
                Suite.test(
                    "Should fail",
                    [20, 10],
                    shouldFailWith(
                        Matchers.array([equals10, equals20]),
                        "At index 0: 20 was expected to be 10\nAt index 1: 10 was expected to be 20\n",
                    ),
                ),
                Suite.test(
                    "Length mismatch",
                    ([] : [Nat]),
                    shouldFailWith(Matchers.array([equals10, equals20]), "Length mismatch between 0 items and 2 matchers"),
                ),
            ],
        ),

        Suite.suite(
            "Hashmap matchers",
            [
                Suite.test("Should have key", map, HMMatchers.hasKey<Text, Nat>(T.text("key1"))),
                Suite.test(
                    "Should fail with missing key",
                    map,
                    shouldFailWith(
                        HMMatchers.hasKey<Text, Nat>(T.text("unknown")),
                        "Missing key \"unknown\"",
                    ),
                ),
                Suite.test("Should match at key", map, HMMatchers.atKey<Text, Nat>(T.text("key1"), equals20)),
                Suite.test(
                    "should fail at key",
                    map,
                    shouldFailWith(HMMatchers.atKey<Text, Nat>(T.text("key2"), equals20), "10 was expected to be 20"),
                ),
                Suite.test(
                    "Should fail with missing key2",
                    map,
                    shouldFailWith(
                        HMMatchers.atKey<Text, Nat>(T.text("unknown"), equals20),
                        "Missing key \"unknown\"",
                    ),
                ),
            ],
        ),
    ],
);

Suite.run(suite);
