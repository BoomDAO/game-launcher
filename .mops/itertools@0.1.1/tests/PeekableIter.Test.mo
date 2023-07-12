import Debug "mo:base/Debug";
import Deque "mo:base/Deque";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import PeekableIter "../src/PeekableIter";

let {
    assertTrue; assertFalse; assertAllTrue; describe; it; skip; pending; run
} = ActorSpec;

let success = run([
    describe("PeekableIter", [
        it("fromIter", do {
            let vals = [1, 2, 3].vals();
            let peekable = PeekableIter.fromIter<Nat>(vals);

            assertAllTrue([
                peekable.peek() == ?1,
                peekable.next() == ?1,
    
                peekable.peek() == ?2,
                peekable.peek() == ?2,
                peekable.next() == ?2,

                peekable.peek() == ?3,
                peekable.next() == ?3,

                peekable.peek() == null,
                peekable.next() == null,
            ])
        }),
    ]),
]);

if(success == false){
  Debug.trap("\1b[46;41mTests failed\1b[0m");
}else{
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
