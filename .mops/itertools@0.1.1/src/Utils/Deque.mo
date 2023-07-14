import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";

module DequeUtils {
    public func toArray<A>(dq : Deque.Deque<A>) : [A] {
        var deque = dq;
        var buffer = Buffer.Buffer<A>(0);

        label l loop {
            if (Deque.isEmpty(deque)) {
                break l;
            };

            switch (Deque.popFront(deque)) {
                case (?(x, xs)) {
                    deque := xs;
                    buffer.add(x);
                };
                case (_) {
                    break l;
                };
            };
        };

        return Buffer.toArray(buffer);
    };

    public func fromArray<A>(array : [A]) : Deque.Deque<A> {
        var deque = Deque.empty<A>();

        for (elem in array.vals()) {
            deque := Deque.pushBack<A>(deque, elem);
        };

        return deque;
    };
};
