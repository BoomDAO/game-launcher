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

import Asset "./Asset/main.asset";

actor Deployer {

    //Stable Memory
    //
    private stable var _games : Trie.Trie<Text, Game> = Trie.empty(); //mapping of canister_id -> Game Info
    private stable var _covers : Trie.Trie<Text, Text> = Trie.empty(); //mapping of game_canister_id -> base64
    private stable var _owners : Trie.Trie<Text, Text> = Trie.empty(); //mapping asset canister_id -> owner principal id
    private stable var _admins : [Text] = []; //admins of deployer canister

    //IC-Management canister records
    //
    type canister_id = Principal;
    type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : [Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
    };
    type user_id = Principal;
    type wasm_module = Blob;
    type headerField = (Text, Text);
    type HttpRequest = {
        body : Blob;
        headers : [headerField];
        method : Text;
        url : Text;
    };
    type HttpResponse = {
        body : Blob;
        headers : [headerField];
        status_code : Nat16;
    };

    //Game Info record
    //
    type Game = {
        name : Text;
        description : Text;
        platform : Text;
        canister_id : Text;
        url : Text;
        cover : Text;
        lastUpdated : Int;
        verified : Bool;
    };

    //IC Management Canister Interface
    //
    let IC = actor ("aaaaa-aa") : actor {
        canister_status : shared { canister_id : canister_id } -> async {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : definite_canister_settings;
            module_hash : ?[Nat8];
        };
        create_canister : shared { settings : ?canister_settings } -> async {
            canister_id : canister_id;
        };
        delete_canister : shared { canister_id : canister_id } -> async ();
        deposit_cycles : shared { canister_id : canister_id } -> async ();
        install_code : shared {
            arg : Blob;
            wasm_module : wasm_module;
            mode : { #reinstall; #upgrade; #install };
            canister_id : canister_id;
        } -> async ();
        provisional_create_canister_with_cycles : shared {
            settings : ?canister_settings;
            amount : ?Nat;
        } -> async { canister_id : canister_id };
        provisional_top_up_canister : shared {
            canister_id : canister_id;
            amount : Nat;
        } -> async ();
        raw_rand : shared () -> async [Nat8];
        start_canister : shared { canister_id : canister_id } -> async ();
        stop_canister : shared { canister_id : canister_id } -> async ();
        uninstall_code : shared { canister_id : canister_id } -> async ();
        update_settings : shared {
            canister_id : Principal;
            settings : canister_settings;
        } -> async ();
    };

    //internals
    //
    //to sort trie values
    private func _sort(t : Trie.Trie<Text, Game>) : [Game] {
        var trie : Trie.Trie<Text, Game> = Trie.empty();
        var b : Buffer.Buffer<Int> = Buffer.Buffer<Int>(0);
        var _b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        for ((i, g) in Trie.iter(t)) {
            trie := Trie.put(trie, keyT(Int.toText(g.lastUpdated)), Text.equal, g).0;
            b.add(g.lastUpdated);
        };
        var a : [Int] = Buffer.toArray(b);
        a := Array.sort(a, Int.compare);
        a := Array.reverse(a);
        for (i in a.vals()) {
            switch (Trie.find(trie, keyT(Int.toText(i)), Text.equal)) {
                case (?g) {
                    _b.add(g);
                };
                case _ {};
            };
        };
        Buffer.toArray(_b);
    };

    //to generate Trie key
    private func key(x : Nat32) : Trie.Key<Nat32> {
        return { hash = x; key = x };
    };
    private func keyT(x : Text) : Trie.Key<Text> {
        return { hash = Text.hash(x); key = x };
    };

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
        Cycles.add(2000000000000);
        let canister = await Asset.Assets(_owner);
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
                    controllers = ?[init_owner];
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            })
        );
    };

    //Queries
    //
    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    public query func get_all_admins() : async ([Text]) {
        return _admins;
    };

    public query func get_total_games() : async (Nat) {
        return Trie.size(_games);
    };

    public query func get_users_total_games(uid : Text) : async (Nat) {
        var b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                switch (Trie.find(_games, keyT(i), Text.equal)) {
                    case (?g) {
                        b.add(g);
                    };
                    case _ {};
                };
            };
        };
        return b.size();
    };

    public query func get_game_owner(canister_id : Text) : async (?Text) {
        var owner : ?Text = Trie.find(_owners, keyT(canister_id), Text.equal);
        return owner;
    };

    public query func get_all_asset_canisters(_page : Nat) : async ([Game]) {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        let arr : [Game] = _sort(_games);
        let size = Trie.size(_games);
        if (upper > size) {
            upper := size;
        };
        while (lower < upper) {
            b.add(arr[lower]);
            lower := lower + 1;
        };
        return Buffer.toArray(b);
    };

    public query func get_game_cover(canister_id : Text) : async (Text) {
        switch (Trie.find(_covers, keyT(canister_id), Text.equal)) {
            case (?c) {
                return c;
            };
            case null {
                return "";
            };
        };
    };

    public query func get_user_games(uid : Text, _page : Nat) : async [Game] {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var t : Trie.Trie<Text, Game> = Trie.empty();
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                switch (Trie.find(_games, keyT(i), Text.equal)) {
                    case (?g) {
                        t := Trie.put(t, keyT(i), Text.equal, g).0;
                    };
                    case _ {};
                };
            };
        };
        var arr : [Game] = _sort(t);
        let size = Trie.size(t);
        var b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        if (upper > size) {
            upper := size;
        };
        while (lower < upper) {
            b.add(arr[lower]);
            lower := lower + 1;
        };
        return Buffer.toArray(b);
    };

    public query func get_game(canister_id : Text) : async (?Game) {
        switch (Trie.find(_games, keyT(canister_id), Text.equal)) {
            case (?g) {
                return ?g;
            };
            case _ {
                return null;
            };
        };
    };

    //Updates
    //
    public shared ({ caller }) func add_admin(p : Text) : async () {
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

    public shared ({ caller }) func remove_admin(p : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in _admins.vals()) {
            if (p != i) {
                b.add(i);
            };
        };
        _admins := Buffer.toArray(b);
    };
    
    public shared (msg) func create_game_canister(game_name : Text, data : Text, base64 : Text, _type : Text) : async (Text) {
        var canister_id : Text = await create_canister(msg.caller);
        _games := Trie.put(
            _games,
            keyT(canister_id),
            Text.equal,
            {
                name = game_name;
                description = data;
                platform = _type;
                canister_id = canister_id;
                url = "https://" #canister_id # ".raw.icp0.io/";
                cover = "https://6rvbl-uqaaa-aaaal-ab24a-cai.raw.icp0.io/cover/" #canister_id;
                lastUpdated = Time.now();
                verified = false;
            },
        ).0;
        _covers := Trie.put(_covers, keyT(canister_id), Text.equal, base64).0;
        _owners := Trie.put(_owners, keyT(canister_id), Text.equal, Principal.toText(msg.caller)).0;
        return canister_id;
    };

    //update game info
    //
    public shared (msg) func update_game_data(canister_id : Text, game_name : Text, game_data : Text, game_platform : Text) : async (Result.Result<(), Text>) {
        assert ((await _isOwner(msg.caller, canister_id)) == true);
        switch (Trie.find(_owners, keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                switch (Trie.find(_games, keyT(canister_id), Text.equal)) {
                    case (?_game) {
                        _games := Trie.put(
                            _games,
                            keyT(canister_id),
                            Text.equal,
                            {
                                name = game_name;
                                description = game_data;
                                platform = game_platform;
                                canister_id = _game.canister_id;
                                url = _game.url;
                                cover = _game.cover;
                                lastUpdated = _game.lastUpdated;
                                verified = _game.verified;
                            },
                        ).0;
                    };
                    case _ {};
                };
                return #ok();
            };
            case null {
                return #err("canister owner not found");
            };
        };
    };

    public shared (msg) func update_game_cover(canister_id : Text, base64 : Text) : async (Result.Result<(), Text>) {
        assert ((await _isOwner(msg.caller, canister_id)) == true);
        switch (Trie.find(_owners, keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                _covers := Trie.put(_covers, keyT(canister_id), Text.equal, base64).0;
                return #ok();
            };
            case null {
                return #err("canister owner not found");
            };
        };
    };

    public shared (msg) func owner_remove_canister(canister_id : Text) : async () {
        var o : Text = Option.get(Trie.find(_owners, keyT(canister_id), Text.equal), "");
        assert (Principal.fromText(o) == msg.caller);
        _covers := Trie.remove(_covers, keyT(canister_id), Text.equal).0;
        _owners := Trie.remove(_owners, keyT(canister_id), Text.equal).0;
        _games := Trie.remove(_games, keyT(canister_id), Text.equal).0;
    };

    //admin functions
    //
    public shared ({ caller }) func admin_create_game(game_name : Text, data : Text, base64 : Text, _type : Text, game_url : Text, canister_id : Text) : async (Text) {
        assert (_isAdmin(Principal.toText(caller)));
        _games := Trie.put(
            _games,
            keyT(canister_id),
            Text.equal,
            {
                name = game_name;
                description = data;
                platform = _type;
                canister_id = canister_id;
                url = game_url;
                cover = "https://6rvbl-uqaaa-aaaal-ab24a-cai.raw.icp0.io/cover/" #canister_id;
                lastUpdated = Time.now();
                verified = false;
            },
        ).0;
        _covers := Trie.put(_covers, keyT(canister_id), Text.equal, base64).0;
        _owners := Trie.put(_owners, keyT(canister_id), Text.equal, Principal.toText(caller)).0;
        return game_url;
    };

    public shared ({ caller }) func admin_remove_game(canister_id : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        _covers := Trie.remove(_covers, keyT(canister_id), Text.equal).0;
        _owners := Trie.remove(_owners, keyT(canister_id), Text.equal).0;
        _games := Trie.remove(_games, keyT(canister_id), Text.equal).0;
    };

    public shared ({ caller }) func admin_verify_game(canister_id : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        switch (Trie.find(_games, keyT(canister_id), Text.equal)) {
            case (?_game) {
                var g : Game = {
                    name = _game.name;
                    description = _game.description;
                    platform = _game.platform;
                    canister_id = _game.canister_id;
                    url = _game.url;
                    cover = _game.cover;
                    lastUpdated = _game.lastUpdated;
                    verified = true;
                };
                _games := Trie.put(_games, keyT(canister_id), Text.equal, g).0;
            };
            case _ {};
        };
    };

    public shared ({ caller }) func admin_remove_game_verification(canister_id : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        switch (Trie.find(_games, keyT(canister_id), Text.equal)) {
            case (?_game) {
                var g : Game = {
                    name = _game.name;
                    description = _game.description;
                    platform = _game.platform;
                    canister_id = _game.canister_id;
                    url = _game.url;
                    cover = _game.cover;
                    lastUpdated = _game.lastUpdated;
                    verified = false;
                };
                _games := Trie.put(_games, keyT(canister_id), Text.equal, g).0;
            };
            case _ {};
        };
    };

    //http query for cover url
    public query func http_request(req : HttpRequest) : async (HttpResponse) {
        let path = Iter.toArray(Text.tokens(req.url, #text("/")));
        let collection = path[1];
        switch (req.method, (path[0] == "cover")) {
            case ("GET", true) {
                switch (Trie.find(_covers, keyT(collection), Text.equal)) {
                    case (?c) {
                        var content : Text = "<!DOCTYPE html><html lang=\"en\"><head><title>Cover Image</title></head><body><div style=\"text-align:center; margin-top:10vh\"><img src=\"" #c # "\" style=\"width:200px\"></img></div></body></html>";
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

};
