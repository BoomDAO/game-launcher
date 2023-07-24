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

import ICRC3 "./ICRC3/Canisters/Token";
import Types "./ICRC3/Types";

actor Deployer {

    //Stable Memory
    private func deployer() : Principal = Principal.fromActor(Deployer);
    private stable var _tokens : Trie.Trie<Text, Token> = Trie.empty(); //mapping of token_canister_id -> Token details
    private stable var _logos : Trie.Trie<Text, Text> = Trie.empty(); //mapping of token_canister_id -> base64
    private stable var _owners : Trie.Trie<Text, Text> = Trie.empty(); //mapping  token_canister_id -> owner principal id
    private stable var _admins : [Text] = [];

    //Types
    //
    // type Asset = Asset.Assets;
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

    //for game
    public type Token = {
        name : Text;
        symbol : Text;
        description : Text;
        canister : Text;
        cover : Text;
    };

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

    //Utility Functions
    private func key(x : Nat32) : Trie.Key<Nat32> {
        return { hash = x; key = x };
    };

    private func keyT(x : Text) : Trie.Key<Text> {
        return { hash = Text.hash(x); key = x };
    };

    private func textToNat(txt : Text) : Nat {
        assert (txt.size() > 0);
        let chars = txt.chars();

        var num : Nat = 0;
        for (v in chars) {
            let charToNum = Nat32.toNat(Char.toNat32(v) -48);
            assert (charToNum >= 0 and charToNum <= 9);
            num := num * 10 + charToNum;
        };

        return num;
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    private func _isAdmin(p : Text) : (Bool) {
        for (i in _admins.vals()) {
            if (i == p) {
                return true;
            };
        };
        return false;
    };

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

    public query func getAllAdmins() : async ([Text]) {
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

    private func create_canister(_owner : Principal, init : Types.TokenInitArgs) : async (Text) {
        Cycles.add(1000000000000);
        let canister = await ICRC3.Token(init);
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
    public query func getOwner(canister_id : Text) : async (?Text) {
        var owner : ?Text = Trie.find(_owners, keyT(canister_id), Text.equal);
        return owner;
    };

    public query func getUserTotalTokens(uid : Text) : async (Nat) {
        var size = 0;
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                size := size + 1;
            };
        };
        return size;
    };

    public query func getUserTokens(uid : Text, _page : Nat) : async ([Token]) {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var b : Buffer.Buffer<Token> = Buffer.Buffer<Token>(0);
        for ((i, v) in Trie.iter(_owners)) {
            if (v == uid) {
                switch (Trie.find(_tokens, keyT(i), Text.equal)) {
                    case (?t) {
                        b.add(t);
                    };
                    case _ {};
                };
            };
        };
        let arr = Buffer.toArray(b);
        b := Buffer.Buffer<Token>(0);
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

    public query func getTokens(_page : Nat) : async ([Token]) {
        var lower : Nat = _page * 9;
        var upper : Nat = lower + 9;
        var b : Buffer.Buffer<Token> = Buffer.Buffer<Token>(0);
        for ((i, v) in Trie.iter(_owners)) {
            switch (Trie.find(_tokens, keyT(i), Text.equal)) {
                case (?t) {
                    b.add(t);
                };
                case _ {};
            };
        };
        let arr = Buffer.toArray(b);
        b := Buffer.Buffer<Token>(0);
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

    public query func getTotalTokens() : async (Nat) {
        return Trie.size(_tokens);
    };

    //Updates
    //
    public shared (msg) func createTokenCanister(_name : Text, _symbol : Text, _desc : Text, _amt : Nat, logo_encoding : Text, _decimals : Nat8, tx_fee : Nat) : async (Text) {
        let pre_mint_account = {
            owner = msg.caller;
            subaccount = null;
        };
        var canister_id : Text = await create_canister(
            msg.caller,
            {
                name = _name;
                symbol = _symbol;
                decimals = _decimals;
                fee = tx_fee;
                max_supply = 1000000000000000000000000000000000000; // Max supply is set to 10^36
                initial_balances = [(pre_mint_account, _amt)];
                min_burn_amount = 0;
                minting_account = ?pre_mint_account;
                advanced_settings= null;
            }
        );
        _tokens := Trie.put(
            _tokens,
            keyT(canister_id),
            Text.equal,
            {
                name = _name;
                symbol = _symbol;
                description = _desc;
                canister = canister_id;
                cover = "https://" #Principal.toText(deployer()) #".raw.icp0.io/logo/" #canister_id; 
            },
        ).0;
        _logos := Trie.put(_logos, keyT(canister_id), Text.equal, logo_encoding).0;
        _owners := Trie.put(_owners, keyT(canister_id), Text.equal, Principal.toText(msg.caller)).0;
        return canister_id;
    };

    //Queries
    public query func getTokenDetails(canister_id : Text) : async (?Token) {
        switch (Trie.find(_tokens, keyT(canister_id), Text.equal)) {
            case (?t) {
                return ?t;
            };
            case _ {
                return null;
            };
        };
    };

    //upgrade token details
    public shared (msg) func updateTokenCover(canister_id : Text, base64 : Text) : async (Result.Result<(), Text>) {
        assert ((await _isOwner(msg.caller, canister_id)) == true);
        switch (Trie.find(_owners, keyT(canister_id), Text.equal)) {
            case (?o) {
                assert (Principal.fromText(o) == msg.caller);
                _logos := Trie.put(_logos, keyT(canister_id), Text.equal, base64).0;
                return #ok();
            };
            case null {
                return #err("canister owner not found");
            };
        };
    };

    public query func http_request(req : HttpRequest) : async (HttpResponse) {
        let path = Iter.toArray(Text.tokens(req.url, #text("/")));
        let collection = path[1];
        switch (req.method, (path[0] == "logo")) {
            case ("GET", true) {
                switch (Trie.find(_logos, keyT(collection), Text.equal)) {
                    case (?c) {
                        var content : Text = "<!DOCTYPE html><html lang=\"en\"><head><title>Logo</title></head><body><div style=\"text-align:center; margin-top:10vh\"><img src=\"" #c # "\" style=\"width:200px\"></img></div></body></html>";
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

    public query func getAllTokens() : async [(Text, Text)] {
        var b : Buffer.Buffer<(Text, Text)> = Buffer.Buffer<(Text, Text)>(0);
        for ((i, v) in Trie.iter(_tokens)) {
            b.add((i, v.name));
        };
        return Buffer.toArray(b);
    };

};
