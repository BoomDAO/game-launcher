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
import Deque "mo:base/Deque";
import Map "../utils/Map";

import Parser "../utils/Parser";
import ENV "../utils/Env";
import Utils "../utils/Utils";
import Leaderboard "../modules/Leaderboard";
import RandomExt "../modules/RandomExt";
import EXTCORE "../utils/Core";
import EXT "../types/ext.types";
import AccountIdentifier "../utils/AccountIdentifier";
import ICP "../types/icp.types";
import ICRC "../types/icrc.types";
import TGlobal "../types/global.types";
import TEntity "../types/entity.types";
import TAction "../types/action.types";
import TStaking "../types/staking.types";
import Hex "../utils/Hex";
import Ledger "../modules/Ledger";

import Config "../modules/Configs";
import FormulaEvaluation "../modules/FormulaEvaluation";

actor class WorldTemplate(owner : Principal) = this {

    private func WorldId() : Principal = Principal.fromActor(this);
    private stable var tokensDecimals : Trie.Trie<Text, Nat8> = Trie.empty();
    private stable var tokensFees : Trie.Trie<Text, Nat> = Trie.empty();
    private stable var totalNftCount : Trie.Trie<Text, Nat32> = Trie.empty();
    private stable var userPrincipalToUserNode : Trie.Trie<Text, Text> = Trie.empty();

    //stable memory
    private stable var _owner : Text = Principal.toText(owner);
    private stable var _admins : [Text] = [Principal.toText(owner)];

    //Configs
    private stable var configsStorage : Trie.Trie<Text, TEntity.Config> = Trie.empty();
    private stable var actionsStorage : Trie.Trie<Text, TAction.Action> = Trie.empty();

    private var configs = Buffer.Buffer<TEntity.Config>(0);
    private stable var tempUpdateConfig : Config.StableConfigs = [];

    private var action = Buffer.Buffer<TAction.Action>(0);
    private stable var tempUpdateAction : Config.Actions = [];

    private var randomGenerator = RandomExt.RandomLCG();
    private var seedMod : ?Nat = null;

    //Interfaces
    type UserNode = actor {
        validateConstraints : shared query (uid : TGlobal.userId, wid : TGlobal.worldId, aid : TGlobal.actionId, actionConstraint : ?TAction.ActionConstraint) -> async (Result.Result<TAction.ActionState, Text>);
        applyOutcomes : shared (uid : TGlobal.userId, actionState : TAction.ActionState, outcomes : [TAction.ActionOutcomeOption]) -> async (Result.Result<(), Text>);
        getAllUserEntities : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TEntity.StableEntity], Text>);
        getAllUserActionStates : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TAction.ActionState], Text>);
    };
    type WorldHub = actor {
        createNewUser : shared (Principal) -> async (Result.Result<Text, Text>);
        getUserNodeCanisterId : shared (Text) -> async (Result.Result<Text, Text>);

        grantEntityPermission : shared (TEntity.EntityPermission) -> async ();
        removeEntityPermission : shared (TEntity.EntityPermission) -> async ();
        grantGlobalPermission : shared (TEntity.GlobalPermission) -> async ();
        removeGlobalPermission : shared (TEntity.GlobalPermission) -> async ();
    };

    let worldHub : WorldHub = actor (ENV.WorldHubCanisterId);

    type ICP = actor {
        transfer : shared ICP.TransferArgs -> async ICP.TransferResult;
    };
    type NFT = actor {
        ext_mint : ([(EXT.AccountIdentifier, EXT.Metadata)]) -> async [EXT.TokenIndex];
    };
    type ICRC = actor {
        icrc1_decimals : shared query () -> async Nat8;
        icrc1_fee : shared query () -> async Nat;
    };
    type EXTInterface = actor {
        getTokenMetadata : (EXT.TokenIndex) -> async (?EXT.Metadata);
        ext_burn : (EXT.TokenIdentifier, EXT.AccountIdentifier) -> async (Result.Result<(), EXT.CommonError>);
        ext_transfer : shared (request : EXT.TransferRequest) -> async EXT.TransferResponse;

        getRegistry : query () -> async [(EXT.TokenIndex, EXT.AccountIdentifier)];

        supply : query (EXT.TokenIdentifier) -> async Result.Result<EXT.Balance, EXT.CommonError>;
        get_paged_registry : query (page : Nat32) -> async [(EXT.TokenIndex, EXT.AccountIdentifier)];
    };

    public func upgradeActionsAndConfigsData() : async (Text) {
        for (i in Buffer.toArray(configs).vals()) {
            let fields_array : [(Text, Text)] = Map.toArray(i.fields);

            ignore createConfig({
                cid = i.cid;
                fields = fields_array;
            });
        };

        for (i in Buffer.toArray(action).vals()) {
            ignore createAction(i);
        };

        return ":)";
    };

    system func preupgrade() {
        var b = Buffer.Buffer<TEntity.StableConfig>(0);
        for (i in Buffer.toArray(configs).vals()) {
            let fields_array : [(Text, Text)] = Map.toArray(i.fields);
            b.add({
                cid = i.cid;
                fields = fields_array;
            });
        };
        tempUpdateConfig := Buffer.toArray(b);

        tempUpdateAction := Buffer.toArray(action);
    };
    system func postupgrade() {
        let { thash } = Map;
        for (i in tempUpdateConfig.vals()) {
            configs.add({
                cid = i.cid;
                fields = Map.fromIter(i.fields.vals(), thash);
            });
        };
        tempUpdateConfig := [];
        action := Buffer.fromArray(tempUpdateAction);
        tempUpdateAction := [];
    };

    //Internal Functions
    private func isAdmin_(_p : Principal) : (Bool) {
        var p : Text = Principal.toText(_p);
        for (i in _admins.vals()) {
            if (p == i) {
                return true;
            };
        };
        return false;
    };

    private func tokenFee_(tokenCanisterId : Text) : async (Nat) {
        switch (Trie.find(tokensFees, Utils.keyT(tokenCanisterId), Text.equal)) {
            case (?f) {
                return f;
            };
            case _ {
                let token : ICRC = actor (tokenCanisterId);
                let fee = await token.icrc1_fee();
                tokensFees := Trie.put(tokensFees, Utils.keyT(tokenCanisterId), Text.equal, fee).0;
                return fee;
            };
        };
    };

    private func tokenDecimal_(tokenCanisterId : Text) : async (Nat8) {
        switch (Trie.find(tokensDecimals, Utils.keyT(tokenCanisterId), Text.equal)) {
            case (?d) {
                return d;
            };
            case _ {
                let token : ICRC = actor (tokenCanisterId);
                let decimals = await token.icrc1_decimals();
                tokensDecimals := Trie.put(tokensDecimals, Utils.keyT(tokenCanisterId), Text.equal, decimals).0;
                return decimals;
            };
        };
    };

    private func getUserNode_(userPrincipalTxt : Text) : async (Result.Result<Text, Text>) {

        switch (Trie.find(userPrincipalToUserNode, Utils.keyT(userPrincipalTxt), Text.equal)) {
            case (?userNodeId) {
                return #ok(userNodeId);
            };
            case _ {
                switch (await worldHub.getUserNodeCanisterId(userPrincipalTxt)) {
                    case (#ok(userNodeId)) {
                        userPrincipalToUserNode := Trie.put(userPrincipalToUserNode, Utils.keyT(userPrincipalTxt), Text.equal, userNodeId).0;
                        return #ok(userNodeId);
                    };
                    case (#err(errMsg0)) {
                        var newUserNodeId = await worldHub.createNewUser(Principal.fromText(userPrincipalTxt));
                        switch (newUserNodeId) {
                            case (#ok(userNodeId)) {
                                userPrincipalToUserNode := Trie.put(userPrincipalToUserNode, Utils.keyT(userPrincipalTxt), Text.equal, userNodeId).0;
                                return #ok(userNodeId);
                            };
                            case (#err(errMsg1)) {
                                return #err("user doesnt exist, thus, tried to created it, but failed on the attempt, msg: " # (errMsg0 # " " #errMsg1));
                            };
                        };
                    };
                };
            };
        };
    };
    public shared ({ caller }) func removeAllUserNodeRef() : async () {
        assert (isAdmin_(caller));
        userPrincipalToUserNode := Trie.empty();
    };

    //utils
    public shared ({ caller }) func addAdmin(p : Text) : async () {
        assert (isAdmin_(caller));
        var b : Buffer.Buffer<Text> = Buffer.fromArray(_admins);
        b.add(p);
        _admins := Buffer.toArray(b);
    };

    public shared ({ caller }) func removeAdmin(p : Text) : async () {
        assert (isAdmin_(caller));
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in _admins.vals()) {
            if (i != p) {
                b.add(i);
            };
        };
        _admins := Buffer.toArray(b);
    };

    public query func getOwner() : async Text { return Principal.toText(owner) };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    //GET CONFIG
    private func getSpecificConfig_(cid : Text) : (?TEntity.Config) {
        switch (Trie.find(configsStorage, Utils.keyT(cid), Text.equal)) {
            case (?c) {
                return ?c;
            };
            case _ {
                return null;
            };
        };
    };
    private func getSpecificAction_(aid : Text) : (?TAction.Action) {
        switch (Trie.find(actionsStorage, Utils.keyT(aid), Text.equal)) {
            case (?c) {
                return ?c;
            };
            case _ {
                return null;
            };
        };
    };

    public query func getAllConfigs() : async ([TEntity.StableConfig]) {
        var b = Buffer.Buffer<TEntity.StableConfig>(0);

        for ((cid, c) in Trie.iter(configsStorage)) {
            let fields_array : [(Text, Text)] = Map.toArray(c.fields);
            b.add({
                cid = cid;
                fields = fields_array;
            });
        };
        return Buffer.toArray(b);
    };
    public query func getAllActions() : async ([TAction.Action]) {
        var b = Buffer.Buffer<TAction.Action>(0);

        for ((aid, a) in Trie.iter(actionsStorage)) {
            b.add(a);
        };
        return Buffer.toArray(b);
    };

    public func exportConfigs() : async ([TEntity.StableConfig]) {
        var b = Buffer.Buffer<TEntity.StableConfig>(0);

        for ((cid, c) in Trie.iter(configsStorage)) {
            let fields_array : [(Text, Text)] = Map.toArray(c.fields);
            b.add({
                cid = cid;
                fields = fields_array;
            });
        };
        return Buffer.toArray(b);
    };
    public func exportActions() : async ([TAction.Action]) {
        var b = Buffer.Buffer<TAction.Action>(0);

        for ((aid, a) in Trie.iter(actionsStorage)) {
            b.add(a);
        };
        return Buffer.toArray(b);
    };

    //CHECK CONFIG
    private func configExist_(cid : Text) : (Bool) {
        switch (Trie.find(configsStorage, Utils.keyT(cid), Text.equal)) {
            case (?c) true;
            case _ false;
        };
    };
    private func actionExist_(aid : Text) : (Bool) {
        switch (Trie.find(actionsStorage, Utils.keyT(aid), Text.equal)) {
            case (?c) true;
            case _ false;
        };
    };

    // Edit endpoints to support Candid edit feature
    public shared ({ caller }) func editAction(arg : { aid : Text }) : async (TAction.Action) {
        assert (isAdmin_(caller));

        for (configElement in action.vals()) {
            if (configElement.aid == arg.aid) {
                return configElement;
            };
        };
        return {
            aid = arg.aid;
            callerAction = null;
            targetAction = null;
            name = null;
            description = null;
            imageUrl = null;
            tag = null;
        };
    };

    public shared ({ caller }) func editConfig(arg : { cid : Text }) : async (TEntity.StableConfig) {
        assert (isAdmin_(caller));

        for (configElement in configs.vals()) {
            if (configElement.cid == arg.cid) {
                let fields_array : [(Text, Text)] = Map.toArray(configElement.fields);
                return {
                    cid = configElement.cid;
                    fields = fields_array;
                };
            };
        };
        return {
            cid = arg.cid;
            fields = [];
        };
    };

    //CREATE CONFIG
    public shared ({ caller }) func createConfig(config : TEntity.StableConfig) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller) or caller == WorldId());
        let configExist = configExist_(config.cid);
        if (configExist == false) {
            let { thash } = Map;

            let fields : Map.Map<Text, Text> = Map.fromIter(config.fields.vals(), thash);

            configsStorage := Trie.put(
                configsStorage,
                Utils.keyT(config.cid),
                Text.equal,
                {
                    cid = config.cid;
                    fields = fields;
                },
            ).0;

            return #ok("all good :)");
        };
        return #err("there is an entity already using that id, you can try updateConfig");
    };
    public shared ({ caller }) func createAction(config : TAction.Action) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller) or caller == WorldId());
        let configExist = actionExist_(config.aid);
        if (configExist == false) {

            actionsStorage := Trie.put(actionsStorage, Utils.keyT(config.aid), Text.equal, config).0;

            return #ok("all good :)");
        };
        return #err("there is an action already using that id, you can try updateConfig");
    };
    //UPDATE CONFIG
    public shared ({ caller }) func updateConfig(config : TEntity.StableConfig) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = configExist_(config.cid);
        if (configExist) {
            let { thash } = Map;
            let fields : Map.Map<Text, Text> = Map.fromIter(config.fields.vals(), thash);

            configsStorage := Trie.put(
                configsStorage,
                Utils.keyT(config.cid),
                Text.equal,
                {
                    cid = config.cid;
                    fields = fields;
                },
            ).0;

            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func updateAction(config : TAction.Action) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = actionExist_(config.aid);
        if (configExist) {
            actionsStorage := Trie.put(actionsStorage, Utils.keyT(config.aid), Text.equal, config).0;

            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //DELETE CONFIG
    public shared ({ caller }) func deleteConfig(cid : Text) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = configExist_(cid);
        if (configExist) {

            configsStorage := Trie.remove(configsStorage, Utils.keyT(cid), Text.equal).0;

            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func deleteAction(aid : Text) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = actionExist_(aid);
        if (configExist) {

            actionsStorage := Trie.remove(actionsStorage, Utils.keyT(aid), Text.equal).0;

            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //RESET CONFIG
    public shared ({ caller }) func resetConfig() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));

        configsStorage := Trie.empty();
        let { thash } = Map;
        for (i in Config.configs.vals()) {
            ignore createConfig(i);
        };
        return #ok();
    };

    public shared ({ caller }) func resetActions() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));

        actionsStorage := Trie.empty();

        for (i in Config.action.vals()) {
            ignore createAction(i);
        };

        return #ok();
    };

    //Get Actions
    public func getAllUserActionStates(userPrincipal : Text) : async (Result.Result<[TAction.ActionState], Text>) {
        let worldId = WorldId();

        switch (await getUserNode_(userPrincipal)) {
            case (#ok(userNodeId)) {

                let userNode : UserNode = actor (userNodeId);

                return await userNode.getAllUserActionStates(userPrincipal, Principal.toText(worldId));
            };
            case (#err(message)) {
                return #err(message);
            };
        }; 
    };
    //Get Entities
    public func getAllUserEntities(userPrincipal : Text) : async (Result.Result<[TEntity.StableEntity], Text>) {
        let worldId = WorldId();

        switch (await getUserNode_(userPrincipal)) {
            case (#ok(userNodeId)) {

                let userNode : UserNode = actor (userNodeId);

                return await userNode.getAllUserEntities(userPrincipal, Principal.toText(worldId));
            };
            case (#err(message)) {
                return #err(message);
            };
        };
    };

    //Process Action
    private func generateActionResultOutcomes_(actionResult : TAction.ActionResult, caller : Text, worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : async (Result.Result<[TAction.ActionOutcomeOption], Text>) {
        var outcomes = Buffer.Buffer<TAction.ActionOutcomeOption>(0);
        for (outcome in actionResult.outcomes.vals()) {
            var accumulated_weight : Float = 0;
            var randPerc : Float = 1;

            //A) Compute total weight on the current outcome
            if (outcome.possibleOutcomes.size() > 1) {
                for (outcomeOption in outcome.possibleOutcomes.vals()) {
                    accumulated_weight += outcomeOption.weight;
                };

                //B) Gen a random number using the total weight as max value
                switch seedMod {
                    case (?_seedMod) {
                        randPerc := randomGenerator.genAsPerc(_seedMod);
                    };
                    case _ {
                        let trueRandom = await RandomExt.getRandomNat(999999999999);
                        seedMod := ?trueRandom;
                        randPerc := randomGenerator.genAsPerc(trueRandom);
                    };
                };
            };

            var dice_outcome = (randPerc * 1.0 * accumulated_weight);

            //C Pick outcomes base on their weights
            label outcome_loop for (outcomeOption in outcome.possibleOutcomes.vals()) {
                let outcome_weight = outcomeOption.weight;
                if (outcome_weight >= dice_outcome) {

                    switch (refineOutcome_(outcomeOption, caller, worldData, callerData, targetData)) {
                        case (#ok refinedOutcome) outcomes.add(refinedOutcome);
                        case (#err errMsg) return #err errMsg;
                    };

                    break outcome_loop;
                } else {
                    dice_outcome -= outcome_weight;
                };
            };
        };

        return #ok(Buffer.toArray(outcomes));
    };

    private func refineOutcome_(outcome : TAction.ActionOutcomeOption, caller : Text, worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<TAction.ActionOutcomeOption, Text>) {
        switch (outcome.option) {

            case (#updateEntity updateEntity) {

                var gid = updateEntity.gid;
                if (gid == "") gid := "general";
                var eid = updateEntity.eid;
                if (Text.contains(eid, #text "$caller")) eid := caller;

                switch (updateEntity.updateType) {
                    case (#setNumber updateType) {

                        switch (updateType.value) {
                            case (#formula formula) {

                                var number = 0.0;
                                switch (evaluateFormula(formula, worldData, callerData, targetData)) {
                                    case (#ok(_number)) number := _number;
                                    case (#err errMsg) return #err errMsg;
                                };

                                return #ok {
                                    weight = outcome.weight;
                                    option = #updateEntity {
                                        wid = updateEntity.wid;
                                        gid = gid;
                                        eid = eid;
                                        updateType = #setNumber {
                                            field = updateType.field;
                                            value = #number number;
                                        };
                                    };
                                };
                            };
                            case (_) {};
                        };

                    };
                    case (#decrementNumber updateType) {

                        switch (updateType.value) {
                            case (#formula formula) {

                                var number = 0.0;
                                switch (evaluateFormula(formula, worldData, callerData, targetData)) {
                                    case (#ok(_number)) number := _number;
                                    case (#err errMsg) return #err errMsg;
                                };

                                return #ok {
                                    weight = outcome.weight;
                                    option = #updateEntity {
                                        wid = updateEntity.wid;
                                        gid = gid;
                                        eid = eid;
                                        updateType = #decrementNumber {
                                            field = updateType.field;
                                            value = #number number;
                                        };
                                    };
                                };
                            };
                            case (_) {};
                        };

                    };
                    case (#incrementNumber updateType) {

                        switch (updateType.value) {
                            case (#formula formula) {

                                var number = 0.0;
                                switch (evaluateFormula(formula, worldData, callerData, targetData)) {
                                    case (#ok(_number)) number := _number;
                                    case (#err errMsg) return #err errMsg;
                                };

                                return #ok {
                                    weight = outcome.weight;
                                    option = #updateEntity {
                                        wid = updateEntity.wid;
                                        gid = gid;
                                        eid = eid;
                                        updateType = #incrementNumber {
                                            field = updateType.field;
                                            value = #number number;
                                        };
                                    };
                                };
                            };
                            case (_) {};
                        };

                    };
                    case (#renewTimestamp updateType) {

                        switch (updateType.value) {
                            case (#formula formula) {

                                var number = 0.0;
                                switch (evaluateFormula(formula, worldData, callerData, targetData)) {
                                    case (#ok(_number)) number := _number;
                                    case (#err errMsg) return #err errMsg;
                                };

                                return #ok {
                                    weight = outcome.weight;
                                    option = #updateEntity {
                                        wid = updateEntity.wid;
                                        gid = gid;
                                        eid = eid;
                                        updateType = #renewTimestamp {
                                            field = updateType.field;
                                            value = #number number;
                                        };
                                    };
                                };
                            };
                            case (_) {};
                        };

                    };
                    case (#setText updateType){

                        if(Text.contains(updateType.value, #text "$caller")){
                            return #ok {
                                weight = outcome.weight;
                                option = #updateEntity {
                                    wid = updateEntity.wid;
                                    gid = gid;
                                    eid = eid;
                                    updateType = #setText {
                                        field = updateType.field;
                                        value = caller;
                                    };
                                };
                            };
                        };
                    };
                    case _ {};
                };

                return #ok {
                    weight = outcome.weight;
                    option = #updateEntity {
                        wid = updateEntity.wid;
                        gid = gid;
                        eid = eid;
                        updateType = updateEntity.updateType;
                    };
                };
                //
            };
            case _ {};
        };

        return #ok outcome;
    };

    private func mint_(nftCanisterId : Text, mintsToProcess : [(EXT.AccountIdentifier, EXT.Metadata)]) : async ([TAction.MintNft]) {
        let nftCollection : NFT = actor (nftCanisterId);

        var amountToMint = mintsToProcess.size();
        var mintedNfts = Buffer.Buffer<TAction.MintNft>(amountToMint);

        switch (Trie.find(totalNftCount, Utils.keyT(nftCanisterId), Text.equal)) {
            case (?collectionNftCount) {
                //MINT NFTs
                ignore nftCollection.ext_mint(mintsToProcess);

                //WE PREPARE THE RETURN VALUE
                var loopIndex : Nat32 = 0;
                for (mintToProcess in mintsToProcess.vals()) {
                    var assetId = "";
                    var metadata = "";
                    let optinalMetadata = mintToProcess.1;

                    //HERE ASSET ID AND METADATA ARE EXTRACTED "IF ANY"
                    switch (optinalMetadata) {
                        case (#nonfungible asNonfungible) {
                            //WE SET ASSET ID
                            assetId := asNonfungible.asset;

                            //WE SET METADATA "ONLY IF IT IS A JSON"
                            switch (asNonfungible.metadata) {
                                case (? #json asJson) {
                                    metadata := asJson;
                                };
                                case _ {}; //WE DO NOTHING HERE
                            };
                        };
                        case _ {}; //WE DO NOTHING HERE
                    };

                    //WE ADD THE MINTED NFT INTO THE BUFFER TO RETURN IT AS AN ARRAY
                    mintedNfts.add({
                        index = ?(collectionNftCount + loopIndex);
                        canister = nftCanisterId;
                        assetId;
                        metadata;
                    });

                    loopIndex += 1;
                };

                //WE STORE THE NEW COLLECTION NFT COUNT
                totalNftCount := Trie.put(totalNftCount, Utils.keyT(nftCanisterId), Text.equal, collectionNftCount + Nat32.fromNat(amountToMint)).0;
            };
            case _ {
                //IF COLLECTION COUNT WASN'T STORED
                //MINT NFTs
                var mintedIndexes = await nftCollection.ext_mint(mintsToProcess);

                //WE PREPARE THE RETURN VALUE
                var loopIndex = 0;
                for (mintedIndex in mintedIndexes.vals()) {
                    var assetId = "";
                    var metadata = "";
                    let optinalMetadata = mintsToProcess[loopIndex].1;

                    //HERE ASSET ID AND METADATA ARE EXTRACTED "IF ANY"
                    switch (optinalMetadata) {
                        case (#nonfungible asNonfungible) {
                            //WE SET ASSET ID
                            assetId := asNonfungible.asset;

                            //WE SET METADATA "ONLY IF IT IS A JSON"
                            switch (asNonfungible.metadata) {
                                case (? #json asJson) {
                                    metadata := asJson;
                                };
                                case _ {}; //WE DO NOTHING HERE
                            };
                        };
                        case _ {}; //WE DO NOTHING HERE
                    };

                    //WE ADD THE MINTED NFT INTO THE BUFFER TO RETURN IT AS AN ARRAY
                    mintedNfts.add({
                        index = ?mintedIndex;
                        canister = nftCanisterId;
                        assetId;
                        metadata;
                    });

                    loopIndex += 1;
                };

                //WE STORE THE NEW COLLECTION NFT COUNT
                totalNftCount := Trie.put(totalNftCount, Utils.keyT(nftCanisterId), Text.equal, mintedIndexes[mintedIndexes.size() - 1] + 1).0;
            };
        };

        return Buffer.toArray(mintedNfts);
    };

    private func applyOutcomes_(userPrincipalTxt : Text, userNode : UserNode, actionState : TAction.ActionState, outcomes : [TAction.ActionOutcomeOption]) : async ([TAction.ActionOutcomeOption]) {

        ignore userNode.applyOutcomes(userPrincipalTxt, actionState, outcomes);

        // switch applyOutcomeResult {
        //     case (#ok(a)) {};
        //     case (#err err) return #err err;
        // };

        let accountId : Text = AccountIdentifier.fromText(userPrincipalTxt, null);

        var processedResult = Buffer.Buffer<TAction.ActionOutcomeOption>(0);

        var nftsToMint : Trie.Trie<Text, Buffer.Buffer<(EXT.AccountIdentifier, EXT.Metadata)>> = Trie.empty();

        //Group Nfts by collections
        for (outcome in outcomes.vals()) {
            switch (outcome.option) {
                case (#mintNft val) {
                    switch (Trie.find(nftsToMint, Utils.keyT(val.canister), Text.equal)) {
                        case (?element) {
                            element.add((
                                accountId,
                                #nonfungible {
                                    name = "";
                                    asset = val.assetId;
                                    thumbnail = val.assetId;
                                    metadata = ? #json(val.metadata);
                                },
                            ));

                            nftsToMint := Trie.put(nftsToMint, Utils.keyT(val.canister), Text.equal, element).0;
                        };
                        case _ {
                            let newElement = Buffer.Buffer<(EXT.AccountIdentifier, EXT.Metadata)>(1);

                            newElement.add((
                                accountId,
                                #nonfungible {
                                    name = "";
                                    asset = val.assetId;
                                    thumbnail = val.assetId;
                                    metadata = ? #json(val.metadata);
                                },
                            ));
                            nftsToMint := Trie.put(nftsToMint, Utils.keyT(val.canister), Text.equal, newElement).0;
                        };
                    };
                };
                case _ {};
            };
        };

        //MintNfts and add them to processedResult
        for ((nftCanisterId, nftGroup) in Trie.iter(nftsToMint)) {
            var mintedNfts = await mint_(nftCanisterId, Buffer.toArray(nftGroup));

            for (mintedNft in mintedNfts.vals()) {
                processedResult.add({ weight = 0; option = #mintNft mintedNft });
            };
        };

        //Mint Tokens and add them along with entities to the return value
        for (outcome in outcomes.vals()) {
            switch (outcome.option) {
                case (#mintNft val) {
                    //DO NOTHING HERE
                };
                //Mint Tokens
                case (#transferIcrc val) {
                    //
                    processedResult.add(outcome);
                    //
                    let icrcLedger : ICRC.Self = actor (val.canister);
                    let fee = await tokenFee_(val.canister);
                    let decimals = await tokenDecimal_(val.canister);

                    //IF YOU WANT TO HANDLE ERRORS COMMENT OUT THIS CODE AND UNCOMMENT OUT THE ONE BELOW
                    ignore icrcLedger.icrc1_transfer({
                        to = {
                            owner = Principal.fromText(userPrincipalTxt);
                            subaccount = null;
                        };
                        fee = ?fee;
                        memo = ?[];
                        from_subaccount = null;
                        created_at_time = null;
                        amount = Utils.convertToBaseUnit(val.quantity, decimals);
                    });

                    // var transferResult = await icrcLedger.icrc1_transfer({
                    //     to  = {owner = Principal.fromText(uid); subaccount = null};
                    //     fee = ? fee;
                    //     memo = ? [];
                    //     from_subaccount = null;
                    //     created_at_time = null;
                    //     amount = Utils.convertToBaseUnit(val.quantity, decimals);
                    // });

                    // switch(transferResult){
                    //     case (#Err errorType){
                    //         switch(errorType){
                    //             case(#GenericError error){ return #err("GenericError")};
                    //             case(#TemporarilyUnavailable error){return #err("TemporarilyUnavailable")};
                    //             case(#BadBurn error){return #err("BadBurn")};
                    //             case(#Duplicate error){return #err("Duplicate")};
                    //             case(#BadFee error){return #err("BadFee")};
                    //             case(#CreatedInFuture error){return #err("CreatedInFuture")};
                    //             case(#TooOld error){return #err("TooOld")};
                    //             case(#InsufficientFunds error){return #err("InsufficientFunds")};
                    //         }
                    //     };
                    //     case(_){};
                    // }
                };
                case _ {
                    processedResult.add(outcome);
                };
            };
        };

        return Buffer.toArray(processedResult);
    };

    public shared ({ caller }) func processAction(actionArg : TAction.ActionArg) : async (Result.Result<TAction.ActionReturn, Text>) {
        //Todo: Check for each action the timeConstraint
        let actionId = actionArg.actionId;
        let optTargetPrincipalId = actionArg.targetPrincipalId;

        var callerAction : TAction.SubAction = {
            actionConstraint = null;
            actionResult = { outcomes = [] };
        };
        var targetAction : TAction.SubAction = {
            actionConstraint = null;
            actionResult = { outcomes = [] };
        };

        var callerPrincipalId = Principal.toText(caller);
        var validCallerSubAction = false;

        var targetPrincipalId : Text = "";
        var hasTargetPrincipalId = false;
        var hasSubActionTarget = false;

        //CHECK IF ACTION EXIST TO TRY SETUP BOTH CALLER AND TARGET SUB ACTIONS
        switch (getSpecificAction_(actionId)) {
            case (?_action) {

                //SETUP CALLER ACTION
                switch (_action.callerAction) {
                    case (?_callerAction) {
                        callerAction := _callerAction;
                        validCallerSubAction := true;
                    };
                    case (_) {};
                };

                //TRY SETUP TARGET ACTION
                switch (_action.targetAction) {
                    case (?_targetAction) {
                        targetAction := _targetAction;
                        hasSubActionTarget := true;
                    };
                    case (_) {};
                };
            };
            case (_) {
                return #err("Failure to find action with key " # actionId);
            };
        };

        //SETUP TARGET PRINCIPAL ID
        switch (optTargetPrincipalId) {
            case (?_targetPrincipalId) {
                targetPrincipalId := _targetPrincipalId;
                hasTargetPrincipalId := true;
            };
            case (_) {};
        };

        var worldData : [TEntity.StableEntity] = [];
        var callerData : [TEntity.StableEntity] = [];
        var targetData : ?[TEntity.StableEntity] = null;

        var nodesResult = await getNodesData_(callerPrincipalId, optTargetPrincipalId);

        switch nodesResult {
            case (#ok(nodes)) {
                worldData := nodes.0;
                callerData := nodes.1;
                targetData := nodes.2;
            };
            case (#err(errMsg)) return #err errMsg;
        };

        //CHECK IF IT IS COMPOUND ACTION OR NORMAL ACTION
        let validTargetSubAction = hasTargetPrincipalId and hasSubActionTarget;

        let isCompoundCall = validTargetSubAction and validCallerSubAction;

        if (isCompoundCall) {

            var worldId : Text = Principal.toText(Principal.fromActor(this));

            //FETCH NODES IDS
            var callerNodeId : Text = "2vxsx-fae";
            var targetNodeId : Text = "2vxsx-fae";

            switch (await getUserNode_(callerPrincipalId)) {
                case (#ok(content)) { callerNodeId := content };
                case (#err(message)) {
                    return #err(message);
                };
            };

            switch (await getUserNode_(targetPrincipalId)) {
                case (#ok(content)) { targetNodeId := content };
                case (#err(message)) {
                    return #err(message);
                };
            };

            let callerNode : UserNode = actor (callerNodeId);
            let targetNode : UserNode = actor (targetNodeId);

            //VALIDATE OUTCOMES AND FETCH ACTION STATES
            var callerActionState : TAction.ActionState = {
                actionId = "";
                intervalStartTs = 0;
                actionCount = 0;
            };
            var targetActionState : TAction.ActionState = {
                actionId = "";
                intervalStartTs = 0;
                actionCount = 0;
            };

            var callerActionStateResultHandler = callerNode.validateConstraints(callerPrincipalId, worldId, actionId, callerAction.actionConstraint);
            var targetActionStateResultHandler = targetNode.validateConstraints(targetPrincipalId, worldId, actionId, targetAction.actionConstraint);

            switch (await callerActionStateResultHandler) {
                case (#ok(result)) { callerActionState := result };
                case (#err(message)) {
                    return #err(message);
                };
            };

            switch (await targetActionStateResultHandler) {
                case (#ok(result)) { targetActionState := result };
                case (#err(message)) {
                    return #err(message);
                };
            };

            //GENERATE OUTCOMES
            var callerGeneratedOutcomesResultHandler = generateActionResultOutcomes_(callerAction.actionResult, callerPrincipalId, worldData, callerData, targetData);
            var targetGeneratedOutcomesResultHandler = generateActionResultOutcomes_(targetAction.actionResult, callerPrincipalId, worldData, callerData, targetData);

            var callerGeneratedOutcomesResult = await callerGeneratedOutcomesResultHandler;
            var targetGeneratedOutcomesResult = await targetGeneratedOutcomesResultHandler;

            switch callerGeneratedOutcomesResult {
                case (#ok(callerGeneratedOutcomes)) {

                    switch targetGeneratedOutcomesResult {
                        case (#ok(targetGeneratedOutcomes)) {

                            //APPLY OUTCOMES
                            let callerOutcomesHandler = applyOutcomes_(callerPrincipalId, callerNode, callerActionState, callerGeneratedOutcomes);
                            let targetOutcomesHandler = applyOutcomes_(targetPrincipalId, targetNode, targetActionState, targetGeneratedOutcomes);
                            
                            let callerOutcomes = await callerOutcomesHandler;
                            let targetOutcomes = await targetOutcomesHandler;

                            //RETURN CALLER OUTCOME
                            return #ok({
                                callerOutcomes = ? callerOutcomes;
                                targetOutcomes = ? targetOutcomes;
                            });
                        };
                        case (#err(errMsg)) return #err errMsg;
                    };

                };
                case (#err(errMsg)) return #err errMsg;
            };
        } else if (validTargetSubAction) {
            //GENERATE OUTCOMES
            var targetGeneratedOutcomesResult = await generateActionResultOutcomes_(targetAction.actionResult, callerPrincipalId, worldData, callerData, targetData);

            switch targetGeneratedOutcomesResult {
                case (#ok(targetGeneratedOutcomes)) {

                    var actionResult = await processAction_(targetPrincipalId, actionId, targetAction.actionConstraint, targetGeneratedOutcomes);

                    switch actionResult {
                        case (#ok(outcomes)) {

                            //RETURN CALLER OUTCOME
                            return #ok({
                                callerOutcomes = null;
                                targetOutcomes = ? outcomes;
                            });

                        };
                        case (#err err) return #err err;
                    };
                };
                case (#err(errMsg)) return #err errMsg;
            };
        } else if (validCallerSubAction) {
            //GENERATE OUTCOMES
            var callerGeneratedOutcomesResult = await generateActionResultOutcomes_(callerAction.actionResult, callerPrincipalId, worldData, callerData, targetData);

            switch callerGeneratedOutcomesResult {
                case (#ok(callerGeneratedOutcomes)) {

                    var actionResult = await processAction_(callerPrincipalId, actionId, callerAction.actionConstraint, callerGeneratedOutcomes);

                    switch actionResult {
                        case (#ok outcomes) {

                            //RETURN CALLER OUTCOME
                            return #ok({
                                callerOutcomes = ?outcomes;
                                targetOutcomes = null;
                            });

                        };
                        case (#err err) return #err err;
                    };
                };
                case (#err(errMsg)) return #err errMsg;
            };
        } else {
            return #err("Failure to execute action, it requires at least a subaction declared");
        };
    };

    private func processAction_(principalId : Text, actionId : Text, actionConstraint : ?TAction.ActionConstraint, outcomes : [TAction.ActionOutcomeOption]) : async (Result.Result<[TAction.ActionOutcomeOption], Text>) {

        var worldId : Text = Principal.toText(Principal.fromActor(this));

        //FETCH NODES IDS
        var nodeId : Text = "2vxsx-fae";

        switch (await getUserNode_(principalId)) {
            case (#ok(content)) { nodeId := content };
            case (#err(message)) {
                return #err message;
            };
        };

        let node : UserNode = actor (nodeId);

        //VALIDATE OUTCOMES AND FETCH ACTION STATES
        var actionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
        };
        var actionStateResult = await node.validateConstraints(principalId, worldId, actionId, actionConstraint);

        switch (actionStateResult) {
            case (#ok(content)) { actionState := content };
            case (#err(message)) {
                return #err message;
            };
        };

        //APPLY OUTCOMES
        var applyOutcomeResult = await applyOutcomes_(principalId, node, actionState, outcomes);

        return #ok applyOutcomeResult;
    };

    // for permissions
    public shared ({ caller }) func grantEntityPermission(permission : TEntity.EntityPermission) : async () {
        assert (isAdmin_(caller));
        await worldHub.grantEntityPermission(permission);
    };

    public shared ({ caller }) func removeEntityPermission(permission : TEntity.EntityPermission) : async () {
        assert (isAdmin_(caller));
        await worldHub.removeEntityPermission(permission);
    };

    public shared ({ caller }) func grantGlobalPermission(permission : TEntity.GlobalPermission) : async () {
        assert (isAdmin_(caller));
        await worldHub.grantGlobalPermission(permission);
    };

    public shared ({ caller }) func removeGlobalPermission(permission : TEntity.GlobalPermission) : async () {
        assert (isAdmin_(caller));
        await worldHub.removeGlobalPermission(permission);
    };

    // Import other worlds Configs endpoints
    public shared ({ caller }) func importAllConfigsOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let world = actor (ofWorldId) : actor {
            exportConfigs : shared () -> async ([TEntity.StableConfig]);
        };
        let { thash } = Map;
        configsStorage := Trie.empty();
        for (i in (await world.exportConfigs()).vals()) {
            ignore createConfig(i);
        };
        return #ok("imported");
    };
    public shared ({ caller }) func importAllActionsOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let world = actor (ofWorldId) : actor {
            exportActions : shared () -> async ([TAction.Action]);
        };

        actionsStorage := Trie.empty();

        for (i in (await world.exportActions()).vals()) {
            ignore createAction(i);
        };

        return #ok("imported");
    };

    public shared ({ caller }) func withdrawIcpFromWorld(toPrincipal : Text) : async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>) {
        assert (caller == owner);
        let ICP_Ledger : Ledger.ICP = actor (ENV.Ledger);
        var _amt = await ICP_Ledger.account_balance({
            account = Hex.decode(AccountIdentifier.fromText(Principal.toText(WorldId()), null));
        });
        _amt := {
            e8s = _amt.e8s - 10000;
        };
        var _req : ICP.TransferArgs = {
            to = Hex.decode(AccountIdentifier.fromText(toPrincipal, null));
            fee = {
                e8s = 10000;
            };
            memo = 0;
            from_subaccount = null;
            created_at_time = null;
            amount = _amt;
        };
        var res : ICP.TransferResult = await ICP_Ledger.transfer(_req);
        switch (res) {
            case (#Ok blockIndex) {
                return #ok(res);
            };
            case (#Err e) {
                let err : { #TxErr : ICP.TransferError; #Err : Text } = #TxErr e;
                return #err(err);
            };
        };
    };

    public shared ({ caller }) func withdrawIcrcFromWorld(tokenCanisterId : Text, toPrincipal : Text) : async (Result.Result<ICRC.Result, { #TxErr : ICRC.TransferError; #Err : Text }>) {
        assert (caller == owner);
        let ICRC_Ledger : Ledger.ICRC1 = actor (tokenCanisterId);
        var _amt = await ICRC_Ledger.icrc1_balance_of({
            owner = WorldId();
            subaccount = null;
        });
        var _fee = await ICRC_Ledger.icrc1_fee();
        _amt := _amt - _fee;
        var _req : ICRC.TransferArg = {
            to = {
                owner = Principal.fromText(toPrincipal);
                subaccount = null;
            };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = _amt;
        };
        var res : ICRC.Result = await ICRC_Ledger.icrc1_transfer(_req);
        switch (res) {
            case (#Ok blockIndex) {
                return #ok(res);
            };
            case (#Err e) {
                let err : { #TxErr : ICRC.TransferError; #Err : Text } = #TxErr e;
                return #err(err);
            };
        };
    };

    public shared ({ caller }) func getEntityPermissionsOfWorld() : async [(Text, [(Text, TEntity.EntityPermission)])] {
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            getEntityPermissionsOfWorld : () -> async ([(Text, [(Text, TEntity.EntityPermission)])]);
        };
        return (await worldHub.getEntityPermissionsOfWorld());
    };

    public shared ({ caller }) func getGlobalPermissionsOfWorld() : async ([TGlobal.worldId]) {
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            getGlobalPermissionsOfWorld : () -> async [TGlobal.userId];
        };
        return (await worldHub.getGlobalPermissionsOfWorld());
    };

    public shared ({ caller }) func importAllUsersDataOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            importAllUsersDataOfWorld : (Text) -> async (Result.Result<Text, Text>);
        };
        return (await worldHub.importAllUsersDataOfWorld(ofWorldId));
    };

    public shared ({ caller }) func importAllPermissionsOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            importAllPermissionsOfWorld : (Text) -> async (Result.Result<Text, Text>);
        };
        return (await worldHub.importAllPermissionsOfWorld(ofWorldId));
    };

    public func testRecursion(index : Nat, count : Nat, failAt : Nat) : async (Result.Result<Text, Text>) {
        return testRecursion_(index, count, failAt);
    };

    private func testRecursion_(index : Nat, count : Nat, failAt : Nat) : (Result.Result<Text, Text>) {
        var name : Text = "Jack";
        var extra : Text = "";

        if (index == failAt) return #err("Failure success at " #Nat.toText(index));
        if (index < count) {
            switch (testRecursion_(index + 1, count, failAt)) {
                case (#ok val) {
                    extra := "," #val;
                };
                case (#err e) {
                    return #err e;
                };
            };
        };

        return #ok(name #Nat.toText(index) #extra);
    };

    //HANDLE FORMULAS
    private func getEntityField(entities : [TEntity.StableEntity], gid : Text, eid : Text, fieldName : Text) : (fieldValue : ?Text) {
        for (entity in entities.vals()) {
            if (entity.gid == gid and entity.eid == eid) {
                var fields = entity.fields;

                for (field in fields.vals()) {
                    if (field.0 == fieldName) return ?field.1;
                };
            };
        };

        return null;
    };

    private func replaceVariables(formula : Text, worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<Text, Text>) {
        var temp = "";
        var isOpen = false;
        var index = 0;
        var returnValue = formula;
        let formulaTokensLength : Int = Text.size(formula);
        let tokens = Text.toArray(formula);

        for (token in tokens.vals()) {
            if (isOpen) {
                temp := Text.concat(temp, Text.fromChar(token));

            };

            if (token == '{') {
                isOpen := true;
            } else if (index < formulaTokensLength - 1) {

                var nextToken = tokens[index + 1];

                if (nextToken == '}') {
                    isOpen := false;
                };
            };

            //

            if (isOpen == false and Text.size(temp) > 0) {
                let variable = temp;
                temp := "";

                var fieldNameElements = Iter.toArray(Text.split(variable, #char '.'));

                //Entity field
                if (fieldNameElements.size() == 4) {
                    let source = fieldNameElements[0];
                    let entityGroupId = fieldNameElements[1];
                    let entityEntityId = fieldNameElements[2];
                    let entityFieldName = fieldNameElements[3];
                    var entityFieldValue = "";

                    if (source == "$caller") {
                        switch (getEntityField(callerData, entityGroupId, entityEntityId, entityFieldName)) {
                            case (?_entityFieldValue) entityFieldValue := _entityFieldValue;
                            case _ return #err("could not find field of source: " #source # " gid: " #entityGroupId # " eid: " #entityEntityId # " fieldName: " #entityFieldName);
                        };
                    } else if (source == "$target") {

                        switch targetData {
                            case (?value) {
                                if (value.size() == 0) return #err "target data is empty";

                                switch (getEntityField(value, entityGroupId, entityEntityId, entityFieldName)) {
                                    case (?_entityFieldValue) entityFieldValue := _entityFieldValue;
                                    case _ return #err("could not find field of source: " #source # " gid: " #entityGroupId # " eid: " #entityEntityId # " fieldName: " #entityFieldName);
                                };
                            };
                            case _ return #err "target data is null";
                        };
                    } else if (source == "$world") {
                        switch (getEntityField(worldData, entityGroupId, entityEntityId, entityFieldName)) {
                            case (?_entityFieldValue) entityFieldValue := _entityFieldValue;
                            case _ return #err("could not find field of source: " #source # " gid: " #entityGroupId # " eid: " #entityEntityId # " fieldName: " #entityFieldName);
                        };
                    };

                    returnValue := Text.replace(returnValue, #text("{" #variable # "}"), entityFieldValue);
                }
                //Config field
                else if (fieldNameElements.size() == 3) {
                    if (fieldNameElements[0] == "$config") {

                    };
                };

                // do variable replacement using the fieldName
            };

            index += 1;
        };

        return #ok returnValue;
    };

    private func getNodesData_(callerPrincipalId : Text, targetPrincipalId : ?Text) : async (Result.Result<(worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]), Text>) {
        var worldNodeId = "";
        var callerNodeId = "";
        var targetNodeId = "";

        var worldData : [TEntity.StableEntity] = [];
        var callerData : [TEntity.StableEntity] = [];
        var targetData : ?[TEntity.StableEntity] = null;

        let worldId : Text = Principal.toText(WorldId());

        var hasTarget = false;
        var _targetPrincipalId = "";

        switch targetPrincipalId {
            case (?value) {
                hasTarget := true;
                _targetPrincipalId := value;
            };
            case _ {};
        };

        //FETCH ENTITIES AND SETUP ENTITIES ARRAYS
        let getWorldEntitiesHandler = getAllUserEntities(worldId);

        let getCallerEntitiesHandler = getAllUserEntities(callerPrincipalId);

        if (hasTarget) {
            let getTargetEntitiesHandler = getAllUserEntities(_targetPrincipalId);

            let targetDataResult = await getTargetEntitiesHandler;

            switch targetDataResult {
                case (#ok data) targetData := ?data;
                case (#err errMessage) return #err errMessage;
            };
        };

        let worldDataResult = await getWorldEntitiesHandler;

        let callerDataResult = await getCallerEntitiesHandler;

        switch worldDataResult {
            case (#ok data) worldData := data;
            case (#err errMessage) return #err errMessage;
        };

        switch callerDataResult {
            case (#ok data) callerData := data;
            case (#err errMessage) return #err errMessage;
        };

        return #ok(worldData, callerData, targetData);
    };
    //To be able to access entities fields of "caller" "target" and "world"; and to also be able to access configs
    private func evaluateFormula(formula : Text, worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<Float, Text>) {
        var _formula = Text.trimStart(formula, #char ' ');
        _formula := Text.trimEnd(formula, #char ' ');
        //REPLACE VARIABLES

        switch (replaceVariables(_formula, worldData, callerData, targetData)) {
            case (#ok value) {
                _formula := value;
            };
            case (#err errMsg) return #err errMsg;
        };

        //EXECUTE FORMULA
        return FormulaEvaluation.evaluate(_formula);
    };
};
