//MADE BY JACK ANTON - (ItsJackAnton in Twitter, Distrik and Discover)

import Utils "../utils/Utils";

import Random "mo:base/Random";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";

module RandomExt {

    public func getRandomPerc() : async (Float){
        let seed : Blob = await Random.blob();
        let rand : Nat = Random.rangeFrom(32, seed);
        let max : Float = 4294967295;
        let value : Float = Float.div(Float.fromInt(rand), max);
        return value;
    };
    public func getRandomFloat(max : Nat) : async (Float){
        var value =  await getRandomPerc();
        value *= Float.fromInt(max);
        return value;
    };
    public func getRandomInt(max : Nat) : async (Int){
        var value =  await getRandomPerc();
        value *= Float.fromInt(max);
        return Float.toInt(value);
    };
    public func getRandomNat(max : Nat) : async (Nat){
        var value =  await getRandomPerc();
        value *= Float.fromInt(max);
        return Utils.textToNat(Int.toText(Float.toInt(value)));
    };

    //Linear Congruential Generator
    //You dont need to await on this to generate a random number
    //This will always generate the same patern of "random numbers"
    //A way around of making this less deterministic is by generating
    //a true random number with "getRandomNat" only once and use it has
    //seed modifier (seedMod) whenever you call "gen" or "genAsPerc"
    //this will ensure that the pattern the "RandomLCG" makes is unique to the seedMod you use
    //at the end this is always deterministic, but for someone to determine your pattern would need
    //to know the seedMod you are using when calling "gen" or "genAsPerc"
    public class RandomLCG(){
        var mod = 2310;
        let mul = 378;
        let increment = 7829;
        var seed = 4321;
        
        //seed modifier
        public func gen(seedMod : Nat) : (Nat) {
            seed := (seed * mul + increment) % mod;

            return seed;
        };

        public func genAsPerc(seedMod : Nat) : (Float) {
            return Float.fromInt(gen(seedMod)) / Float.fromInt(mod)
        }
    };
}