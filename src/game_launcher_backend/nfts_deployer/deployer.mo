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
import Iter "mo:base/Iter";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
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
import Timer "mo:base/Timer";

import NFT "./EXT/extv2boom";
import AID "../utils/AccountIdentifier";
import Hex "../utils/Hex";
import ExtCore "../utils/Core";
import ExtCommon "../utils/Common";
import ExtAllowance "../utils/Allowance";
import ExtNonFungible "../utils/NonFungible";
import AccountIdentifier "../utils/AccountIdentifier";

//Cap
import Cap "./Cap/Cap";
import Queue "../utils/Queue";
import EXTAsset "./EXT/extAsset";
import Core "../utils/Core";
import Types "../types/ext.types";

actor Deployer {

    type NFT = NFT.EXTNFT;
    type EXTAssetService = EXTAsset.EXTAsset;
    type Order = { #less; #equal; #greater };
    type Time = Time.Time;
    type AccountIdentifier = ExtCore.AccountIdentifier;
    type SubAccount = ExtCore.SubAccount;
    type User = ExtCore.User;
    type Balance = ExtCore.Balance;
    type TokenIdentifier = ExtCore.TokenIdentifier;
    type TokenIndex = ExtCore.TokenIndex;
    type Extension = ExtCore.Extension;
    type CommonError = ExtCore.CommonError;
    type BalanceRequest = ExtCore.BalanceRequest;
    type BalanceResponse = ExtCore.BalanceResponse;
    type TransferRequest = ExtCore.TransferRequest;
    type TransferResponse = ExtCore.TransferResponse;
    type AllowanceRequest = ExtAllowance.AllowanceRequest;
    type ApproveRequest = ExtAllowance.ApproveRequest;
    type MetadataLegacy = ExtCommon.Metadata;
    type NotifyService = ExtCore.NotifyService;
    type MintingRequest = {
        to : AccountIdentifier;
        asset : Nat32;
    };
    type MetadataValue = (
        Text,
        {
            #text : Text;
            #blob : Blob;
            #nat : Nat;
            #nat8 : Nat8;
        },
    );
    type MetadataContainer = {
        #data : [MetadataValue];
        #blob : Blob;
        #json : Text;
    };
    type Metadata = {
        #fungible : {
            name : Text;
            symbol : Text;
            decimals : Nat8;
            metadata : ?MetadataContainer;
        };
        #nonfungible : {
            name : Text;
            asset : Text;
            thumbnail : Text;
            metadata : ?MetadataContainer;
        };
    };

    //Marketplace
    type Transaction = {
        token : TokenIndex;
        seller : AccountIdentifier;
        price : Nat64;
        buyer : AccountIdentifier;
        time : Time;
    };
    type Listing = {
        seller : Principal;
        price : Nat64;
        locked : ?Time;
    };
    type ListRequest = {
        token : TokenIdentifier;
        from_subaccount : ?SubAccount;
        price : ?Nat64;
    };

    //LEDGER
    type AccountBalanceArgs = { account : AccountIdentifier };
    type ICPTs = { e8s : Nat64 };
    type SendArgs = {
        memo : Nat64;
        amount : ICPTs;
        fee : ICPTs;
        from_subaccount : ?SubAccount;
        to : AccountIdentifier;
        created_at_time : ?Time;
    };

    //Cap
    type CapDetailValue = {
        #I64 : Int64;
        #U64 : Nat64;
        #Vec : [CapDetailValue];
        #Slice : [Nat8];
        #Text : Text;
        #True;
        #False;
        #Float : Float;
        #Principal : Principal;
    };
    type CapEvent = {
        time : Nat64;
        operation : Text;
        details : [(Text, CapDetailValue)];
        caller : Principal;
    };
    type CapIndefiniteEvent = {
        operation : Text;
        details : [(Text, CapDetailValue)];
        caller : Principal;
    };

    //Sale
    type PaymentType = {
        #sale : Nat64;
        #nft : TokenIndex;
        #nfts : [TokenIndex];
    };
    type Payment = {
        purchase : PaymentType;
        amount : Nat64;
        subaccount : SubAccount;
        payer : AccountIdentifier;
        expires : Time;
    };
    type SaleTransaction = {
        tokens : [TokenIndex];
        seller : Principal;
        price : Nat64;
        buyer : AccountIdentifier;
        time : Time;
    };
    type SaleDetailGroup = {
        id : Nat;
        name : Text;
        start : Time;
        end : Time;
        available : Bool;
        pricing : [(Nat64, Nat64)];
    };
    type SaleDetails = {
        start : Time;
        end : Time;
        groups : [SaleDetailGroup];
        quantity : Nat;
        remaining : Nat;
    };
    type SaleSettings = {
        price : Nat64;
        salePrice : Nat64;
        sold : Nat;
        remaining : Nat;
        startTime : Time;
        whitelistTime : Time;
        whitelist : Bool;
        totalToSell : Nat;
        bulkPricing : [(Nat64, Nat64)];
    };
    type SalePricingGroup = {
        name : Text;
        limit : (Nat64, Nat64); //user, group
        start : Time;
        end : Time;
        pricing : [(Nat64, Nat64)]; //qty,price
        participants : [AccountIdentifier];
    };
    type SaleRemaining = { #burn; #send : AccountIdentifier; #retain };
    type Sale = {
        start : Time; //Start of first group
        end : Time; //End of first group
        groups : [SalePricingGroup];
        quantity : Nat; //Tokens for sale, set by 0000 address
        remaining : SaleRemaining;
    };

    //EXTv2 Asset Handling
    type AssetHandle = Text;
    type AssetId = Nat32;
    type ChunkId = Nat32;
    type AssetType = {
        #canister : {
            id : AssetId;
            canister : Text;
        };
        #direct : [ChunkId];
        #other : Text;
    };
    type Asset = {
        ctype : Text;
        filename : Text;
        atype : AssetType;
    };
    type Asset_req = {
        assetHandle : Text;
        ctype : Text;
        filename : Text;
        atype : AssetType;
    };

    //HTTP
    type StreamingCallbackHttpResponse = {
        body : Blob;
        token : ?Token;
    };
    type Token = {
        arbitrary_data : Text;
    };
    type CallbackStrategy = {
        callback : shared query (Token) -> async StreamingCallbackHttpResponse;
        token : Token;
    };
    type StreamingStrategy = {
        #Callback : CallbackStrategy;
    };
    type HeaderField = (Text, Text);
    type HttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
        streaming_strategy : ?StreamingStrategy;
        upgrade : ?Bool;
    };
    type HttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };

    //IC Management Canister
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
    type ICTx = {
        height : Nat64;
        to : Text;
        from : Text;
        amt : Nat64;
    };
    type ICHttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
        upgrade : ?Bool;
    };
    type ICHttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };
    type ICHttpHeader = {
        name : Text;
        value : Text;
    };
    type ICHttpMethod = {
        #get;
        #post;
        #head;
    };
    type ICTransformType = {
        #function : shared ICCanisterHttpResponsePayload -> async ICCanisterHttpResponsePayload;
    };
    type ICTransformArgs = {
        response : ICCanisterHttpResponsePayload;
        context : Blob;
    };
    type ICTransformContext = {
        function : shared query ICTransformArgs -> async ICCanisterHttpResponsePayload;
        context : Blob;
    };
    type ICCanisterHttpRequestArgs = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [ICHttpHeader];
        body : [Nat8];
        method : ICHttpMethod;
        transform : ?ICTransformContext;
    };
    type ICCanisterHttpResponsePayload = {
        status : Nat;
        headers : [ICHttpHeader];
        body : [Nat8];
    };
    type ICResponse = {
        #Success : Text;
        #Err : Text;
    };
    //Batch Information
    type Info = {
        collection : Text;
        createdAt : Int;
        burnAt : Int;
        lowerBound : Nat;
        upperBound : Nat;
        status : Text;
    };
    type Collection = {
        name : Text;
        canister_id : Text;
    };
    //stable memory
    //
    private func deployer() : Principal = Principal.fromActor(Deployer); 
    private stable var collections : Trie.Trie<Text, Text> = Trie.empty(); //mapping of Collection CanisterID -> Collection Name
    private stable var _owner : Trie.Trie<Text, Text> = Trie.empty(); //mapping collection canister id -> owner principal id
    private stable var _info : Trie.Trie<AssetHandle, Info> = Trie.empty(); //mapping asset hanel -> Burn Information
    private stable var last_cron_time : Int = Time.now();

    //IC Management Canister Interface
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
        http_request : shared ICCanisterHttpRequestArgs -> async ICCanisterHttpResponsePayload;
    };

    //internal functions
    //
    private func burnNfts(collection_canister_id : Text, _lowerBound : TokenIndex, _upperBound : TokenIndex, assetHandle : AssetHandle) : async () {
        let collection = actor (collection_canister_id) : actor {
            ext_internal_bulk_burn : (TokenIndex, TokenIndex) -> async ();
        };
        var res : () = await collection.ext_internal_bulk_burn(_lowerBound, _upperBound);
        var i : ?Info = Trie.find(_info, keyT(assetHandle), Text.equal);
        switch (i) {
            case (?i) {
                var new_i : Info = {
                    collection = i.collection;
                    createdAt = i.createdAt;
                    burnAt = i.burnAt;
                    lowerBound = i.lowerBound;
                    upperBound = i.upperBound;
                    status = "burned";
                };
                _info := Trie.put(_info, keyT(assetHandle), Text.equal, new_i).0;
            };
            case _ {};
        };
    };

    func burn_cron() : async () {
        last_cron_time := Time.now();
        for ((id, info) in Trie.iter(_info)) {
            if (info.burnAt < Time.now() and info.status == "active" and info.burnAt != 0) {
                await burnNfts(info.collection, Nat32.fromNat(info.lowerBound), Nat32.fromNat(info.upperBound), id);
            };
        };
    };

    private func key(x : Nat32) : Trie.Key<Nat32> {
        return { hash = x; key = x };
    };

    private func keyT(x : Text) : Trie.Key<Text> {
        return { hash = Text.hash(x); key = x };
    };

    private func create_canister(init_owner : Principal, name : Text, data : Text) : async (Text) {
        Cycles.add(1000000000000);
        let canister = await NFT.EXTNFT(init_owner, name, data);
        let _ = await updateCanister(canister, init_owner);
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
            settings : definite_canister_settings;
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

    private func _isMinter(collection_canister_id : Text, p : Principal) : async (Bool) {
        let collection = actor (collection_canister_id) : actor {
            getMinter : () -> async [Principal];
        };
        var _b : [Principal] = await collection.getMinter();
        for (i in _b.vals()) {
            if (p == i) {
                return true;
            };
        };
        return false;
    };

    private func _mintNft(collection_canister_id : Text, _req : (AccountIdentifier, Metadata)) : async TokenIndex {
        let collection = actor (collection_canister_id) : actor {
            ext_mint : ([(AccountIdentifier, Metadata)]) -> async ([TokenIndex]);
        };
        var b : Buffer.Buffer<(AccountIdentifier, Metadata)> = Buffer.Buffer<(AccountIdentifier, Metadata)>(0);
        b.add(_req);
        var a : [TokenIndex] = await collection.ext_mint(Buffer.toArray(b));
        return a[0];
    };

    private func _addAsset(collection_canister_id : Text, assetHandle : AssetHandle, chunk : [Nat8]) : async () {
        let collection = actor (collection_canister_id) : actor {
            ext_assetAdd : (Text, Text, Text, AssetType, Nat) -> async ();
            ext_assetStream : (Text, Blob, Bool) -> async (Bool);
        };
        var _chunk : Blob = Blob.fromArray(chunk);
        await collection.ext_assetAdd(assetHandle, "image/png", assetHandle, #direct([]) : AssetType, 0);
        let res = await collection.ext_assetStream(assetHandle, _chunk, true);
    };

    //utility functions
    //
    public query func cycleBalance() : async Nat {      
        Cycles.balance();
    };

    public shared ({ caller }) func add_controller(collection_canister_id : Text, p : Text) : async () {
        var check : Bool = await _isController(collection_canister_id, caller);
        if (check == false) {
            return ();
        };
        var status : {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : definite_canister_settings;
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

    public shared ({ caller }) func remove_controller(collection_canister_id : Text, p : Text) : async () {
        var check : Bool = await _isController(collection_canister_id, caller);
        if (check == false) {
            return ();
        };
        var status : {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : definite_canister_settings;
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

    //Queries
    //
    public query func getTotalCollections() : async (Nat) {
        return Trie.size(collections);
    };
    
    public query func getCollections(page : Nat32) : async ([Collection]) {
        var buffer : Buffer.Buffer<Collection> = Buffer.Buffer<Collection>(0);
        var start : Nat32 = page * 9;
        var end : Nat32 = start + 9;
        for ((id, name) in Trie.iter(collections)) {
            var i : Collection = {
                name = name;
                canister_id = id;
            };
            buffer.add(i);
        };
        var arr : [Collection] = Buffer.toArray(buffer);
        if(Nat32.toNat(end) > arr.size()) {
            end := Nat32.fromNat(arr.size());
        };
        buffer := Buffer.Buffer<Collection>(0);
        while(start < end) {
            buffer.add(arr[Nat32.toNat(start)]);
            start := start + 1;
        };
        return Buffer.toArray(buffer);
    };

    public query func getUserCollections(_uid : Text) : async ([Collection]) {
        var buffer : Buffer.Buffer<Collection> = Buffer.Buffer<Collection>(0);
        for ((id, uid) in Trie.iter(_owner)) {
            if (uid == _uid) {
                switch (Trie.find(collections, keyT(id), Text.equal)) {
                    case (?n) {
                        buffer.add({
                            name = n;
                            canister_id = id;
                        });
                    };
                    case _ {};
                };
            };
        };
        return Buffer.toArray(buffer);
    };

    public func getRegistry(collection_canister_id : Text, page : Nat32) : async ([Text]) {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        let collection = actor (collection_canister_id) : actor {
            get_paged_registry : (Nat32) -> async [(TokenIndex, AccountIdentifier)];
        };
        var _registry : [(TokenIndex, AccountIdentifier)] = await collection.get_paged_registry(page);
        for ((index, add) in _registry.vals()) {
            buffer.add(add);
        };
        return Buffer.toArray(buffer);
    };

    public func getSize(collection_canister_id : Text) : async (Nat) {
        let collection = actor (collection_canister_id) : actor {
            getTotalTokens : () -> async Nat;
            supply : (TokenIdentifier) -> async (Result.Result<Balance, CommonError>);
        };
        var res : Result.Result<Balance, CommonError> = await collection.supply("");
        switch (res) {
            case (#ok size) {
                return size;
            };
            case (#err _) { return 0 };
        };
    };

    public shared (msg) func getTokenMetadata(collection_canister_id : Text, index : TokenIndex) : async (Text) {
        // var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        // assert (msg.caller == Principal.fromText(owner));
        let collection = actor (collection_canister_id) : actor {
            extGetTokenMetadata : (TokenIndex) -> async (?Metadata);
        };
        var m : ?Metadata = await collection.extGetTokenMetadata(index);
        var json : Text = "";
        switch (m) {
            case (?md) {
                switch (md) {
                    case (#fungible _) {};
                    case (#nonfungible d) {
                        switch (d.metadata) {
                            case (?x) {
                                switch (x) {
                                    case (#json j) { json := j };
                                    case (#blob _) {};
                                    case (#data _) {};
                                };
                            };
                            case _ {};
                        };
                    };
                };
            };
            case _ {};
        };
        return json;
    };

    public shared (msg) func getUserNfts(collection_canister_id : Text, uid : Text) : async ([(TokenIndex, Text)]) {
        var buffer : Buffer.Buffer<(TokenIndex, Text)> = Buffer.Buffer<(TokenIndex, Text)>(0);
        let collection = actor (collection_canister_id) : actor {
            extGetTokenMetadata : (TokenIndex) -> async (?Metadata);
            get_paged_registry : (Nat32) -> async [(TokenIndex, AccountIdentifier)];
        };
        var s : Nat = await getSize(collection_canister_id);
        s := s / 10000;
        var i : Nat32 = 0;
        let aid : AccountIdentifier = AccountIdentifier.fromPrincipal(Principal.fromText(uid), null);
        label pages for (i in Iter.range(0, s)) {
            var _registry : [(TokenIndex, AccountIdentifier)] = await collection.get_paged_registry(Nat32.fromNat(i));
            for ((index, add) in _registry.vals()) {
                if (add == aid) {
                    var m : ?Metadata = await collection.extGetTokenMetadata(index);
                    switch (m) {
                        case (?d) {
                            switch (d) {
                                case (#fungible f) {};
                                case (#nonfungible nmd) {
                                    switch (nmd.metadata) {
                                        case (?x) {
                                            switch (x) {
                                                case (#blob _) {};
                                                case (#data _) {};
                                                case (#json j) {
                                                    buffer.add((index, j));
                                                };
                                            };
                                        };
                                        case _ {
                                            buffer.add((index, ""));
                                        };
                                    };
                                };
                            };
                        };
                        case _ {
                            buffer.add((index, ""));
                        };
                    };
                };
            };
        };
        return Buffer.toArray(buffer);
    };

    public shared (msg) func getCollectionMetadata(collection_canister_id : Text) : async (Text, Text) {
        let collection = actor (collection_canister_id) : actor {
            ext_getCollectionMetadata : () -> async (Text, Text);
        };
        let d : (Text, Text) = await collection.ext_getCollectionMetadata();
        return d;
    };

    public query func getBurnInfo(collection_canister_id : Text) : async [Info] {
        var buffer : Buffer.Buffer<Info> = Buffer.Buffer<Info>(0);
        for ((id, info) in Trie.iter(_info)) {
            if (info.collection == collection_canister_id) {
                buffer.add(info);
            };
        };
        return Buffer.toArray(buffer);
    };

    public query func getTokenUrl(collection_canister_id : Text, token_index : TokenIndex) : async (Text) {
        var tokenid : TokenIdentifier = Core.TokenIdentifier.fromText(collection_canister_id, token_index);
        return "https://" #collection_canister_id # ".raw.icp0.io/?&tokenid=" #tokenid;
    };

    public query func getTokenIdentifier(t : Text, i : TokenIndex) : async (TokenIdentifier) {
        return Core.TokenIdentifier.fromText(t, i);
    };

    public query func getOwner(id : Text) : async (Text) {
        var owner : Text = Option.get(Trie.find(_owner, keyT(id), Text.equal), "");
        return owner;
    };

    //Updates
    //
    //create a new nft collection
    public shared (msg) func create_collection(collectionName : Text, creator : Text, data : Text, _height : Nat64) : async (Text) {
        var canID : Text = await create_canister(msg.caller, collectionName, data);
        collections := Trie.put(collections, keyT(canID), Text.equal, collectionName).0;
        _owner := Trie.put(_owner, keyT(canID), Text.equal, creator).0;
        let collection = actor (canID) : actor {
            internal_ext_addAdmin : shared () -> async ();
        };
        await collection.internal_ext_addAdmin();
        return canID;
    };

    //mint to a address/principal, specific number of NFT's
    public shared (msg) func batch_mint_to_addresses(collection_canister_id : Text, p : [Text], j : Text, mint_size : Nat32, _burnAt : Int, assetHandle : Text) : async ([TokenIndex]) {
        var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        var is_minter : Bool = await _isMinter(collection_canister_id, msg.caller);
        assert (msg.caller == Principal.fromText(owner) or is_minter == true);

        var _json : MetadataContainer = #json j;
        var _lowerBound : Nat = 0;
        var _upperBound : Nat = 0;
        var indices : Buffer.Buffer<TokenIndex> = Buffer.Buffer<TokenIndex>(0);

        for (prin in p.vals()) {
            var aid : AccountIdentifier.AccountIdentifier = prin;
            if (aid.size() != 64) {
                aid := AccountIdentifier.fromText(prin, null);
            };
            var _req : (AccountIdentifier, Metadata) = (
                aid,
                #nonfungible {
                    name = assetHandle;
                    asset = assetHandle;
                    thumbnail = assetHandle;
                    metadata = ?_json;
                },
            );
            var i : Nat32 = 0;
            while (i < mint_size) {
                //minting nft
                var token_id : TokenIndex = await _mintNft(collection_canister_id, _req);
                indices.add(token_id);
                _upperBound := Nat32.toNat(token_id);
                i += 1;
            };
        };

        var s : Nat = p.size();
        var _s : Nat = Nat32.toNat(mint_size);
        var ss : Nat = s * _s;
        _upperBound := _upperBound + 1;
        _lowerBound := _upperBound - ss;
        var info : Info = {
            collection = collection_canister_id;
            createdAt = Time.now();
            burnAt = _burnAt;
            lowerBound = _lowerBound;
            upperBound = _upperBound;
            status = "active";
        };
        _info := Trie.put(_info, keyT(assetHandle), Text.equal, info).0;
        return Buffer.toArray(indices);
    };

    //airdrop NFT's to addresses of other EXT std NFT collection
    public shared (msg) func airdrop_to_addresses(collection_canister_id : Text, canid : Text, j : Text, prevent : Bool, _burnAt : Int, assetHandle : Text) : async ([TokenIndex]) {
        var owner : Text = Option.get(Trie.find(_owner, keyT(canid), Text.equal), "");
        var is_minter : Bool = await _isMinter(canid, msg.caller);
        assert (msg.caller == Principal.fromText(owner) or is_minter == true);

        var _json : MetadataContainer = #json j;

        var i : Nat = 0;
        var indices : Buffer.Buffer<TokenIndex> = Buffer.Buffer<TokenIndex>(0);
        let collection = actor (collection_canister_id) : actor {
            getRegistry : () -> async [(TokenIndex, AccountIdentifier)];
        };
        var fetched_addresses : [(TokenIndex, AccountIdentifier)] = await collection.getRegistry();
        var total_mints : Nat = fetched_addresses.size();
        let airdrop_mapping = HashMap.HashMap<AccountIdentifier, Bool>(0, Text.equal, Text.hash); //mapping address to bool, to prevent duplicate airdrops.
        var _lowerBound : Nat = 0;
        var _upperBound : Nat = 0;
        var actually_minted : Nat = 0;
        while (i < total_mints) {
            var id : (TokenIndex, AccountIdentifier) = fetched_addresses[i];
            var _req : (AccountIdentifier, Metadata) = (
                id.1,
                #nonfungible {
                    name = assetHandle;
                    asset = assetHandle;
                    thumbnail = assetHandle;
                    metadata = ?_json;
                },
            );
            if (prevent == false) {
                var token_id : TokenIndex = await _mintNft(canid, _req);
                actually_minted := actually_minted + 1;
                _upperBound := Nat32.toNat(token_id);
                indices.add(token_id);
            } else {
                var isPresent : Bool = Option.get(airdrop_mapping.get(id.1), false);
                if (isPresent == false) {
                    var token_id : TokenIndex = await _mintNft(canid, _req);
                    actually_minted := actually_minted + 1;
                    _upperBound := Nat32.toNat(token_id);
                    indices.add(token_id);
                    airdrop_mapping.put(id.1, true);
                };
            };
            i := i + 1;
        };
        _upperBound := _upperBound + 1;
        _lowerBound := _upperBound - actually_minted;
        var info : Info = {
            collection = canid;
            createdAt = Time.now();
            burnAt = _burnAt;
            lowerBound = _lowerBound;
            upperBound = _upperBound;
            status = "active";
        };
        _info := Trie.put(_info, keyT(assetHandle), Text.equal, info).0;
        return Buffer.toArray(indices);
    };

    //Burn a NFT - by owner
    public shared (msg) func burnNft(collection_canister_id : Text, tokenindex : TokenIndex, aid : AccountIdentifier) : async (Result.Result<Text, CommonError>) {
        assert (AccountIdentifier.fromPrincipal(msg.caller, null) == aid);
        var tokenid : TokenIdentifier = await getTokenIdentifier(collection_canister_id, tokenindex);
        let collection = actor (collection_canister_id) : actor {
            ext_burn : (TokenIdentifier, AccountIdentifier) -> async (Result.Result<(), CommonError>);
        };
        var res : Result.Result<(), CommonError> = await collection.ext_burn(tokenid, aid);
        switch (res) {
            case (#ok) {
                return #ok("burned!");
            };
            case (#err(e)) {
                return #err(e);
            };
        };
    };

    //Burn a NFT - by collection owner
    public shared (msg) func external_burn(collection_canister_id : Text, tokenindex : TokenIndex) : async Result.Result<(), CommonError> {
        var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        assert (msg.caller == Principal.fromText(owner));
        var tokenid : TokenIdentifier = await getTokenIdentifier(collection_canister_id, tokenindex);
        let collection = actor (collection_canister_id) : actor {
            ext_internal_burn : (TokenIdentifier) -> async (Result.Result<(), CommonError>);
        };
        var res : Result.Result<(), CommonError> = await collection.ext_internal_burn(tokenid);
        return res;
    };

    //Burn all NFT's of a collection
    public shared (msg) func bulk_burn_nfts(collection_canister_id : Text) : async () {
        var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        assert (msg.caller == Principal.fromText(owner));
        let collection = actor (collection_canister_id) : actor {
            ext_internal_bulk_burn : (TokenIndex, TokenIndex) -> async ();
        };
        var s : Nat = await getSize(collection_canister_id);
        var res : () = await collection.ext_internal_bulk_burn(0, Nat32.fromNat(s));
    };

    public shared (msg) func upload_asset_to_collection_for_dynamic_mint(collection_canister_id : Text, assetHandle : AssetHandle, chunk : [Nat8]) : async () {
        var owner : Text = Option.get(Trie.find(_owner, keyT(collection_canister_id), Text.equal), "");
        assert (msg.caller == Principal.fromText(owner));
        await _addAsset(collection_canister_id, assetHandle, chunk);
    };

    //Motoko Timer API
    //
    let cron_id : Timer.TimerId = Timer.recurringTimer(#seconds(45 * 60), burn_cron); //to run cron every 45min, to burn batches of NFT's according to their burn_info
    public query func get_last_cron_timestamp() : async (Int) {
        return last_cron_time;
    };

    public query func get_cron_id() : async (Timer.TimerId) {
        return cron_id;
    };

};
