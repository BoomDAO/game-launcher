import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Char "mo:base/Char";
import Error "mo:base/Error";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import L "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";

module {
    public type ICPStake = {
    amount : Nat64;
    dissolveAt : Int;
    isDissolved : Bool;
    };
    public type ICRCStake = {
    amount : Nat;
    dissolveAt : Int;
    isDissolved : Bool;
    };
    public type EXTStake = {
    staker : Text; //principal
    tokenIndex : Nat32;
    dissolveAt : Int;
    isDissolved : Bool;
    };
    public type Stake = {
    canister_id : Text;
    token_type : Text;
    amount : Nat;
    index : ?Text;
    dissolveAt : Int;
    isDissolved : Bool;
    };
}