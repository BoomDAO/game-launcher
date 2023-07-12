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
import Binary "../utils/Binary";
import Utils "../utils/Utils";

actor Deployer {

    //Stable Memory
    //
    private func deployer() : Principal = Principal.fromActor(Deployer);
    private stable var _games : Trie.Trie<Text, Game> = Trie.empty(); //mapping of canister_id -> Game (info)
    private stable var _covers : Trie.Trie<Text, Text> = Trie.empty(); //mapping of game_canister_id -> base64
    private stable var _owners : Trie.Trie<Text, Text> = Trie.empty(); //mapping asset canister_id -> owner principal id
    private stable var _admins : [Text] = [];

    //Types
    public type Game = {
        name : Text;
        description : Text;
        platform : Text;
        canister_id : Text;
        url : Text;
        cover : Text;
        lastUpdated : Int;
        verified : Bool;
        visibility : Text; //for public/private/soon
    };

    public type canister_id = Principal;
    public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    public type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : [Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
    };
    public type user_id = Principal;
    public type wasm_module = Blob;
    public type headerField = (Text, Text);
    public type HttpRequest = {
        body : Blob;
        headers : [headerField];
        method : Text;
        url : Text;
    };
    public type HttpResponse = {
        body : Blob;
        headers : [headerField];
        status_code : Nat16;
    };

    //IC Management Canister
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

    //Utility Functions
    func _sort(t : Trie.Trie<Text, Game>) : [Game] {
        var trie : Trie.Trie<Text, Game> = Trie.empty();
        var b : Buffer.Buffer<Int> = Buffer.Buffer<Int>(0);
        var _b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        for ((i, g) in Trie.iter(t)) {
            trie := Trie.put(trie, Utils.keyT(Int.toText(g.lastUpdated)), Text.equal, g).0;
            b.add(g.lastUpdated);
        };
        var a : [Int] = Buffer.toArray(b);
        a := Array.sort(a, Int.compare);
        a := Array.reverse(a);
        for (i in a.vals()) {
            switch (Trie.find(trie, Utils.keyT(Int.toText(i)), Text.equal)) {
                case (?g) {
                    _b.add(g);
                };
                case _ {};
            };
        };
        Buffer.toArray(_b);
    };

    func _sort_and_visible(t : Trie.Trie<Text, Game>) : [Game] {
        var trie : Trie.Trie<Text, Game> = Trie.empty();
        var b : Buffer.Buffer<Int> = Buffer.Buffer<Int>(0);
        var _b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        for ((i, g) in Trie.iter(t)) {
            trie := Trie.put(trie, Utils.keyT(Int.toText(g.lastUpdated)), Text.equal, g).0;
            b.add(g.lastUpdated);
        };
        var a : [Int] = Buffer.toArray(b);
        a := Array.sort(a, Int.compare);
        a := Array.reverse(a);
        for (i in a.vals()) {
            switch (Trie.find(trie, Utils.keyT(Int.toText(i)), Text.equal)) {
                case (?g) {
                    if(g.visibility != "private") {
                        _b.add(g);
                    };
                };
                case _ {};
            };
        };
        Buffer.toArray(_b);
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    public query func get_total_games() : async (Nat) {
        return Trie.size(_games);
    };

    public query func get_total_visible_games() : async (Nat) {
        var count = 0;
        for((i, v) in Trie.iter(_games)) {
            if(v.visibility != "private"){
                count := count + 1;
            };
        };
        return count;
    };

    public query func get_users_total_games(uid : Text) : async (Nat) {
        var b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                switch (Trie.find(_games, Utils.keyT(i), Text.equal)) {
                    case (?g) {
                        b.add(g);
                    };
                    case _ {};
                };
            };
        };
        return b.size();
    };

    private func _isAdmin(p : Text) : (Bool) {
        for (i in _admins.vals()) {
            if (i == p) {
                return true;
            };
        };
        return false;
    };

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

    public query func get_all_admins() : async ([Text]) {
        return _admins;
    };

    //Internal Functions
    //
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
                    controllers = ?[init_owner, deployer()];
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            })
        );
    };

    //Queries
    //
    public query func get_owner(canister_id : Text) : async (?Text) {
        var owner : ?Text = Trie.find(_owners, Utils.keyT(canister_id), Text.equal);
        return owner;
    };

    public query func getFeaturedGames() : async [Text] {
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for((_canister_id, _games) in Trie.iter(_games)){
            if(_games.verified == true) {
                b.add(_canister_id);
            }
        };
        return Buffer.toArray(b);
    };

    //Updates
    //
    public shared (msg) func create_game_canister(game_name : Text, data : Text, base64 : Text, _type : Text) : async (Text) {
        var canister_id : Text = await create_canister(msg.caller);
        var deployer_canister : Text = Principal.toText(deployer());
        _games := Trie.put(
            _games,
            Utils.keyT(canister_id),
            Text.equal,
            {
                name = game_name;
                description = data;
                platform = _type;
                canister_id = canister_id;
                url = "https://" #canister_id # ".raw.icp0.io/";
                cover = "https://" #deployer_canister #".raw.ic0.app/cover/" #canister_id;
                lastUpdated = Time.now();
                verified = false;
                visibility = "public";
            },
        ).0;
        _covers := Trie.put(_covers, Utils.keyT(canister_id), Text.equal, base64).0;
        _owners := Trie.put(_owners, Utils.keyT(canister_id), Text.equal, Principal.toText(msg.caller)).0;
        return canister_id;
    };

    public shared ({ caller }) func admin_create_game(game_name : Text, data : Text, base64 : Text, _type : Text, game_url : Text, canister_id : Text) : async (Text) {
        assert (_isAdmin(Principal.toText(caller)));
        var deployer_canister : Text = Principal.toText(deployer());
        _games := Trie.put(
            _games,
            Utils.keyT(canister_id),
            Text.equal,
            {
                name = game_name;
                description = data;
                platform = _type;
                canister_id = canister_id;
                url = game_url;
                cover = "https://" #deployer_canister #".raw.ic0.app/cover/" #canister_id;
                lastUpdated = Time.now();
                verified = false;
                visibility = "public";
            },
        ).0;
        _covers := Trie.put(_covers, Utils.keyT(canister_id), Text.equal, base64).0;
        _owners := Trie.put(_owners, Utils.keyT(canister_id), Text.equal, Principal.toText(caller)).0;
        return game_url;
    };

    public shared ({ caller }) func admin_remove_game(canister_id : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        _covers := Trie.remove(_covers, Utils.keyT(canister_id), Text.equal).0;
        _owners := Trie.remove(_owners, Utils.keyT(canister_id), Text.equal).0;
        _games := Trie.remove(_games, Utils.keyT(canister_id), Text.equal).0;
    };

    public shared ({ caller }) func adminUpdateFeaturedGames(_canister_ids : Text) : async () {
        assert (_isAdmin(Principal.toText(caller)));
        var dummy_time : Int = Time.now();
        for ((canister_id, game) in Trie.iter(_games)) {
            switch (Trie.find(_games, Utils.keyT(canister_id), Text.equal)) {
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
                        visibility = _game.visibility;
                    };
                    _games := Trie.put(_games, Utils.keyT(canister_id), Text.equal, g).0;
                };
                case _ {};
            };
        };
        var canister_ids : [Text] = Iter.toArray(Text.tokens(_canister_ids, #text(",")));
        for (canister_id in canister_ids.vals()) {
            dummy_time := dummy_time - 1;
            switch (Trie.find(_games, Utils.keyT(canister_id), Text.equal)) {
                case (?_game) {
                    var g : Game = {
                        name = _game.name;
                        description = _game.description;
                        platform = _game.platform;
                        canister_id = _game.canister_id;
                        url = _game.url;
                        cover = _game.cover;
                        lastUpdated = dummy_time;
                        verified = true;
                        visibility = _game.visibility;
                    };
                    _games := Trie.put(_games, Utils.keyT(canister_id), Text.equal, g).0;
                };
                case _ {};
            };
        };
    };

    //Queries
    //
    public query func get_all_asset_canisters(_page : Nat, _sorting : Text) : async ([Game]) {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var b : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        var _featured_first : Buffer.Buffer<Game> = Buffer.Buffer<Game>(0);
        let arr : [Game] = _sort_and_visible(_games);
        for(i in arr.vals()) {
            if(i.verified){
                _featured_first.add(i);
            };
        };
        for(i in arr.vals()) {
            if(i.verified == false){
                _featured_first.add(i);
            };
        };
        var _featured_first_arr : [Game] = Buffer.toArray(_featured_first);

        let size = arr.size();
        if (upper > size) {
            upper := size;
        };
        switch (_sorting) {
            case ("newest") {
                while (lower < upper) {
                    b.add(arr[lower]);
                    lower := lower + 1;
                };
                return Buffer.toArray(b);
            };
            case ("featured") {
                while (lower < upper) {
                    b.add(_featured_first_arr[lower]);
                    lower := lower + 1;
                };
                return Buffer.toArray(b);
            };
            case _ { return Buffer.toArray(b) };
        };
    };

    public query func get_game_cover(canister_id : Text) : async (Text) {
        switch (Trie.find(_covers, Utils.keyT(canister_id), Text.equal)) {
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
                switch (Trie.find(_games, Utils.keyT(i), Text.equal)) {
                    case (?g) {
                        t := Trie.put(t, Utils.keyT(i), Text.equal, g).0;
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
        switch (Trie.find(_games, Utils.keyT(canister_id), Text.equal)) {
            case (?g) {
                return ?g;
            };
            case _ {
                return null;
            };
        };
    };

    //upgrade game data
    //
    public shared (msg) func update_game_data(canister_id : Text, game_name : Text, game_data : Text, game_platform : Text) : async (Result.Result<(), Text>) {
        assert ((await _isOwner(msg.caller, canister_id)) == true);
        switch (Trie.find(_owners, Utils.keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                switch (Trie.find(_games, Utils.keyT(canister_id), Text.equal)) {
                    case (?_game) {
                        _games := Trie.put(
                            _games,
                            Utils.keyT(canister_id),
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
                                visibility = _game.visibility;
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
        switch (Trie.find(_owners, Utils.keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                _covers := Trie.put(_covers, Utils.keyT(canister_id), Text.equal, base64).0;
                return #ok();
            };
            case null {
                return #err("canister owner not found");
            };
        };
    };

    public shared (msg) func update_game_visibility(canister_id : Text, _visibility : Text) : async (Result.Result<(), Text>) {
        assert ((await _isOwner(msg.caller, canister_id)) == true);
        switch (Trie.find(_owners, Utils.keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                switch (Trie.find(_games, Utils.keyT(canister_id), Text.equal)) {
                    case (?_game) {
                        if(_visibility == "public" or _visibility == "private" or _visibility == "soon") {
                            _games := Trie.put(
                                _games,
                                Utils.keyT(canister_id),
                                Text.equal,
                                {
                                    name = _game.name;
                                    description = _game.description;
                                    platform = _game.platform;
                                    canister_id = _game.canister_id;
                                    url = _game.url;
                                    cover = _game.cover;
                                    lastUpdated = _game.lastUpdated;
                                    verified = _game.verified;
                                    visibility = _visibility;
                                }
                            ).0;
                        }
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

    public shared (msg) func remove_canister(canister_id : Text) : async () {
        var o : Text = Option.get(Trie.find(_owners, Utils.keyT(canister_id), Text.equal), "");
        assert (Principal.fromText(o) == msg.caller);
        _covers := Trie.remove(_covers, Utils.keyT(canister_id), Text.equal).0;
        _owners := Trie.remove(_owners, Utils.keyT(canister_id), Text.equal).0;
        _games := Trie.remove(_games, Utils.keyT(canister_id), Text.equal).0;
    };

    public query func http_request(req : HttpRequest) : async (HttpResponse) {
        let path = Iter.toArray(Text.tokens(req.url, #text("/")));
        let collection = path[1];
        switch (req.method, (path[0] == "cover")) {
            case ("GET", true) {
                switch (Trie.find(_covers, Utils.keyT(collection), Text.equal)) {
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

    // public func setOwner(c : Text, n : Text) : async (){
    //     switch(Trie.find(_owners, Utils.keyT(c), Text.equal)){
    //         case (?o){
    //             // assert(Principal.fromText(o) == msg.caller);
    //             _owners := Trie.put(_owners, Utils.keyT(c), Text.equal, n).0;
    //         };
    //         case null {
    //             return ();
    //         }
    //     }
    // };

    public query func get_all_games() : async [(Text, Game)] {
        var b = Buffer.Buffer<(Text, Game)> (0);
        for((i, v) in Trie.iter(_games)) {
            b.add((i, v));
        };
        return Buffer.toArray(b);
    };

};
