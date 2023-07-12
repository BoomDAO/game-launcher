import Int "mo:base/Int";
module{
    public func factorial(n: Nat) : Nat {
        if (n == 0){
            1
        } else {
            n * factorial(Int.abs(n - 1))
        }
    };
};
