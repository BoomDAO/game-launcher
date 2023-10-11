import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Char "mo:base/Char";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";

import World "world";
import Helper "../utils/Helpers";
import Management "../types/management.types";

actor Deployer {

    //Stable Memory
    private func deployer() : Principal = Principal.fromActor(Deployer);
    private stable var _worlds : Trie.Trie<Text, World> = Trie.empty(); //mapping of world_canister_id -> World details
    private stable var _covers : Trie.Trie<Text, Text> = Trie.empty(); //mapping of world_canister_id -> base64
    private stable var _owners : Trie.Trie<Text, Text> = Trie.empty(); //mapping  world_canister_id -> owner principal id
    private stable var _admins : [Text] = [];

    let IC : Management.Management = actor ("aaaaa-aa") ;     //IC Management Canister

    //Types
    public type World = {
        name : Text;
        cover : Text;
        canister : Text;
        // version : Text;
    };
    public type Wasm = {
        nextVersion : Text;
        wasmModule : [Nat8];
        createdAt : Int;
    };

    //Internal Functions
    //
    private func _isAdmin(p : Text) : (Bool) {
        for (i in _admins.vals()) {
            if (i == p) {
                return true;
            };
        };
        return false;
    };

    private func _isOwner(p : Principal, canister_id : Text) : async (Bool) {
        for ((i, v) in Trie.iter(_owners)) {
            if (canister_id == i and p == Principal.fromText(v)) {
                return true;
            };
        };
        return false;
    };

    private func create_canister(_owner : Principal) : async (Text) {
        Cycles.add(1000000000000);
        let canister = await World.WorldTemplate(_owner);
        let _ = await updateCanister(canister, _owner);
        let canister_id = Principal.fromActor(canister);
        return Principal.toText(canister_id);
    };

    private func updateCanister(a : actor {}, init_owner : Principal) : async () {
        let cid = { canister_id = Principal.fromActor(a) };
        await (
            IC.update_settings({
                canister_id = cid.canister_id;
                settings = {
                    controllers = ?[init_owner, deployer()];
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            })
        );
    };

    private func _isController(collection_canister_id : Text, p : Principal) : async (Bool) {
        var status : {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : Management.definite_canister_settings;
            module_hash : ?[Nat8];
        } = await IC.canister_status({
            canister_id = Principal.fromText(collection_canister_id);
        });
        var controllers : [Principal] = status.settings.controllers;
        for (i in controllers.vals()) {
            if (i == p) {
                return true;
            };
        };
        return false;
    };

    //Queries
    //
    public query func getAllAdmins() : async ([Text]) {
        return _admins;
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    public query func getOwner(canister_id : Text) : async (?Text) {
        var owner : ?Text = Trie.find(_owners, Helper.keyT(canister_id), Text.equal);
        return owner;
    };

    public query func getUserTotalWorlds(uid : Text) : async (Nat) {
        var size = 0;
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                size := size + 1;
            };
        };
        return size;
    };

    public query func getUserWorlds(uid : Text, _page : Nat) : async ([World]) {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var b : Buffer.Buffer<World> = Buffer.Buffer<World>(0);
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                switch (Trie.find(_worlds, Helper.keyT(i), Text.equal)) {
                    case (?t) {
                        b.add(t);
                    };
                    case _ {};
                };
            };
        };
        let arr = Buffer.toArray(b);
        b := Buffer.Buffer<World>(0);
        let size = arr.size();
        if (upper > size) {
            upper := size;
        };
        while (lower < upper) {
            b.add(arr[lower]);
            lower := lower + 1;
        };
        return Buffer.toArray(b);
    };

    public query func getWorlds(_page : Nat) : async ([World]) {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var b : Buffer.Buffer<World> = Buffer.Buffer<World>(0);
        for ((i, v) in Trie.iter(_owners)) {
            switch (Trie.find(_worlds, Helper.keyT(i), Text.equal)) {
                case (?t) {
                    b.add(t);
                };
                case _ {};
            };
        };
        let arr = Buffer.toArray(b);
        b := Buffer.Buffer<World>(0);
        let size = arr.size();
        if (upper > size) {
            upper := size;
        };
        while (lower < upper) {
            b.add(arr[lower]);
            lower := lower + 1;
        };
        return Buffer.toArray(b);
    };

    public query func getTotalWorlds() : async (Nat) {
        return Trie.size(_worlds);
    };

    public query func getWorldDetails(canister_id : Text) : async (?World) {
        switch (Trie.find(_worlds, Helper.keyT(canister_id), Text.equal)) {
            case (?w) {
                return ?w;
            };
            case _ {
                return null;
            };
        };
    };

    public query func getWorldCover(canister_id : Text) : async (Text) {
        switch (Trie.find(_covers, Helper.keyT(canister_id), Text.equal)) {
            case (?c){
                return c;
            };
            case _ {
                return "";
            };
        };
    };

    public query func getAllWorlds() : async [(Text, Text)] {
        var b : Buffer.Buffer<(Text, Text)> = Buffer.Buffer<(Text, Text)>(0);
        for ((i, v) in Trie.iter(_worlds)) {
            b.add((i, v.name));
        };
        return Buffer.toArray(b);
    };

    //Updates
    //
    public shared ({ caller }) func addAdmin(p : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in _admins.vals()) {
            if (p != i) {
                b.add(i);
            };
        };
        b.add(p);
        _admins := Buffer.toArray(b);
    };

    public shared ({ caller }) func removeAdmin(p : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in _admins.vals()) {
            if (p != i) {
                b.add(i);
            };
        };
        _admins := Buffer.toArray(b);
    };

    public shared ({ caller }) func addController(collection_canister_id : Text, p : Text) : async () {
        var check : Bool = await _isController(collection_canister_id, caller);
        if (check == false) {
            return ();
        };
        var status : {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : Management.definite_canister_settings;
            module_hash : ?[Nat8];
        } = await IC.canister_status({
            canister_id = Principal.fromText(collection_canister_id);
        });
        var controllers : [Principal] = status.settings.controllers;
        var b : Buffer.Buffer<Principal> = Buffer.Buffer<Principal>(0);
        for (i in controllers.vals()) {
            if (i != Principal.fromText(p)) b.add(i);
        };
        b.add(Principal.fromText(p));
        await (
            IC.update_settings({
                canister_id = Principal.fromText(collection_canister_id);
                settings = {
                    controllers = ?Buffer.toArray(b);
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            })
        );
    };

    public shared ({ caller }) func removeController(collection_canister_id : Text, p : Text) : async () {
        var check : Bool = await _isController(collection_canister_id, caller);
        if (check == false) {
            return ();
        };
        var status : {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : Management.definite_canister_settings;
            module_hash : ?[Nat8];
        } = await IC.canister_status({
            canister_id = Principal.fromText(collection_canister_id);
        });
        var controllers : [Principal] = status.settings.controllers;
        var b : Buffer.Buffer<Principal> = Buffer.Buffer<Principal>(0);
        for (i in controllers.vals()) {
            if (i != Principal.fromText(p)) b.add(i);
        };
        await (
            IC.update_settings({
                canister_id = Principal.fromText(collection_canister_id);
                settings = {
                    controllers = ?Buffer.toArray(b);
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            })
        );
    };

    public shared (msg) func createWorldCanister(_name : Text, cover_encoding : Text) : async (Text) {
        var canister_id : Text = await create_canister(msg.caller);
        _worlds := Trie.put(
            _worlds,
            Helper.keyT(canister_id),
            Text.equal,
            {
                name = _name;
                canister = canister_id;
                cover = "https://" #Principal.toText(deployer()) #".raw.icp0.io/cover/" #canister_id;
                // version = _latestVersion; 
            },
        ).0;
        _covers := Trie.put(_covers, Helper.keyT(canister_id), Text.equal, cover_encoding).0;
        _owners := Trie.put(_owners, Helper.keyT(canister_id), Text.equal, Principal.toText(msg.caller)).0;
        return canister_id;
    };

    public shared ({caller}) func upgradeWorldToNewWasm(canister_id : Text, owner : Blob, _wasm_module : [Nat8]) : async () {
        assert ((await _isOwner(caller, canister_id)) == true);
        await IC.install_code({
            arg = owner;
            wasm_module = Blob.fromArray(_wasm_module);
            mode = #reinstall;
            canister_id = Principal.fromText(canister_id);
        });
    };

    public shared (msg) func updateWorldCover(canister_id : Text, base64 : Text) : async (Result.Result<(), Text>) {
        assert ((await _isOwner(msg.caller, canister_id)) == true);
        switch (Trie.find(_owners, Helper.keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                _covers := Trie.put(_covers, Helper.keyT(canister_id), Text.equal, base64).0;
                return #ok();
            };
            case null {
                return #err("canister owner not found");
            };
        };
    };

    // http request handler
    public query func http_request(req : Management.HttpRequest) : async (Management.HttpResponse) {
        let path = Iter.toArray(Text.tokens(req.url, #text("/")));
        let collection = path[1];
        switch (req.method, (path[0] == "cover")) {
            case ("GET", true) {
                switch (Trie.find(_covers, Helper.keyT(collection), Text.equal)) {
                    case (?c) {
                        var content : Text = "<!DOCTYPE html><html lang=\"en\"><head><title>Cover</title></head><body><div style=\"text-align:center; margin-top:10vh\"><img src=\"" #c # "\" style=\"width:200px\"></img></div></body></html>";
                        return {
                            body = Text.encodeUtf8(content);
                            headers = [("content-type", "text/html")];
                            status_code = 200;
                        };
                    };
                    case _ {
                        return {
                            body = Text.encodeUtf8("not found");
                            headers = [("content-type", "text/plain")];
                            status_code = 500;
                        };
                    };
                };
            };
            case _ {
                return {
                    body = Text.encodeUtf8("invalid request");
                    headers = [];
                    status_code = 404;
                };
            };
        };
    };

    // state-management and wasm-management
    private stable var _latestVersion : Text = "";
    private stable var _wasms : Trie.Trie<Text, Wasm> = Trie.empty();

    public shared({caller}) func updateWasmModule(req : { version : Text; wasmModule : [Nat8]; }) : async (Result.Result<(), Text>) {
        // assert(caller == Principal.fromText("2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe"));
        switch (Trie.find(_wasms, Helper.keyT(_latestVersion), Text.equal)) {
            case (?w) {
                _wasms := Trie.put(_wasms, Helper.keyT(_latestVersion), Text.equal, {
                    nextVersion = req.version;
                    wasmModule = w.wasmModule;
                    createdAt = w.createdAt;
                }).0;
                _wasms := Trie.put(_wasms, Helper.keyT(req.version), Text.equal, {
                    nextVersion = "Latest";
                    wasmModule = req.wasmModule;
                    createdAt = Time.now();
                }).0;
                _latestVersion := req.version;
                return #ok();
            };
            case _ {
                return #err("latest wasm version not found");
            };
        };
    } ;

    private stable var _oldWorlds : Trie.Trie<Text, World> = Trie.empty();
    system func preupgrade() : () {
        for((i, v) in Trie.iter(_worlds)) {
            _oldWorlds := Trie.put(_oldWorlds, Helper.keyT(i), Text.equal, {
                name = v.name;
                cover = v.cover;
                canister = v.canister;
                version = "1.0.2";
            }).0;
        };
    };

    system func postupgrade() : () {
        _worlds := _oldWorlds;
        _oldWorlds := Trie.empty();
    };

    public query func getWorldVersion() : async (Text) {
        return _latestVersion;
    };



};


// irfpf-tqaaa-aaaal-qcemq-cai
