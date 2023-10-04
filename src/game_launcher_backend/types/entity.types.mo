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
import Map "../utils/Map";

import TGlobal "./global.types";

module {

    public type Entity = {
        wid : TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        fields : Map.Map<Text, Text>;
    };

    public type StableEntity = {
        wid : TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        fields : [(Text, Text)];
    };

    public type Config = {
        cid : TGlobal.configId;
        fields : Map.Map<Text, Text>;
    };

    public type StableConfig = {
        cid : TGlobal.configId;
        fields : [(Text, Text)];
    };

    public type EntityPermission = {
        wid : TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
    };

    public type GlobalPermission = {
        wid : TGlobal.worldId;
    };
};
