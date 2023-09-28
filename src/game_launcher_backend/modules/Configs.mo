import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import RandomUtil "../utils/RandomUtil";
import Utils "../utils/Utils";
import Int "mo:base/Int";

import ENV "../utils/Env";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

import ActionTypes "../types/action.types";
import EntityTypes "../types/entity.types";

module{

    public type StableConfigs = [EntityTypes.StableConfig]; 
    public type Actions = [ActionTypes.Action]; 
    
    public let configs : StableConfigs = [];
    public let action : Actions = [];
}