
import Random "mo:base/Random";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Utils "../utils/Utils";

module RandomUtil {

    public func get_random_perc() : async (Float){
        let seed : Blob = await Random.blob();
        let rand : Nat = Random.rangeFrom(32, seed);
        let max : Float = 4294967295;
        let value : Float = Float.div(Float.fromInt(rand), max);
        return value;
    };

    public func get_random_float(max : Nat) : async (Float){
        var value =  await get_random_perc();
        value *= Float.fromInt(max);
        return value;
    };
    public func get_random_int(max : Nat) : async (Int){
        var value =  await get_random_perc();
        value *= Float.fromInt(max);
        return Float.toInt(value);
    };
    public func get_random_nat(max : Nat) : async (Nat){
        var value =  await get_random_perc();
        value *= Float.fromInt(max);
        return Utils.textToNat(Int.toText(Float.toInt(value)));
    };
}