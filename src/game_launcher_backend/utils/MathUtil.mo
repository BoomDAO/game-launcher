import Float "mo:base/Float";

module MathUtil {

    public query func fixDecimal(value :Float, decimal_count : Nat){
        let ten_based_factor = Float.exp(10, decimal_count);

        return Float.floor(value *ten_based_factor ) / ten_based_factor;
    };
}