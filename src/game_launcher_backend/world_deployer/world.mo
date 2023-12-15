//# IMPORTS
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
import Int64 "mo:base/Int64";
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

import TConstraints "../types/constraints.types";
import IcWebSocketCdk "mo:ic-websocket-cdk";

import V1TGlobal "../migrations/v1.global.types";
import V1TEntity "../migrations/v1.entity.types";
import V1TAction "../migrations/v1.action.types";

actor class WorldTemplate() = this {

    //# FIELDS
    private func WorldId() : Principal = Principal.fromActor(this);

    private stable var processActionCount : Nat = 0;
    private stable var tokensDecimals : Trie.Trie<Text, Nat8> = Trie.empty(); //token_canister_id -> decimals
    private stable var tokensFees : Trie.Trie<Text, Nat> = Trie.empty(); //token_canister_id -> fees
    private stable var totalNftCount : Trie.Trie<Text, Nat32> = Trie.empty();
    private stable var userPrincipalToUserNode : Trie.Trie<Text, Text> = Trie.empty();

    //stable memory
    private stable var owner : Principal = Principal.fromText("2vxsx-fae");
    private stable var _owner : Text = Principal.toText(owner);
    private stable var _admins : [Text] = [Principal.toText(owner)];

    //Configs
    // empty stable memory used for migration
    private stable var v1configsStorage : Trie.Trie<Text, V1TEntity.Config> = Trie.empty();
    private stable var v1actionsStorage : Trie.Trie<Text, V1TAction.Action> = Trie.empty();

    // active data of stable memory
    private stable var configsStorage : Trie.Trie<Text, TEntity.Config> = Trie.empty();
    private stable var actionsStorage : Trie.Trie<Text, TAction.Action> = Trie.empty();

    private var randomGeneratorGacha = RandomExt.RandomLCG();

    private stable var indexedKeyCount = 0;

    private var seedMod : ?Nat = null;

    let { ihash; nhash; thash; phash; calcHash } = Map;

    var worldPrincipalId = "";

    //# INTERFACES
    type UserNode = actor {
        createEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId, fields : [TGlobal.Field]) -> async (Result.Result<Text, Text>);
        editEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId, fields : [TGlobal.Field]) -> async (Result.Result<Text, Text>);
        deleteEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId) -> async (Result.Result<Text, Text>);
        applyOutcomes : shared (uid : TGlobal.userId, actionState : TAction.ActionState, outcomes : [TAction.ActionOutcomeOption]) -> async (Result.Result<(), Text>);
        getAllUserEntities : shared (uid : TGlobal.userId, wid : TGlobal.worldId, page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
        getAllUserActionStates : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TAction.ActionState], Text>);
        getActionState : query (uid : TGlobal.userId, wid : TGlobal.worldId, aid : TGlobal.actionId) -> async (?TAction.ActionState);
        getEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId) -> async (TEntity.StableEntity);
        getAllUserEntitiesOfSpecificWorlds : shared (uid : TGlobal.userId, wids : [TGlobal.worldId], page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>)
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

    type PaymentHub = actor {
        verifyTxIcp : shared (Nat64, Text, Text, Nat64) -> async ({
            #Success : Text;
            #Err : Text;
        });
        verifyTxIcrc : shared (Nat, Text, Text, Nat, Text) -> async ({
            #Success : Text;
            #Err : Text;
        });
    };

    let paymentHub : PaymentHub = actor (ENV.PaymentHubCanisterId);

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

    //# UPGRADE FUNCTIONS

    system func preupgrade() {
        v1configsStorage := configsStorage;
        v1actionsStorage := actionsStorage;
    };
    system func postupgrade() {
        worldPrincipalId := Principal.toText(WorldId());
    };

    //# INTERNAL FUNCTIONS
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

    public shared ({ caller }) func updateOwnership(arg : Principal) : async () {
        assert (caller == Principal.fromText(ENV.WorldDeployerCanisterId));
        owner := arg;
        _admins := [Principal.toText(owner)];
        _owner := Principal.toText(owner);
    };

    public shared ({ caller }) func removeAllUserNodeRef() : async () {
        assert (isAdmin_(caller));
        userPrincipalToUserNode := Trie.empty();
    };

    //# UTILS
    public shared ({ caller }) func addAdmin(args : { principal : Text }) : async () {
        assert (isAdmin_(caller));
        var b : Buffer.Buffer<Text> = Buffer.fromArray(_admins);
        b.add(args.principal);
        _admins := Buffer.toArray(b);
    };

    public shared ({ caller }) func removeAdmin(args : { principal : Text }) : async () {
        assert (isAdmin_(caller));
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in _admins.vals()) {
            if (i != args.principal) {
                b.add(i);
            };
        };
        _admins := Buffer.toArray(b);
    };

    public query func getOwner() : async Text { return Principal.toText(owner) };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    public shared ({ caller }) func deleteCache() {
        assert (isAdmin_(caller));

        userPrincipalToUserNode := Trie.empty();
    };

    //# CONFIGS

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
            let fieldsArray : [(Text, Text)] = Map.toArray(c.fields);

            var fieldsBuffer = Buffer.Buffer<TGlobal.Field>(0);
            for (f in Iter.fromArray(fieldsArray)) {
                fieldsBuffer.add({ fieldName = f.0; fieldValue = f.1 });
            };

            b.add({
                cid = cid;
                fields = Buffer.toArray(fieldsBuffer);
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
            let fieldsArray : [(Text, Text)] = Map.toArray(c.fields);

            var fieldsBuffer = Buffer.Buffer<TGlobal.Field>(0);
            for (f in Iter.fromArray(fieldsArray)) {
                fieldsBuffer.add({ fieldName = f.0; fieldValue = f.1 });
            };

            b.add({
                cid = cid;
                fields = Buffer.toArray(fieldsBuffer);
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

    //EDIT CONFIG to support Candid edit feature
    public shared ({ caller }) func editAction(args : { aid : Text }) : async (TAction.Action) {
        assert (isAdmin_(caller));

        switch (getSpecificAction_(args.aid)) {
            case (?element) return element;
            case _ {};
        };

        return {
            aid = args.aid;
            adminPrincipalIds = [];
            callerAction = null;
            targetAction = null;
            worldAction = null;
        };
    };

    public shared ({ caller }) func editConfig(args : { cid : Text }) : async (TEntity.StableConfig) {
        assert (isAdmin_(caller));

        var fields : [TGlobal.Field] = [];

        switch (getSpecificConfig_(args.cid)) {
            case (?element) {
                var fieldsBuffer = Buffer.Buffer<TGlobal.Field>(0);
                for (f in Iter.fromArray(Map.toArray(element.fields))) {
                    fieldsBuffer.add({ fieldName = f.0; fieldValue = f.1 });
                };

                fields := Buffer.toArray(fieldsBuffer);
            };
            case _ {};
        };

        return {
            cid = args.cid;
            fields = fields;
        };
    };

    //CREATE CONFIG
    public shared ({ caller }) func createConfig(config : TEntity.StableConfig) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller) or caller == WorldId());
        let configExist = configExist_(config.cid);

        var fieldsBuffer = Buffer.Buffer<(Text, Text)>(0);

        for (f in Iter.fromArray(config.fields)) {
            fieldsBuffer.add((f.fieldName, f.fieldValue));
        };

        let fields : Map.Map<Text, Text> = Map.fromIter(Iter.fromArray(Buffer.toArray(fieldsBuffer)), thash);

        configsStorage := Trie.put(
            configsStorage,
            Utils.keyT(config.cid),
            Text.equal,
            {
                cid = config.cid;
                fields = fields;
            },
        ).0;

        if (configExist) return #ok("you have overwriten the config");
        return #ok("you have created a new config");
    };
    public shared ({ caller }) func createAction(config : TAction.Action) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller) or caller == WorldId());
        let configExist = actionExist_(config.aid);

        actionsStorage := Trie.put(actionsStorage, Utils.keyT(config.aid), Text.equal, config).0;

        if (configExist) return #ok("you have overwriten the action");
        return #ok("you have created a new action");
    };
    //DELETE CONFIG
    public shared ({ caller }) func deleteConfig(args : { cid : Text }) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = configExist_(args.cid);
        if (configExist) {

            configsStorage := Trie.remove(configsStorage, Utils.keyT(args.cid), Text.equal).0;

            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func deleteAction(args : { aid : Text }) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = actionExist_(args.aid);
        if (configExist) {

            actionsStorage := Trie.remove(actionsStorage, Utils.keyT(args.aid), Text.equal).0;

            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //RESET CONFIG & ACTIONS
    public shared ({ caller }) func resetActionsAndConfigsToHardcodedTemplate() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));

        configsStorage := Trie.empty();
        actionsStorage := Trie.empty();

        for (i in Config.configs.vals()) {
            ignore createConfig(i);
        };

        for (i in Config.action.vals()) {
            ignore createAction(i);
        };
        return #ok();
    };

    //DELETE ALL CONFIGS & ACTIONS
    public shared ({ caller }) func deleteAllConfigs() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));

        configsStorage := Trie.empty();

        return #ok();
    };

    public shared ({ caller }) func deleteAllActions() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));

        actionsStorage := Trie.empty();

        for (i in Config.action.vals()) {
            ignore createAction(i);
        };

        return #ok();
    };

    //# USER DATA
    //Get Actions
    public func getAllUserActionStates(args : { uid : Text }) : async (Result.Result<[TAction.ActionState], Text>) {

        switch (await getUserNode_(args.uid)) {
            case (#ok(userNodeId)) {

                let userNode : UserNode = actor (userNodeId);

                return await userNode.getAllUserActionStates(args.uid, worldPrincipalId);
            };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };
    };
    //Get Entities
    public func getAllUserEntities(args : { uid : Text; page : ?Nat }) : async (Result.Result<[TEntity.StableEntity], Text>) {
        switch (await getUserNode_(args.uid)) {
            case (#ok(userNodeId)) {
                let userNode : UserNode = actor (userNodeId);
                return await userNode.getAllUserEntities(args.uid, worldPrincipalId, args.page);
            };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };
    };

    private func getEntity_(entities : [TEntity.StableEntity], wid : TGlobal.worldId, eid : TGlobal.entityId) : (?TEntity.StableEntity) {

        for (entity in entities.vals()) {
            if (entity.eid == eid) {
                return ?entity;
            };
        };

        return null;
    };

    private func getEntityField_(entities : [TEntity.StableEntity], wid : TGlobal.worldId, eid : TGlobal.entityId, fieldName : Text) : (fieldValue : ?Text) {

        switch (getEntity_(entities, wid, eid)) {
            case (?entity) {
                var fields = entity.fields;

                for (field in fields.vals()) {
                    if (field.fieldName == fieldName) return ?field.fieldValue;
                };
            };
            case _ {};
        };

        return null;
    };

    public shared ({ caller }) func createEntity(entitySchema : TEntity.EntitySchema) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId);

        switch (await getUserNode_(entitySchema.uid)) {
            case (#ok(userNodeId)) {
                let userNode : UserNode = actor (userNodeId);
                return await userNode.createEntity(entitySchema.uid, worldPrincipalId, entitySchema.eid, entitySchema.fields);
            };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };
    };

    public shared ({ caller }) func deleteEntity(args : { uid : Text; eid : Text }) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId);
        switch (await getUserNode_(args.uid)) {
            case (#ok(userNodeId)) {
                let userNode : UserNode = actor (userNodeId);
                return await userNode.deleteEntity(args.uid, worldPrincipalId, args.eid);
            };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };
    };

    private func editEntity_(entitySchema : TEntity.EntitySchema) : async (Result.Result<Text, Text>) {
        switch (await getUserNode_(entitySchema.uid)) {
            case (#ok(userNodeId)) {

                let userNode : UserNode = actor (userNodeId);

                return await userNode.editEntity(entitySchema.uid, worldPrincipalId, entitySchema.eid, entitySchema.fields);
            };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };
    };

    public shared ({ caller }) func editEntity(arg : { userId : Text; entityId : Text }) : async (TEntity.EntitySchema) {
        assert (isAdmin_(caller));
        switch (await getUserNode_(arg.userId)) {
            case (#ok(userNodeId)) {
                let userNode : UserNode = actor (userNodeId);
                let entities = await userNode.getEntity(arg.userId, worldPrincipalId, arg.entityId);
                return {
                    uid = arg.userId;
                    eid = arg.entityId;
                    fields = entities.fields;
                };
            };
            case (#err(errMsg)) {
                return {
                    uid = arg.userId;
                    eid = arg.entityId;
                    fields = [];
                };
            };
        };
    };

    //# HANDLE OUTCOMES
    private func generateActionResultOutcomes_(actionResult : TAction.ActionResult) : async ([TAction.ActionOutcomeOption]) {
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
                        randPerc := randomGeneratorGacha.genAsPerc(_seedMod);
                    };
                    case _ {
                        let trueRandom = await RandomExt.getRandomNat(999999999999);
                        seedMod := ?trueRandom;
                        randPerc := randomGeneratorGacha.genAsPerc(trueRandom);
                    };
                };
            };

            var dice_outcome = (randPerc * 1.0 * accumulated_weight);

            //C Pick outcomes base on their weights
            label outcome_loop for (outcomeOption in outcome.possibleOutcomes.vals()) {
                let outcome_weight = outcomeOption.weight;
                if (outcome_weight >= dice_outcome) {

                    outcomes.add(outcomeOption);

                    break outcome_loop;
                } else {
                    dice_outcome -= outcome_weight;
                };
            };
        };

        return Buffer.toArray(outcomes);
    };

    private func transferTokens_(userPrincipalTxt : Text, transferData : TAction.TransferIcrc) : async () {
        let icrcLedger : ICRC.Self = actor (transferData.canister);

        let feeHandler = tokenFee_(transferData.canister);
        let decimalHandler = tokenDecimal_(transferData.canister);

        let fee = await feeHandler;
        let decimals = await decimalHandler;

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
            amount = Utils.convertToBaseUnit(transferData.quantity, decimals);
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

    private func applyOutcomes_(userPrincipalTxt : Text, userNode : UserNode, actionState : TAction.ActionState, outcomes : [TAction.ActionOutcomeOption]) : async () {

        switch (await userNode.applyOutcomes(userPrincipalTxt, actionState, outcomes)) {
            case (#err msg) { debugLog("applyOutcomes_ Failure " # msg) };
            case _ {};
        };

        let accountId : Text = AccountIdentifier.fromText(userPrincipalTxt, null);

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
            let nftCollection : NFT = actor (nftCanisterId);
            ignore nftCollection.ext_mint(Buffer.toArray(nftGroup)); //ignore mint_(nftCanisterId, Buffer.toArray(nftGroup));
        };

        //Mint Tokens and add them along with entities to the return value
        for (outcome in outcomes.vals()) {
            switch (outcome.option) {
                //Transfer Tokens
                case (#transferIcrc val) {
                    ignore transferTokens_(userPrincipalTxt, val);
                };
                case _ {};
            };
        };
    };

    //# REFINE FUNCS
    private func refineAllOutcomes_(outcomes : [TAction.ActionOutcomeOption], caller : Text, target : Text, actionFields : [TGlobal.Field], worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<[TAction.ActionOutcomeOption], Text>) {
        var refinedOutcomes = Buffer.Buffer<TAction.ActionOutcomeOption>(0);

        for (e in outcomes.vals()) {
            switch (refineOutcome_(e, caller, target, actionFields, worldData, callerData, targetData)) {
                case (#ok refinedOutcome) refinedOutcomes.add(refinedOutcome);
                case (#err errMsg) return #err errMsg;
            };
        };

        return #ok(Buffer.toArray(refinedOutcomes));
    };
    private func refineOutcome_(outcome : TAction.ActionOutcomeOption, caller : Text, target : Text, actionFields : [TGlobal.Field], worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<TAction.ActionOutcomeOption, Text>) {
        switch (outcome.option) {

            case (#updateEntity updateEntity) {

                var eid = updateEntity.eid;
                if (Text.contains(eid, #text "$caller")) { eid := caller } else if (Text.contains(eid, #text "$target")) {
                    eid := target;
                } else if (Text.contains(eid, #text "$args")) {

                    var variableFieldNameElements = Iter.toArray(Text.split(eid, #char '.'));

                    if (variableFieldNameElements.size() == 2) {
                        let argFieldName = variableFieldNameElements[1];

                        switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                            case (#ok(fieldValue)) {
                                eid := fieldValue;
                            };
                            case (#err errMsg) return #err errMsg;
                        };
                    } else {
                        return #err("you need an action argument whose pattern must be #args.fieldName");
                    };
                } else if (Text.contains(eid, #char '#')) {
                    let newIndex = indexedKeyCount;
                    eid := Text.replace(eid, #char '#', "") # Nat.toText(newIndex);
                    indexedKeyCount += 1;
                };

                var refinedUpdateEntityTypes = Buffer.Buffer<TAction.UpdateEntityType>(0);
                var outcomeNeededToBeRefined = false;

                label updateTypes for (e in Iter.fromArray(updateEntity.updates)) {
                    switch (e) {
                        case (#setNumber update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            switch (update.fieldValue) {
                                case (#formula formula) {

                                    var number = 0.0;
                                    switch (evaluateFormula(formula, actionFields, worldData, callerData, targetData)) {
                                        case (#ok(_number)) number := _number;
                                        case (#err errMsg) return #err errMsg;
                                    };
                                    refinedUpdateEntityTypes.add(
                                        #setNumber {
                                            fieldName = _fieldName;
                                            fieldValue = #number number;
                                        }
                                    );

                                    continue updateTypes;
                                };
                                case (_) {};
                            };

                        };
                        case (#decrementNumber update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            switch (update.fieldValue) {
                                case (#formula formula) {

                                    var number = 0.0;
                                    switch (evaluateFormula(formula, actionFields, worldData, callerData, targetData)) {
                                        case (#ok(_number)) number := _number;
                                        case (#err errMsg) return #err errMsg;
                                    };

                                    refinedUpdateEntityTypes.add(
                                        #decrementNumber {
                                            fieldName = _fieldName;
                                            fieldValue = #number number;
                                        }
                                    );

                                    continue updateTypes;
                                };
                                case (_) {};
                            };

                        };
                        case (#incrementNumber update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            switch (update.fieldValue) {
                                case (#formula formula) {

                                    var number = 0.0;
                                    switch (evaluateFormula(formula, actionFields, worldData, callerData, targetData)) {
                                        case (#ok(_number)) number := _number;
                                        case (#err errMsg) return #err errMsg;
                                    };

                                    refinedUpdateEntityTypes.add(
                                        #incrementNumber {
                                            fieldName = _fieldName;
                                            fieldValue = #number number;
                                        }
                                    );

                                    continue updateTypes;
                                };
                                case (_) {};
                            };

                        };
                        case (#renewTimestamp update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            switch (update.fieldValue) {
                                case (#formula formula) {

                                    var number = 0.0;
                                    switch (evaluateFormula(formula, actionFields, worldData, callerData, targetData)) {
                                        case (#ok(_number)) number := _number;
                                        case (#err errMsg) return #err errMsg;
                                    };

                                    refinedUpdateEntityTypes.add(
                                        #renewTimestamp {
                                            fieldName = _fieldName;
                                            fieldValue = #number number;
                                        }
                                    );

                                    continue updateTypes;
                                };
                                case (_) {};
                            };
                        };
                        case (#setText update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            if (Text.contains(update.fieldValue, #text "$caller")) {

                                refinedUpdateEntityTypes.add(
                                    #setText {
                                        fieldName = _fieldName;
                                        fieldValue = caller;
                                    }
                                );

                                continue updateTypes;
                            } else if (Text.contains(update.fieldValue, #text "$target")) {

                                refinedUpdateEntityTypes.add(
                                    #setText {
                                        fieldName = _fieldName;
                                        fieldValue = target;
                                    }
                                );

                                continue updateTypes;
                            } else if (Text.contains(update.fieldValue, #text "$args")) {
                                var variableFieldNameElements = Iter.toArray(Text.split(update.fieldValue, #char '.'));

                                if (variableFieldNameElements.size() == 2) {
                                    let argFieldName = variableFieldNameElements[1];

                                    switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                                        case (#ok(fieldValue)) {

                                            refinedUpdateEntityTypes.add(
                                                #setText {
                                                    fieldName = _fieldName;
                                                    fieldValue = fieldValue;
                                                }
                                            );

                                            continue updateTypes;
                                        };
                                        case (#err errMsg) return #err errMsg;
                                    };
                                } else {
                                    return #err("you need an action argument whose pattern must be #args.fieldName");
                                };
                            };
                        };
                        case (#addToList update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            if (Text.contains(update.value, #text "$caller")) {

                                refinedUpdateEntityTypes.add(
                                    #addToList {
                                        fieldName = _fieldName;
                                        value = caller;
                                    }
                                );

                                continue updateTypes;
                            } else if (Text.contains(update.value, #text "$target")) {

                                refinedUpdateEntityTypes.add(
                                    #addToList {
                                        fieldName = _fieldName;
                                        value = target;
                                    }
                                );

                                continue updateTypes;
                            } else if (Text.contains(update.value, #text "$args")) {

                                var variableFieldNameElements = Iter.toArray(Text.split(update.value, #char '.'));

                                if (variableFieldNameElements.size() == 2) {
                                    let argFieldName = variableFieldNameElements[1];

                                    switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                                        case (#ok(fieldValue)) {

                                            refinedUpdateEntityTypes.add(
                                                #removeFromList {
                                                    fieldName = update.fieldName;
                                                    value = fieldValue;
                                                }
                                            );

                                            continue updateTypes;
                                        };
                                        case (#err errMsg) return #err errMsg;
                                    };
                                } else {
                                    return #err("you need an action argument whose pattern must be #args.fieldName");
                                };
                            };
                        };
                        case (#removeFromList update) {

                            var _fieldName = update.fieldName;
                            if (Text.contains(_fieldName, #text "$caller")) {
                                _fieldName := caller;
                            } else if (Text.contains(_fieldName, #text "$caller")) _fieldName := target;

                            if (Text.contains(update.value, #text "$caller")) {

                                refinedUpdateEntityTypes.add(
                                    #removeFromList {
                                        fieldName = _fieldName;
                                        value = caller;
                                    }
                                );

                                continue updateTypes;
                            } else if (Text.contains(update.value, #text "$target")) {

                                refinedUpdateEntityTypes.add(
                                    #removeFromList {
                                        fieldName = _fieldName;
                                        value = target;
                                    }
                                );

                                continue updateTypes;
                            } else if (Text.contains(update.value, #text "$args")) {
                                var variableFieldNameElements = Iter.toArray(Text.split(update.value, #char '.'));

                                if (variableFieldNameElements.size() == 2) {
                                    let argFieldName = variableFieldNameElements[1];

                                    switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                                        case (#ok(fieldValue)) {

                                            refinedUpdateEntityTypes.add(
                                                #removeFromList {
                                                    fieldName = _fieldName;
                                                    value = fieldValue;
                                                }
                                            );

                                            continue updateTypes;
                                        };
                                        case (#err errMsg) return #err errMsg;
                                    };
                                } else {
                                    return #err("you need an action argument whose pattern must be #args.fieldName");
                                };
                            };
                        };
                        case _ {};
                    };
                    refinedUpdateEntityTypes.add(e);
                };

                return #ok {
                    weight = outcome.weight;
                    option = #updateEntity {
                        wid = updateEntity.wid;
                        eid = eid;
                        updates = Buffer.toArray(refinedUpdateEntityTypes);
                    };
                };
                //
            };
            case _ {};
        };

        return #ok outcome;
    };

    private func refineConstraints_(actionConstraint : ?TAction.ActionConstraint, callerPrincipalId : Text, targetPrincipalId : Text, actionFields : [TGlobal.Field]) : (Result.Result<?TAction.ActionConstraint, Text>) {

        switch (actionConstraint) {

            case (?_actionConstraint) {

                if (Array.size(_actionConstraint.entityConstraint) > 0) {

                    var editedConstraints = Buffer.Buffer<TConstraints.EntityConstraint>(0);

                    for (e in Iter.fromArray(_actionConstraint.entityConstraint)) {
                        var newEidConstraint = e.eid;

                        //EID
                        if (e.eid == "$caller") {
                            newEidConstraint := callerPrincipalId;
                        } else if (e.eid == "$target") {
                            newEidConstraint := targetPrincipalId;
                        } else if (Text.contains(e.eid, #text "$args")) {

                            var variableFieldNameElements = Iter.toArray(Text.split(e.eid, #char '.'));

                            if (variableFieldNameElements.size() == 2) {
                                let argFieldName = variableFieldNameElements[1];

                                switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                                    case (#ok(fieldValue)) {
                                        newEidConstraint := fieldValue;
                                    };
                                    case (#err errMsg) return #err errMsg;
                                };
                            } else {
                                return #err("you need an action argument whose pattern must be #args.fieldName");
                            };
                        };

                        var entityConstraintType : TConstraints.EntityConstraintType = e.entityConstraintType;

                        switch (e.entityConstraintType) {
                            case (#equalToText val) {
                                if (val.value == "$caller") {
                                    entityConstraintType := #equalToText {
                                        fieldName = val.fieldName;
                                        value = callerPrincipalId;
                                        equal = val.equal;
                                    };
                                } else if (val.value == "$target") {
                                    entityConstraintType := #equalToText {
                                        fieldName = val.fieldName;
                                        value = targetPrincipalId;
                                        equal = val.equal;
                                    };
                                } else if (Text.contains(val.value, #text "$args")) {
                                    var variableFieldNameElements = Iter.toArray(Text.split(val.value, #char '.'));

                                    if (variableFieldNameElements.size() == 2) {
                                        let argFieldName = variableFieldNameElements[1];

                                        switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                                            case (#ok(fieldValue)) {
                                                entityConstraintType := #equalToText {
                                                    fieldName = val.fieldName;
                                                    value = fieldValue;
                                                    equal = val.equal;
                                                };
                                            };
                                            case (#err errMsg) return #err errMsg;
                                        };
                                    } else {
                                        return #err("you need an action argument whose pattern must be #args.fieldName");
                                    };
                                } else entityConstraintType := #equalToText val;
                            };
                            case (#containsText val) {
                                if (val.value == "$caller") {
                                    entityConstraintType := #containsText {
                                        fieldName = val.fieldName;
                                        value = callerPrincipalId;
                                        contains = val.contains;
                                    };
                                } else if (val.value == "$target") {
                                    entityConstraintType := #containsText {
                                        fieldName = val.fieldName;
                                        value = targetPrincipalId;
                                        contains = val.contains;
                                    };
                                } else if (Text.contains(val.value, #text "$args")) {
                                    var variableFieldNameElements = Iter.toArray(Text.split(val.value, #char '.'));

                                    if (variableFieldNameElements.size() == 2) {
                                        let argFieldName = variableFieldNameElements[1];

                                        switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                                            case (#ok(fieldValue)) {
                                                entityConstraintType := #containsText {
                                                    fieldName = val.fieldName;
                                                    value = fieldValue;
                                                    contains = val.contains;
                                                };
                                            };
                                            case (#err errMsg) return #err errMsg;
                                        };
                                    } else {
                                        return #err("you need an action argument whose pattern must be #args.fieldName");
                                    };
                                } else entityConstraintType := #containsText val;
                            };
                            case (_) {};
                        };

                        editedConstraints.add({
                            wid = e.wid;
                            eid = newEidConstraint;
                            entityConstraintType = entityConstraintType;
                        });
                    };

                    return #ok(
                        ?{
                            timeConstraint = _actionConstraint.timeConstraint;
                            entityConstraint = Buffer.toArray(editedConstraints);
                            icpConstraint = _actionConstraint.icpConstraint;
                            icrcConstraint = _actionConstraint.icrcConstraint;
                            nftConstraint = _actionConstraint.nftConstraint;
                        }
                    );
                };

            };
            case _ {};
        };

        return #ok(actionConstraint);
    };

    private func validateICPTransfer_(fromAccountId : Text, toAccountId : Text, amt : ICP.Tokens, base_block : ICP.Block, block_index : ICP.BlockIndex) : Result.Result<Text, Text> {
        switch (Trie.find(_icp_blocks, Utils.keyT(Nat64.toText(block_index)), Text.equal)) {
            case (?_) {
                return #err("block already verified before");
            };
            case _ {};
        };
        var tx : ICP.Transaction = base_block.transaction;
        var op : ?ICP.Operation = tx.operation;
        switch (op) {
            case (?op) {
                switch (op) {
                    case (#Transfer { to; fee; from; amount }) {
                        if (Hex.encode(Blob.toArray(Blob.fromArray(to))) == toAccountId and Hex.encode(Blob.toArray(Blob.fromArray(from))) == fromAccountId and amount == amt) {
                            _icp_blocks := Trie.put(_icp_blocks, Utils.keyT(Nat64.toText(block_index)), Text.equal, "").0;
                            return #ok("verified!");
                        } else {
                            return #err("invalid tx!");
                        };
                    };
                    case (#Burn {}) {
                        return #err("burn tx!");
                    };
                    case (#Mint {}) {
                        return #err("mint tx!");
                    };
                };
            };
            case _ {
                return #err("invalid tx!");
            };
        };
    };

    private stable var _icp_blocks : Trie.Trie<Text, Text> = Trie.empty(); // Block_index -> ""
    private stable var _icrc_blocks : Trie.Trie<Text, Trie.Trie<Text, Text>> = Trie.empty(); // token_canister_id -> [Block_index -> ""]
    private stable var _nft_txs : Trie.Trie<Text, Trie.Trie<Text, EXT.TokenIndex>> = Trie.empty(); // nft_canister_id -> [TxId, TokenIndex]

    private func validateICRCTransfer_(token_canister_id : Text, fromAccount : ICRC.Account, toAccount : ICRC.Account, amt : Nat, tx : ICRC.Transaction, block_index : Nat) : Result.Result<Text, Text> {
        switch (Trie.find(_icrc_blocks, Utils.keyT(token_canister_id), Text.equal)) {
            case (?token_blocks) {
                switch (Trie.find(token_blocks, Utils.keyT(Nat.toText(block_index)), Text.equal)) {
                    case (?_) {
                        return #err("block already verified before");
                    };
                    case _ {};
                };
            };
            case _ {};
        };
        if (tx.kind == "transfer") {
            let transfer = tx.transfer;
            switch (transfer) {
                case (?tt) {
                    if (tt.from == fromAccount and tt.to == toAccount and tt.amount == amt) {
                        _icrc_blocks := Trie.put2D(_icrc_blocks, Utils.keyT(token_canister_id), Text.equal, Utils.keyT(Nat.toText(block_index)), Text.equal, "");
                        return #ok("verified!");
                    } else {
                        return #err("tx transfer details mismatch!");
                    };
                };
                case (null) {
                    return #err("tx transfer details not found!");
                };
            };

        } else if (tx.kind == "mint") {
            let mint = tx.mint;
            switch (mint) {
                case (?tt) {
                    if (tt.to == toAccount and tt.amount == amt and fromAccount == { owner = Principal.fromText("2vxsx-fae"); subaccount = null }) {
                        return #ok("verified!");
                    } else {
                        return #err("tx mint details mismatch!");
                    };
                };
                case (null) {
                    return #err("tx mint details not found!");
                };
            };
        } else {
            return #err("not a transfer!");
        };
    };

    private func validateNftTransfer_(nft_canister_id : Text, txs : [EXT.TxInfo], fromPrincipal : Text, txType : { #hold : { #boomEXT; #originalEXT }; #transfer : TConstraints.NftTransfer }, metadata : ?Text) : Result.Result<Text, Text> {
        switch (txType) {
            case (#hold h) {
                switch (h) {
                    case (#originalEXT) { return #ok("") }; // this case will be validated directly
                    case (#boomEXT) {
                        for (i in txs.vals()) {
                            switch (metadata) {
                                case (?_) {
                                    if (i.current_holder == AccountIdentifier.fromText(fromPrincipal, null) and metadata == i.metadata) {
                                        switch (Trie.find(_nft_txs, Utils.keyT(nft_canister_id), Text.equal)) {
                                            case (?val) {
                                                switch (Trie.find(val, Utils.keyT(i.txid), Text.equal)) {
                                                    case (?_) {};
                                                    case _ {
                                                        _nft_txs := Trie.put2D(_nft_txs, Utils.keyT(nft_canister_id), Text.equal, Utils.keyT(i.txid), Text.equal, i.index);
                                                        return #ok("");
                                                    };
                                                };
                                            };
                                            case _ {
                                                _nft_txs := Trie.put2D(_nft_txs, Utils.keyT(nft_canister_id), Text.equal, Utils.keyT(i.txid), Text.equal, i.index);
                                                return #ok("");
                                            };
                                        };
                                    };
                                };
                                case _ {
                                    if (i.current_holder == AccountIdentifier.fromText(fromPrincipal, null)) {
                                        switch (Trie.find(_nft_txs, Utils.keyT(nft_canister_id), Text.equal)) {
                                            case (?val) {
                                                switch (Trie.find(val, Utils.keyT(i.txid), Text.equal)) {
                                                    case (?_) {};
                                                    case _ {
                                                        _nft_txs := Trie.put2D(_nft_txs, Utils.keyT(nft_canister_id), Text.equal, Utils.keyT(i.txid), Text.equal, i.index);
                                                        return #ok("");
                                                    };
                                                };
                                            };
                                            case _ {
                                                _nft_txs := Trie.put2D(_nft_txs, Utils.keyT(nft_canister_id), Text.equal, Utils.keyT(i.txid), Text.equal, i.index);
                                                return #ok("");
                                            };
                                        };
                                    };
                                };
                            };
                        };
                        return #err("");
                    };
                };
            };
            case (#transfer t) {
                var toPrincipal = "";
                if (t.toPrincipal == "") {
                    toPrincipal := "0000000000000000000000000000000000000000000000000000000000000001";
                } else {
                    toPrincipal := t.toPrincipal;
                };

                label txs_check for (i in txs.vals()) {

                    if (i.previous_holder == AccountIdentifier.fromText(fromPrincipal, null) and i.current_holder == AccountIdentifier.fromText(toPrincipal, null)) {

                        switch (metadata) {
                            case (?_) {
                                if (metadata != i.metadata) continue txs_check;
                            };
                            case (_) {};
                        };

                        switch (Trie.find(_nft_txs, Utils.keyT(nft_canister_id), Text.equal)) {
                            case (?val) {
                                switch (Trie.find(val, Utils.keyT(i.txid), Text.equal)) {
                                    case (?_) {};
                                    case _ {
                                        _nft_txs := Trie.put2D(_nft_txs, Utils.keyT(nft_canister_id), Text.equal, Utils.keyT(i.txid), Text.equal, i.index);
                                        return #ok("");
                                    };
                                };
                            };
                            case _ {
                                _nft_txs := Trie.put2D(_nft_txs, Utils.keyT(nft_canister_id), Text.equal, Utils.keyT(i.txid), Text.equal, i.index);
                                return #ok("");
                            };
                        };
                    };
                };
                return #err("");
            };
        };
    };

    private func validateEntityConstraints_(entities : [TEntity.StableEntity], entityConstraints : [TConstraints.EntityConstraint]) : (Result.Result<(), Text>) {

        for (e in entityConstraints.vals()) {

            var wid = Option.get(e.wid, worldPrincipalId);

            switch (e.entityConstraintType) {
                case (#greaterThanNumber val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_float = Utils.textToFloat(currentVal);

                            if (current_val_in_float <= val.value) {
                                return #err("entity field : " #val.fieldName # " is less than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
                            };

                        };
                        case _ {
                            return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#lessThanNumber val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_float = Utils.textToFloat(currentVal);

                            if (current_val_in_float >= val.value) {
                                return #err("entity field : " #val.fieldName # " is greater than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
                            };

                        };
                        case _ {
                            //We are not longer returning false if entity or field doesnt exist
                            //return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#equalToNumber val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_float = Utils.textToFloat(currentVal);

                            if (val.equal) {
                                if (current_val_in_float != val.value) return #err("entity field : " #val.fieldName # " is not equal to " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
                            } else {
                                if (current_val_in_float == val.value) return #err("entity field : " #val.fieldName # " is equal to " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
                            };

                        };
                        case _ {
                            if (val.equal) return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#equalToText val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            if (val.equal) {
                                if (currentVal != val.value) return #err("entity field : " #val.fieldName # " is not equal to " #val.value # ", therefore, does not pass EntityConstraints");
                            } else {
                                if (currentVal == val.value) return #err("entity field : " #val.fieldName # " is equal to " #val.value # ", therefore, does not pass EntityConstraints");
                            };

                        };
                        case _ {
                            if (val.equal) return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#containsText val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            if (val.contains) {

                                if (Text.contains(currentVal, #text(val.value)) == false) {
                                    return #err("entity field : " #val.fieldName # " doesn't contain " # (val.value) # ", therefore, does not pass EntityConstraints. current value: " #currentVal);
                                };
                            } else {

                                if (Text.contains(currentVal, #text(val.value))) {
                                    return #err("entity field : " #val.fieldName # " contains " # (val.value) # ", therefore, does not pass EntityConstraints. current value: " #currentVal);
                                };
                            };

                        };
                        case _ {
                            if (val.contains) return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#greaterThanNowTimestamp val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_Nat = Utils.textToNat(currentVal);
                            if (current_val_in_Nat < Time.now()) {
                                return #err("entity field : " #val.fieldName # " Time.Now is greater than current value, therefore, does not pass EntityConstraints, " #Nat.toText(current_val_in_Nat) # " < " #Int.toText(Time.now()));
                            };

                        };
                        case _ {
                            return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#lessThanNowTimestamp val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_Nat = Utils.textToNat(currentVal);
                            if (current_val_in_Nat > Time.now()) {
                                return #err("entity field : " #val.fieldName # " Time.Now is lesser than current value, therefore, does not pass EntityConstraints, " #Nat.toText(current_val_in_Nat) # " > " #Int.toText(Time.now()));
                            };

                        };
                        case _ {
                            //We are not longer returning false if entity or field doesnt exist
                            //return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#greaterThanEqualToNumber val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_float = Utils.textToFloat(currentVal);

                            if (current_val_in_float < val.value) {
                                return #err("entity field : " #val.fieldName # " is less than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
                            };

                        };
                        case _ {
                            return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#lessThanEqualToNumber val) {

                    switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                        case (?currentVal) {

                            let current_val_in_float = Utils.textToFloat(currentVal);

                            if (current_val_in_float > val.value) {
                                return #err("entity field : " #val.fieldName # " is greater than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
                            };

                        };
                        case _ {
                            //We are not longer returning false if entity or field doesnt exist
                            // return #err(("You don't have entity of id: " #e.eid # " or field with key : " #val.fieldName # " therefore, does not exist in respected entity to match entity constraints."));
                        };
                    };

                };
                case (#existField val) {

                    switch (getEntity_(entities, wid, e.eid)) {
                        case (?entity) {

                            switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                                case (?currentVal) {
                                    if (val.value == false) return #err(("Field with fieldName : " #val.fieldName # " exist, therefore, doens't match entity constraints of \'exist field false\''."));
                                };
                                case _ {
                                    if (val.value) return #err(("Field with fieldName : " #val.fieldName # " doesn't exist, therefore, doens't match entity constraints of \'exist field true\''."));
                                };
                            };

                        };
                        case _ {
                            if (val.value) return #err(("Entity of id : " #e.eid # " doesn't exist, therefore, it is required to be able to check if field of id: " #val.fieldName # " exists"));
                        };
                    };
                };
                case (#exist val) {
                    switch (getEntity_(entities, wid, e.eid)) {
                        case (?entity) {
                            if (val.value == false) return #err(("Entity of id : " #e.eid # " exist, therefore, doens't match entity constraints of \'exist false\''."));
                        };
                        case _ {
                            if (val.value) return #err(("Entity of id : " #e.eid # " doesn't exist, therefore, doens't match entity constraints of \'exist true\''."));
                        };
                    };
                };
            };

        };

        return #ok();
    };
    private func validateConstraints_(entities : [TEntity.StableEntity], uid : TGlobal.userId, aid : TGlobal.actionId, actionConstraint : ?TAction.ActionConstraint, currentUserActionState : ?TAction.ActionState) : async (Result.Result<TAction.ActionState, Text>) {

        var _intervalStartTs : Nat = 0;
        var _actionCount : Nat = 0;
        var _quantity = ?0.0;
        var _expiration = ?0;

        switch (currentUserActionState) {
            case (?a) {
                _intervalStartTs := a.intervalStartTs;
                _actionCount := a.actionCount;
            };
            case _ {};
        };

        switch (actionConstraint) {
            case (?constraints) {

                //TIME CONSTRAINT
                switch (constraints.timeConstraint) {
                    case (?t) {

                        switch (t.actionExpirationTimestamp) {
                            case (?actionExpirationTimestamp) {
                                if (actionExpirationTimestamp < Time.now()) return #err("action is expired!");
                            };
                            case _ {};
                        };

                        switch(t.actionTimeInterval){
                            case (? actionTimeInterval){

                                //intervalDuration is expected example (24hrs in nanoseconds)
                                if (actionTimeInterval.actionsPerInterval == 0) {
                                    return #err("actionsPerInterval limit is set to 0 so the action cannot be done");
                                };
                                if ((_intervalStartTs + actionTimeInterval.intervalDuration < Time.now())) {
                                    let t : Text = Int.toText(Time.now());
                                    let time : Nat = Utils.textToNat(t);
                                    _intervalStartTs := time;
                                    _actionCount := 1;
                                } else if (_actionCount < actionTimeInterval.actionsPerInterval) {
                                    _actionCount := _actionCount + 1;
                                } else {
                                    return #err("actionCount has already reached actionsPerInterval limit for this time interval");
                                };

                            };
                            case _ {};
                        };
                    };
                    case _ {};
                };
                //ENTITY CONSTRAINTS
                switch (validateEntityConstraints_(entities, constraints.entityConstraint)) {
                    case (#err(errMsg)) return #err(errMsg);
                    case _ {};
                };

                //Validating ICP txs
                let icpTxOptional = constraints.icpConstraint;
                switch icpTxOptional {
                    case (?icpTx) {
                        let ICP_Ledger : Ledger.ICP = actor (ENV.Ledger);
                        var res_icp : ICP.QueryBlocksResponse = await ICP_Ledger.query_blocks({
                            start = 1;
                            length = 1;
                        });
                        let chain_length = res_icp.chain_length;
                        let first_block_index = res_icp.first_block_index;
                        res_icp := await ICP_Ledger.query_blocks({
                            start = first_block_index;
                            length = chain_length - first_block_index;
                        });
                        let blocks = res_icp.blocks;
                        let total_blocks = blocks.size();

                        var fromAccountId : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(uid, null);
                        var toAccountId : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(icpTx.toPrincipal, null);
                        var amt : Nat64 = Int64.toNat64(Float.toInt64(icpTx.amount * 100000000.0));
                        var isValid : Bool = false;

                        if (total_blocks > 0) {
                            label check_icp_blocks for (i in Iter.range(0, total_blocks - 1)) {
                                switch (validateICPTransfer_(fromAccountId, toAccountId, { e8s = amt }, blocks[i], (Nat64.fromNat(i) + first_block_index))) {
                                    case (#ok _) {
                                        isValid := true;
                                        break check_icp_blocks;
                                    };
                                    case (#err e) {};
                                };
                            };
                        };

                        if (isValid == false) {
                            return #err("ICP tx is not valid or too old");
                        };

                    };
                    case _ {};
                };

                //Validating ICRC token txs
                let icrcTxs = constraints.icrcConstraint;
                if (icrcTxs.size() != 0) {
                    var from_ : ICRC.Account = {
                        owner = Principal.fromText(uid);
                        subaccount = null;
                    };
                    for (tx in icrcTxs.vals()) {
                        var to_ : ICRC.Account = {
                            owner = Principal.fromText(tx.toPrincipal);
                            subaccount = null;
                        };
                        let ICRC_Ledger : Ledger.ICRC1 = actor (tx.canister);
                        var res_icrc : ICRC.GetTransactionsResponse = await ICRC_Ledger.get_transactions({
                            start = 0;
                            length = 2000;
                        });

                        res_icrc := await ICRC_Ledger.get_transactions({
                            start = res_icrc.first_index;
                            length = res_icrc.log_length - res_icrc.first_index;
                        });

                        let txs_icrc = res_icrc.transactions;
                        let total_txs_icrc = txs_icrc.size();

                        var decimal = await tokenDecimal_(tx.canister);

                        var amt : Nat64 = Int64.toNat64(Float.toInt64(tx.amount * (Float.pow(10.0, Utils.textToFloat(Nat8.toText(decimal))))));
                        var isValid : Bool = false;

                        if (total_txs_icrc > 0) {
                            label check_icrc_txs for (i in Iter.range(0, total_txs_icrc - 1)) {
                                switch (validateICRCTransfer_(tx.canister, from_, to_, Nat64.toNat(amt), txs_icrc[i], (i + res_icrc.first_index))) {
                                    case (#ok _) {
                                        isValid := true;
                                        break check_icrc_txs;
                                    };
                                    case (#err e) {};
                                };
                            };
                        };

                        if (isValid == false) {
                            return #err("some icrc txs are not valid or are too old");
                        };
                    };
                };

                //Validating NFT Tx
                let nftTx = constraints.nftConstraint;
                if (nftTx.size() != 0) {
                    for (tx in nftTx.vals()) {
                        switch (tx.nftConstraintType) {
                            case (#transfer t) {
                                let nft_canister = actor (tx.canister) : actor {
                                    getUserNftTx : shared (Text, EXT.TxKind) -> async ([EXT.TxInfo]);
                                };
                                let user_txs = await nft_canister.getUserNftTx(uid, #transfer);

                                let result = validateNftTransfer_(tx.canister, user_txs, uid, tx.nftConstraintType, tx.metadata);

                                switch (result) {
                                    case (#ok _) {};
                                    case (#err e) {
                                        return #err("some nft txs are not valid or already validated");
                                    };
                                };
                            };
                            case (#hold h) {
                                switch (h) {
                                    case (#boomEXT) {
                                        let nft_canister = actor (tx.canister) : actor {
                                            getUserNftTx : shared (Text, EXT.TxKind) -> async ([EXT.TxInfo]);
                                        };
                                        let user_txs = await nft_canister.getUserNftTx(uid, #hold);
                                        let result = validateNftTransfer_(tx.canister, user_txs, uid, tx.nftConstraintType, tx.metadata);
                                        switch (result) {
                                            case (#ok _) {};
                                            case (#err e) {
                                                return #err("some nft txs are not valid or already validated");
                                            };
                                        };
                                    };
                                    case (#originalEXT) {
                                        let nft_canister = actor (tx.canister) : actor {
                                            getRegistry : shared query () -> async [(EXT.TokenIndex, EXT.AccountIdentifier)];
                                        };
                                        let registry = await nft_canister.getRegistry();
                                        var isValid = false;
                                        label registry_check for (i in registry.vals()) {
                                            if (i.1 == AccountIdentifier.fromText(uid, null)) {
                                                isValid := true;
                                                break registry_check;
                                            };
                                        };
                                        if (isValid == false) {
                                            return #err("user does not hold any nft from this collection");
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
            case _ {};
        };

        let a : TAction.ActionState = {
            intervalStartTs = _intervalStartTs;
            actionCount = _actionCount;
            actionId = aid; //NEW
        };
        return #ok(a);
    };

    //# ACTION LOCK MANAGEMENT
    private stable var actionLockState : Trie.Trie<Text, Trie.Trie<Text, Bool>> = Trie.empty(); // [key1 = callerPrincipalId] [key2 = ActionId] [Value = LockState]

    public shared ({ caller }) func deleteAllActionLockStates() : async () {
        assert (isAdmin_(caller));
        actionLockState := Trie.empty();
    };
    public shared ({ caller }) func deleteActionLockState(args : TAction.ActionLockStateArgs) : async () {
        assert (isAdmin_(caller));
        changeActionLockState_(args.uid, args.aid, false);
    };

    private func getActionLockState_(args : TAction.ActionLockStateArgs) : (Bool) {

        let callerActionsLockStates : Trie.Trie<Text, Bool> = switch (Trie.find(actionLockState, Utils.keyT(args.uid), Text.equal)) {
            case (?_callerActionsLockStates) _callerActionsLockStates;
            case (_) return false;
        };

        let callerSpecificActionLockState : Bool = switch (Trie.find(callerActionsLockStates, Utils.keyT(args.aid), Text.equal)) {
            case (?_callerSpecificActionLockState) _callerSpecificActionLockState;
            case (_) return false;
        };

        return callerSpecificActionLockState;
    };

    public query func getActionLockState(args : TAction.ActionLockStateArgs) : async (Bool) {
        return getActionLockState_({ uid = args.uid; aid = args.aid });
    };

    private func changeActionLockState_(callerPrincipalId : Text, actionId : Text, lock : Bool) : () {

        switch (Trie.find(actionLockState, Utils.keyT(callerPrincipalId), Text.equal)) {
            case (?callerActionsLockStates) {
                var _callerActionsLockStates = callerActionsLockStates;

                _callerActionsLockStates := Trie.put(_callerActionsLockStates, Utils.keyT(actionId), Text.equal, lock).0;

                actionLockState := Trie.put(actionLockState, Utils.keyT(callerPrincipalId), Text.equal, _callerActionsLockStates).0;
            };
            case (_) {
                var callerActionsLockStates : Trie.Trie<Text, Bool> = Trie.empty<Text, Bool>();

                callerActionsLockStates := Trie.put(callerActionsLockStates, Utils.keyT(actionId), Text.equal, lock).0;

                actionLockState := Trie.put(actionLockState, Utils.keyT(callerPrincipalId), Text.equal, callerActionsLockStates).0;
            };
        };
    };

    //# PROCESS ACTION

    private func getActionArgByFieldName_(fieldName : Text, args : [TGlobal.Field]) : (Result.Result<Text, Text>) {

        for (e in args.vals()) {
            if (e.fieldName == fieldName) return #ok(e.fieldValue);
        };

        return #err("Requires action argument of fieldName: " #fieldName);
    };

    //

    public shared ({ caller }) func processAction(actionArg : TAction.ActionArg) : async (Result.Result<TAction.ActionReturn, Text>) {

        let actionId = actionArg.actionId;
        let callerPrincipalId = Principal.toText(caller);

        let isActionStateLocked = getActionLockState_({
            uid = callerPrincipalId;
            aid = actionId;
        });

        if (isActionStateLocked) {
            debugLog("The '" #actionId # "' action failed because it is locked. Please wait for action to fully process before calling it again. This may take a few seconds.");

            return #err("The '" #actionId # "' action failed because it is locked. Please wait for action to fully process before calling it again. This may take a few seconds.");
        };
        changeActionLockState_(callerPrincipalId, actionId, true);

        processActionCount += 1;

        var callerAction : TAction.SubAction = {
            actionConstraint = null;
            actionResult = { outcomes = [] };
        };
        var targetAction : TAction.SubAction = {
            actionConstraint = null;
            actionResult = { outcomes = [] };
        };
        var worldAction : TAction.SubAction = {
            actionConstraint = null;
            actionResult = { outcomes = [] };
        };

        //caller
        var hasSubActionCaller = false;
        //target
        var targetPrincipalId : Text = "";
        var hasSubActionTarget = false;
        //world
        var hasSubActionWorld = false;

        //CHECK IF ACTION EXIST TO TRY SETUP BOTH CALLER AND TARGET SUB ACTIONS
        switch (getSpecificAction_(actionId)) {
            case (?_action) {

                //SETUP CALLER ACTION
                switch (_action.callerAction) {
                    case (?_callerAction) {
                        callerAction := _callerAction;
                        hasSubActionCaller := true;
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

                //TRY SETUP TARGET ACTION
                switch (_action.worldAction) {
                    case (?_targetAction) {
                        worldAction := _targetAction;
                        hasSubActionWorld := true;
                    };
                    case (_) {};
                };
            };
            case (_) {
                changeActionLockState_(callerPrincipalId, actionId, false);
                return #err("The '" #actionId # "' action failed to be executed, because it doesn't exist");
            };
        };

        //TRY SETUP TARGET PRINCIPAL ID
        if (hasSubActionTarget) {

            switch (getActionArgByFieldName_("targetPrincipalId", actionArg.fields)) {
                case (#ok(fieldValue)) {
                    targetPrincipalId := fieldValue;
                };
                case (#err(errMsg)) {
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return #err("The '" #actionId # "' action failed to be executed, because this is a compound action, thus requires as ActionArg.field a fieldName of 'targetPrincipalId' whose value is the target principal ");
                };
            };
        };

        //CHECK IF IT IS COMPOUND ACTION OR NORMAL ACTION

        let isCompoundCall = hasSubActionTarget and hasSubActionCaller;

        //

        if (isCompoundCall) {

            //GENERATE OUTCOMES
            var callerGeneratedOutcomesHandler = generateActionResultOutcomes_(callerAction.actionResult);
            var targetGeneratedOutcomesHandler = generateActionResultOutcomes_(targetAction.actionResult);

            var callerOutcomes : [TAction.ActionOutcomeOption] = [];
            var targetOutcomes : [TAction.ActionOutcomeOption] = [];

            var worldOutcomes : ?[TAction.ActionOutcomeOption] = null;
            if (hasSubActionWorld) {
                worldOutcomes := ?(await generateActionResultOutcomes_(worldAction.actionResult));

                callerOutcomes := await callerGeneratedOutcomesHandler;
                targetOutcomes := await targetGeneratedOutcomesHandler;

                ignore processCompoundAction_(actionId, actionArg.fields, callerPrincipalId, targetPrincipalId, callerAction.actionConstraint, targetAction.actionConstraint, worldAction.actionConstraint, callerOutcomes, targetOutcomes, worldOutcomes);
            } else {

                callerOutcomes := await callerGeneratedOutcomesHandler;
                targetOutcomes := await targetGeneratedOutcomesHandler;

                ignore processCompoundAction_(actionId, actionArg.fields, callerPrincipalId, targetPrincipalId, callerAction.actionConstraint, targetAction.actionConstraint, null, callerOutcomes, targetOutcomes, worldOutcomes);

            };

            let outcomes = {
                callerPrincipalId = callerPrincipalId;
                targetPrincipalId = ?targetPrincipalId;
                worldPrincipalId = worldPrincipalId;
                callerOutcomes = ?callerOutcomes;
                targetOutcomes = ?targetOutcomes;
                worldOutcomes = worldOutcomes;
            };
            ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
            //RETURN CALLER OUTCOME
            return #ok(outcomes);
        } else if (hasSubActionTarget) {
            //GENERATE OUTCOMES
            var targetOutcomesHandler = generateActionResultOutcomes_(targetAction.actionResult);

            var targetOutcomes : [TAction.ActionOutcomeOption] = [];

            var worldOutcomes : ?[TAction.ActionOutcomeOption] = null;

            if (hasSubActionWorld) {

                worldOutcomes := ?(await generateActionResultOutcomes_(worldAction.actionResult));

                targetOutcomes := await targetOutcomesHandler;

                ignore processAction_(actionId, actionArg.fields, callerPrincipalId, targetPrincipalId, targetAction.actionConstraint, worldAction.actionConstraint, targetOutcomes, worldOutcomes);
            } else {

                targetOutcomes := await targetOutcomesHandler;

                ignore processAction_(actionId, actionArg.fields, callerPrincipalId, targetPrincipalId, targetAction.actionConstraint, null, targetOutcomes, worldOutcomes);
            };

            let outcomes = {
                callerPrincipalId = callerPrincipalId;
                targetPrincipalId = ?targetPrincipalId;
                worldPrincipalId = worldPrincipalId;
                callerOutcomes = null;
                targetOutcomes = ?targetOutcomes;
                worldOutcomes = worldOutcomes;
            };
            ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
            return #ok(outcomes);

        } else if (hasSubActionCaller) {
            //GENERATE OUTCOMES
            var callerOutcomeHandler = generateActionResultOutcomes_(callerAction.actionResult);

            var callerOutcomes : [TAction.ActionOutcomeOption] = [];

            var worldOutcomes : ?[TAction.ActionOutcomeOption] = null;
            if (hasSubActionWorld) {
                worldOutcomes := ?(await generateActionResultOutcomes_(worldAction.actionResult));

                callerOutcomes := await callerOutcomeHandler;

                ignore processAction_(actionId, actionArg.fields, callerPrincipalId, callerPrincipalId, callerAction.actionConstraint, worldAction.actionConstraint, callerOutcomes, worldOutcomes);

            } else {
                callerOutcomes := await callerOutcomeHandler;

                ignore processAction_(actionId, actionArg.fields, callerPrincipalId, callerPrincipalId, callerAction.actionConstraint, null, callerOutcomes, worldOutcomes);
            };

            let outcomes = {
                callerPrincipalId = callerPrincipalId;
                targetPrincipalId = null;
                worldPrincipalId = worldPrincipalId;
                callerOutcomes = ?callerOutcomes;
                targetOutcomes = null;
                worldOutcomes = worldOutcomes;
            };

            ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
            return #ok(outcomes);

        } else if (hasSubActionWorld) {
            //GENERATE OUTCOMES
            var worldOutcomes : [TAction.ActionOutcomeOption] = await generateActionResultOutcomes_(worldAction.actionResult);
            ignore processAction_(actionId, actionArg.fields, callerPrincipalId, worldPrincipalId, worldAction.actionConstraint, null, worldOutcomes, null);

            let outcomes = {
                callerPrincipalId = callerPrincipalId;
                targetPrincipalId = null;
                worldPrincipalId = worldPrincipalId;
                callerOutcomes = null;
                targetOutcomes = null;
                worldOutcomes = ?worldOutcomes;
            };

            ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
            return #ok(outcomes);

        } else {
            changeActionLockState_(callerPrincipalId, actionId, false);
            return #err("The '" #actionId # "' action failed to be executed, because it requires at least a subaction declared");
        };
    };

    private func processCompoundAction_(actionId : Text, actionFields : [TGlobal.Field], callerPrincipalId : Text, targetPrincipalId : Text, callerActionConstraint : ?TAction.ActionConstraint, targetActionConstraint : ?TAction.ActionConstraint, worldActionConstraint : ?TAction.ActionConstraint, callerOutcomes : [TAction.ActionOutcomeOption], targetOutcomes : [TAction.ActionOutcomeOption], worldOutcomes : ?[TAction.ActionOutcomeOption]) : async () {

        var worldHasOutcomes = worldOutcomes != null;

        //FETCH NODES IDS
        var worldNodeId : Text = "2vxsx-fae";
        var callerNodeId : Text = "2vxsx-fae";
        var targetNodeId : Text = "2vxsx-fae";

        let getWorldNodeHandler = getUserNode_(worldNodeId);
        let getCallerNodeHandler = getUserNode_(callerPrincipalId);
        let getTargetNodeHandler = getUserNode_(targetPrincipalId);

        switch (await getWorldNodeHandler) {
            case (#ok(content)) { worldNodeId := content };
            case (#err(errMsg)) {
                debugLog("The '" #actionId # "' action failed because it could not get world node Id.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        switch (await getCallerNodeHandler) {
            case (#ok(content)) { callerNodeId := content };
            case (#err(errMsg)) {
                debugLog("The '" #actionId # "' action failed because it could not get caller node Id.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        if (targetPrincipalId == worldPrincipalId) {
            targetNodeId := worldNodeId;
        } else {
            switch (await getTargetNodeHandler) {
                case (#ok(content)) { targetNodeId := content };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not get target node Id.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };
        };

        //INTERFACES

        let worldNode : UserNode = actor (worldNodeId);
        let callerNode : UserNode = actor (callerNodeId);
        let targetNode : UserNode = actor (targetNodeId);

        //FETCH ACTIONS STATES SETUP
        var newCallerActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
        };
        var newTargetActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
        };
        var newWorldActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
        };

        let oldCallerActionStateResultHandler = callerNode.getActionState(callerPrincipalId, worldPrincipalId, actionId);
        let oldTargetActionStateResultHandler = targetNode.getActionState(targetPrincipalId, worldPrincipalId, actionId);
        let oldWorldActionStateResultHandler = targetNode.getActionState(worldPrincipalId, worldPrincipalId, actionId);

        //FETCH ENTITIES DATA SETUP
        var worldData : [TEntity.StableEntity] = [];
        var callerData : [TEntity.StableEntity] = [];
        var targetData : [TEntity.StableEntity] = [];


        //GET WORLD IDS TO FETCH ENTITIES FROM
        var worldEntityConstraintsWorldIds : [Text] = [];
        
        switch (worldActionConstraint) {
            case(? constraints){

                var worldEntityConstraintsWorldIds_ = Buffer.Buffer<Text>(0);

                for(entityConstraint in Iter.fromArray(constraints.entityConstraint)){
                    let _wid = Option.get(entityConstraint.wid , worldPrincipalId);
                    if(Buffer.contains(worldEntityConstraintsWorldIds_, _wid, Text.equal) == false)
                        worldEntityConstraintsWorldIds_.add(Option.get(entityConstraint.wid , worldPrincipalId));
                };
                worldEntityConstraintsWorldIds := Buffer.toArray(worldEntityConstraintsWorldIds_);
            };
            case _ {};
        };

        var callerEntityConstraintsWorldIds : [Text] = [];
        
        switch (callerActionConstraint) {
            case(? constraints){

                var callerEntityConstraintsWorldIds_ = Buffer.Buffer<Text>(0);

                for(entityConstraint in Iter.fromArray(constraints.entityConstraint)){
                    let _wid = Option.get(entityConstraint.wid , worldPrincipalId);
                    if(Buffer.contains(callerEntityConstraintsWorldIds_, _wid, Text.equal) == false)
                        callerEntityConstraintsWorldIds_.add(_wid);
                };
                callerEntityConstraintsWorldIds := Buffer.toArray(callerEntityConstraintsWorldIds_);
            };
            case _ {};
        };

        var targetEntityConstraintsWorldIds : [Text] = [];
        
        switch (targetActionConstraint) {
            case(? constraints){

                var targetEntityConstraintsWorldIds_ = Buffer.Buffer<Text>(0);

                for(entityConstraint in Iter.fromArray(constraints.entityConstraint)){
                    let _wid = Option.get(entityConstraint.wid , worldPrincipalId);
                    if(Buffer.contains(targetEntityConstraintsWorldIds_, _wid, Text.equal) == false)
                        targetEntityConstraintsWorldIds_.add(Option.get(entityConstraint.wid , worldPrincipalId));
                };
                targetEntityConstraintsWorldIds := Buffer.toArray(targetEntityConstraintsWorldIds_);
            };
            case _ {};
        };

        //FETCH DATA

        let worldEntityResultHandler = worldNode.getAllUserEntitiesOfSpecificWorlds(worldPrincipalId, worldEntityConstraintsWorldIds, null);
        let callerEntityResultHandler = callerNode.getAllUserEntitiesOfSpecificWorlds(callerPrincipalId, callerEntityConstraintsWorldIds, null);
        let targetEntityResultHandler = targetNode.getAllUserEntitiesOfSpecificWorlds(targetPrincipalId, targetEntityConstraintsWorldIds, null);

        //ACTIONS STATES

        let oldCallerActionStateResult = await oldCallerActionStateResultHandler;
        let oldTargetActionStateResult = await oldTargetActionStateResultHandler;
        var oldWorldActionStateResult : ?TAction.ActionState = null;

        if (worldHasOutcomes) {
            oldWorldActionStateResult := await oldWorldActionStateResultHandler;
        };

        //ENTITIES
        switch (await worldEntityResultHandler) {
            case (#ok data) worldData := data;
            case (#err errMsg) {

                debugLog("The '" #actionId # "' action failed because it could not get entities from world.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        switch (await callerEntityResultHandler) {
            case (#ok data) callerData := data;
            case (#err errMsg) {

                debugLog("The '" #actionId # "' action failed because it could not get entities from caller.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        if (targetPrincipalId == worldPrincipalId) {
            targetData := worldData;
        } else {
            switch (await targetEntityResultHandler) {
                case (#ok data) targetData := data;
                case (#err errMsg) {

                    debugLog("The '" #actionId # "' action failed because it could not get entities from target.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };
        };

        //REFINE CONSTRAINTS
        var callerRefinedConstraints : ?TAction.ActionConstraint = ?{
            timeConstraint = null;
            containEntity = [];
            entityConstraint = [];
            icpConstraint = null;
            icrcConstraint = [];
            nftConstraint = [];
        };
        var targetRefinedConstraints : ?TAction.ActionConstraint = ?{
            timeConstraint = null;
            containEntity = [];
            entityConstraint = [];
            icpConstraint = null;
            icrcConstraint = [];
            nftConstraint = [];
        };
        var worldRefinedConstraints : ?TAction.ActionConstraint = ?{
            timeConstraint = null;
            containEntity = [];
            entityConstraint = [];
            icpConstraint = null;
            icrcConstraint = [];
            nftConstraint = [];
        };

        let callerRefinedConstraintsResult = refineConstraints_(callerActionConstraint, callerPrincipalId, targetPrincipalId, actionFields);
        let targetRefinedConstraintsResult = refineConstraints_(targetActionConstraint, callerPrincipalId, targetPrincipalId, actionFields);
        let worldRefinedConstraintsResult = refineConstraints_(worldActionConstraint, callerPrincipalId, targetPrincipalId, actionFields);

        switch callerRefinedConstraintsResult {
            case (#ok(?refinedConstraint)) {
                callerRefinedConstraints := ?refinedConstraint;
            };
            case (#ok(null)) {
                callerRefinedConstraints := null;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because caller's constraint could not be refined.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        switch targetRefinedConstraintsResult {
            case (#ok(?refinedConstraint)) {
                targetRefinedConstraints := ?refinedConstraint;
            };
            case (#ok(null)) {
                targetRefinedConstraints := null;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because target's constraint could not be refined.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        switch worldRefinedConstraintsResult {
            case (#ok(?refinedConstraint)) {
                worldRefinedConstraints := ?refinedConstraint;
            };
            case (#ok(null)) {
                worldRefinedConstraints := null;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because world's constraint could not be refined.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        //VALIDATE OUTCOMES AND FETCH ACTION STATES

        var callerActionStateResultHandler = validateConstraints_(callerData, callerPrincipalId, actionId, callerRefinedConstraints, oldCallerActionStateResult);
        var targetActionStateResultHandler = validateConstraints_(targetData, targetPrincipalId, actionId, targetRefinedConstraints, oldTargetActionStateResult);

        if (worldHasOutcomes) {
            var worldActionStateResultHandler = validateConstraints_(worldData, worldPrincipalId, actionId, worldRefinedConstraints, oldWorldActionStateResult);

            switch (await worldActionStateResultHandler) {
                case (#ok(result)) { newWorldActionState := result };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not validate world constraints.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

            //

            switch (await callerActionStateResultHandler) {
                case (#ok(result)) { newCallerActionState := result };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not validate caller constraints.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

            switch (await targetActionStateResultHandler) {
                case (#ok(result)) { newTargetActionState := result };
                case (#err(errMsg)) {

                    debugLog("The '" #actionId # "' action failed because it could not validate target constraints.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

        } else {

            switch (await callerActionStateResultHandler) {
                case (#ok(result)) { newCallerActionState := result };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not validate caller constraints.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

            switch (await targetActionStateResultHandler) {
                case (#ok(result)) { newTargetActionState := result };
                case (#err(errMsg)) {

                    debugLog("The '" #actionId # "' action failed because it could not validate target constraints.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

        };

        //REFINE OUTCOMES
        var callerRefinedOutcome : [TAction.ActionOutcomeOption] = [];
        var targetRefinedOutcome : [TAction.ActionOutcomeOption] = [];
        var worldRefinedOutcome : [TAction.ActionOutcomeOption] = [];

        let callerRefinedOutcomeResult = refineAllOutcomes_(callerOutcomes, callerPrincipalId, targetPrincipalId, actionFields, worldData, callerData, ?targetData);
        let targetRefinedOutcomeResult = refineAllOutcomes_(targetOutcomes, callerPrincipalId, targetPrincipalId, actionFields, worldData, callerData, ?targetData);

        switch (callerRefinedOutcomeResult) {
            case (#ok _callerRefinedOutcome) {
                callerRefinedOutcome := _callerRefinedOutcome;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because it could not be executed.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        switch (targetRefinedOutcomeResult) {
            case (#ok _targetRefinedOutcome) {
                targetRefinedOutcome := _targetRefinedOutcome;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because it could not refine outcome target.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        if (worldHasOutcomes) {

            var worldRefinedOutcomeResult = refineAllOutcomes_(Option.get(worldOutcomes, []), callerPrincipalId, targetPrincipalId, actionFields, worldData, callerData, ?targetData);

            switch worldRefinedOutcomeResult {
                case (#ok(_worldRefinedOutcome)) worldRefinedOutcome := _worldRefinedOutcome;
                case (#err(errMsg)) {
                    debugLog(errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                };
            };
        };

        //APPLY OUTCOMES
        let callerApplyOutcomesHandler = applyOutcomes_(callerPrincipalId, callerNode, newCallerActionState, callerRefinedOutcome);
        let targetApplyOutcomesHandler = applyOutcomes_(targetPrincipalId, targetNode, newTargetActionState, targetRefinedOutcome);

        let callerApplyOutcomes = await callerApplyOutcomesHandler;
        let targetApplyOutcomes = await targetApplyOutcomesHandler;

        if (worldHasOutcomes) let worldApplyOutcomes = applyOutcomes_(worldPrincipalId, worldNode, newWorldActionState, worldRefinedOutcome);

        //UNLOCK ACTION
        changeActionLockState_(callerPrincipalId, actionId, false);

        ignore tryBroadcastFetchUsersDataRequest_(callerPrincipalId);
    };

    private func processAction_(actionId : Text, actionFields : [TGlobal.Field], callerPrincipalId : Text, sourcePrincipalId : Text, sourceActionConstraint : ?TAction.ActionConstraint, worldActionConstraint : ?TAction.ActionConstraint, sourceOutcomes : [TAction.ActionOutcomeOption], worldOutcomes : ?[TAction.ActionOutcomeOption]) : async () {
        var worldHasOutcomes = worldOutcomes != null;

        //FETCH NODES IDS
        var worldNodeId : Text = "2vxsx-fae";
        var sourceNodeId : Text = "2vxsx-fae";

        let getWorldNodeHandler = getUserNode_(worldNodeId);
        let getSourceNodeHandler = getUserNode_(sourcePrincipalId);

        switch (await getWorldNodeHandler) {
            case (#ok(content)) { worldNodeId := content };
            case (#err(errMsg)) {
                debugLog("The '" #actionId # "' action failed because it could not get world node Id.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(sourcePrincipalId, actionId, false);
                return;
            };
        };

        if (sourcePrincipalId == worldPrincipalId) {
            sourceNodeId := worldNodeId;
        } else {
            switch (await getSourceNodeHandler) {
                case (#ok(content)) { sourceNodeId := content };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not get source node Id.\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(sourcePrincipalId, actionId, false);
                    return;
                };
            };
        };

        //INTERFACES

        let worldNode : UserNode = actor (worldNodeId);
        let sourceNode : UserNode = actor (sourceNodeId);

        //FETCH ACTIONS STATES SETUP
        var newCallerActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
        };
        var newWorldActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
        };

        let oldCallerActionStateResultHandler = sourceNode.getActionState(sourcePrincipalId, worldPrincipalId, actionId);
        let oldWorldActionStateResultHandler = worldNode.getActionState(worldPrincipalId, worldPrincipalId, actionId);

        //FETCH ENTITIES DATA SETUP
        var worldData : [TEntity.StableEntity] = [];
        var sourceData : [TEntity.StableEntity] = [];

        //GET WORLD IDS TO FETCH ENTITIES FROM
        var worldEntityConstraintsWorldIds : [Text] = [];
        
        switch (worldActionConstraint) {
            case(? constraints){

                var worldEntityConstraintsWorldIds_ = Buffer.Buffer<Text>(0);

                for(entityConstraint in Iter.fromArray(constraints.entityConstraint)){
                    let _wid = Option.get(entityConstraint.wid , worldPrincipalId);
                    if(Buffer.contains(worldEntityConstraintsWorldIds_, _wid, Text.equal) == false)
                        worldEntityConstraintsWorldIds_.add(Option.get(entityConstraint.wid , worldPrincipalId));
                };
                worldEntityConstraintsWorldIds := Buffer.toArray(worldEntityConstraintsWorldIds_);
            };
            case _ {};
        };

        var sourceEntityConstraintsWorldIds : [Text] = [];
        
        switch (sourceActionConstraint) {
            case(? constraints){

                var sourceEntityConstraintsWorldIds_ = Buffer.Buffer<Text>(0);

                for(entityConstraint in Iter.fromArray(constraints.entityConstraint)){
                    let _wid = Option.get(entityConstraint.wid , worldPrincipalId);
                    if(Buffer.contains(sourceEntityConstraintsWorldIds_, _wid, Text.equal) == false)
                        sourceEntityConstraintsWorldIds_.add(_wid);
                };
                sourceEntityConstraintsWorldIds := Buffer.toArray(sourceEntityConstraintsWorldIds_);
            };
            case _ {};
        };


        //FETCH DATA

        let worldEntityResultHandler = worldNode.getAllUserEntitiesOfSpecificWorlds(worldPrincipalId, worldEntityConstraintsWorldIds, null);
        let sourceEntityResultHandler = sourceNode.getAllUserEntitiesOfSpecificWorlds(sourcePrincipalId, sourceEntityConstraintsWorldIds, null);


        let oldCallerActionStateResult = await oldCallerActionStateResultHandler;
        var oldWorldActionStateResult : ?TAction.ActionState = null;

        if (worldHasOutcomes) {
            oldWorldActionStateResult := await oldWorldActionStateResultHandler;
        };

        switch (await worldEntityResultHandler) {
            case (#ok data) worldData := data;
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because it could not get world entities\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        if (sourcePrincipalId == worldPrincipalId) {
            sourceData := worldData;
        } else {
            switch (await sourceEntityResultHandler) {
                case (#ok data) sourceData := data;
                case (#err errMsg) {
                    debugLog("The '" #actionId # "' action failed because it could not get source entities\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };
        };

        //REFINE CONSTRAINTS
        var sourceRefinedConstraints : ?TAction.ActionConstraint = ?{
            timeConstraint = null;
            containEntity = [];
            entityConstraint = [];
            icpConstraint = null;
            icrcConstraint = [];
            nftConstraint = [];
        };
        var worldRefinedConstraints : ?TAction.ActionConstraint = ?{
            timeConstraint = null;
            containEntity = [];
            entityConstraint = [];
            icpConstraint = null;
            icrcConstraint = [];
            nftConstraint = [];
        };

        let sourceRefinedConstraintsResult = refineConstraints_(sourceActionConstraint, callerPrincipalId, "", actionFields);
        let worldRefinedConstraintsResult = refineConstraints_(worldActionConstraint, callerPrincipalId, "", actionFields);

        switch sourceRefinedConstraintsResult {
            case (#ok(?refinedConstraint)) {
                sourceRefinedConstraints := ?refinedConstraint;
            };
            case (#ok(null)) {
                sourceRefinedConstraints := null;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because source's constraint could not be refined.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        switch worldRefinedConstraintsResult {
            case (#ok(?refinedConstraint)) {
                worldRefinedConstraints := ?refinedConstraint;
            };
            case (#ok(null)) {
                worldRefinedConstraints := null;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because world's constraint could not be refined.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        //VALIDATE OUTCOMES AND FETCH ACTION STATES

        var newCallerActionStateResultHandler = validateConstraints_(sourceData, sourcePrincipalId, actionId, sourceRefinedConstraints, oldCallerActionStateResult);

        if (worldHasOutcomes) {
            var worldActionStateResultHandler = validateConstraints_(worldData, worldPrincipalId, actionId, worldRefinedConstraints, oldWorldActionStateResult);

            switch (await worldActionStateResultHandler) {
                case (#ok(result)) { newWorldActionState := result };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not validate world constraints\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

            //

            switch (await newCallerActionStateResultHandler) {
                case (#ok(result)) { newCallerActionState := result };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not validate source action constraints\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

        } else {

            switch (await newCallerActionStateResultHandler) {
                case (#ok(result)) { newCallerActionState := result };
                case (#err(errMsg)) {
                    debugLog("The '" #actionId # "' action failed because it could not validate source action constraints\nExtra insight: " #errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                    return;
                };
            };

        };

        //REFINE OUTCOMES
        var sourceRefinedOutcome : [TAction.ActionOutcomeOption] = [];
        var worldRefinedOutcome : [TAction.ActionOutcomeOption] = [];

        var targetPrincipalId = "";

        if (callerPrincipalId != sourcePrincipalId) targetPrincipalId := sourcePrincipalId;

        let sourceRefinedOutcomeResult = refineAllOutcomes_(sourceOutcomes, callerPrincipalId, targetPrincipalId, actionFields, worldData, sourceData, null);

        switch (sourceRefinedOutcomeResult) {
            case (#ok _sourceRefinedOutcome) {
                sourceRefinedOutcome := _sourceRefinedOutcome;
            };
            case (#err errMsg) {
                debugLog("The '" #actionId # "' action failed because it could not refine source outcomes.\nExtra insight: " #errMsg);
                //UNLOCK ACTION
                changeActionLockState_(callerPrincipalId, actionId, false);
                return;
            };
        };

        if (worldHasOutcomes) {

            var worldRefinedOutcomeResult = refineAllOutcomes_(Option.get(worldOutcomes, []), callerPrincipalId, targetPrincipalId, actionFields, worldData, sourceData, null);

            switch worldRefinedOutcomeResult {
                case (#ok(_worldRefinedOutcome)) worldRefinedOutcome := _worldRefinedOutcome;
                case (#err(errMsg)) {
                    debugLog(errMsg);
                    //UNLOCK ACTION
                    changeActionLockState_(callerPrincipalId, actionId, false);
                };
            };
        };

        //APPLY OUTCOMES

        let sourceApplyOutcomesHandler = applyOutcomes_(sourcePrincipalId, sourceNode, newCallerActionState, sourceRefinedOutcome);

        let sourceApplyOutcomes = await sourceApplyOutcomesHandler;

        if (worldHasOutcomes) let worldApplyOutcomes = applyOutcomes_(worldPrincipalId, worldNode, newWorldActionState, worldRefinedOutcome);

        //UNLOCK ACTION
        changeActionLockState_(callerPrincipalId, actionId, false);

        ignore tryBroadcastFetchUsersDataRequest_(callerPrincipalId);
    };

    public query func getProcessActionCount() : async (Nat) {
        processActionCount;
    };

    //# Websocket Utils

    private func tryBroadcastOutcomes_(actionCallerPrincipalId : Text, outcomes : TAction.ActionReturn) : async () {
        //Broadcast action outcomes
        switch (await getAllUsersInTargetUserRoom_(actionCallerPrincipalId)) {
            case (#ok(users)) {

                for (e in Iter.fromArray(users)) {
                    if (e != actionCallerPrincipalId) {
                        let otherUserPrincipalId = e;
                        //send outcomes to the otherUser
                        ignore send_app_message(Principal.fromText(otherUserPrincipalId), #actionOutcomes outcomes);
                    };
                };
            };
            case (#err errMsg) {};
        };
    };
    private func tryBroadcastFetchUsersDataRequest_(uid : Text) : async () {
        switch (await getAllUsersInTargetUserRoom_(uid)) {
            case (#ok(users)) {

                for (e in Iter.fromArray(users)) {
                    let otherUserPrincipalId = e;
                    ignore send_app_message(Principal.fromText(otherUserPrincipalId), #userIdsToFetchDataFrom(users));
                };
            };
            case (#err errMsg) {};
        };
    };

    //If #ok it will return an Text of all users in room you are in separated by comma, including yourself
    private func isUserInRoom_(uid : Text) : async (Result.Result<TEntity.StableEntity, Text>) {

        //FETCH NODES IDS
        var worldNodeId : Text = "2vxsx-fae";

        let getWorldNodeHandler = getUserNode_(worldNodeId);

        switch (await getWorldNodeHandler) {
            case (#ok(content)) { worldNodeId := content };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };

        let worldNode : UserNode = actor (worldNodeId);

        var worldData : [TEntity.StableEntity] = [];

        let worldEntityResultHandler = worldNode.getAllUserEntities(worldPrincipalId, worldPrincipalId, null);

        switch (await worldEntityResultHandler) {
            case (#ok data) worldData := data;
            case (#err errMsg) {
                return #err errMsg;
            };
        };

        label worldEntityLoop for (e in Iter.fromArray(worldData)) {

            for (field in Iter.fromArray(e.fields)) {
                let fieldName = field.fieldName;
                let fieldValue = field.fieldValue;

                if (fieldName == "tag") {

                    if (fieldValue == "room") {

                        for (field1 in Iter.fromArray(e.fields)) {
                            let fieldName1 = field1.fieldName;
                            let fieldValue1 = field1.fieldValue;

                            if (fieldName == "users") {

                                if (Text.contains(fieldValue, #text uid)) {
                                    return #ok(e);
                                };
                            };
                        };
                    };
                };
            };
        };

        return #err("User is not in a room. UserId: " # uid);
    };
    private func getAllUsersInTargetUserRoom_(uid : Text) : async (Result.Result<[Text], Text>) {

        //FETCH NODES IDS
        var worldNodeId : Text = "2vxsx-fae";

        let getWorldNodeHandler = getUserNode_(worldNodeId);

        switch (await getWorldNodeHandler) {
            case (#ok(content)) { worldNodeId := content };
            case (#err(errMsg)) {
                return #err(errMsg);
            };
        };

        let worldNode : UserNode = actor (worldNodeId);

        var worldData : [TEntity.StableEntity] = [];

        let worldEntityResultHandler = worldNode.getAllUserEntities(worldPrincipalId, worldPrincipalId, null);

        switch (await worldEntityResultHandler) {
            case (#ok data) worldData := data;
            case (#err errMsg) {
                return #err errMsg;
            };
        };

        label worldEntityLoop for (e in Iter.fromArray(worldData)) {

            for (field in Iter.fromArray(e.fields)) {
                let fieldName = field.fieldName;
                let fieldValue = field.fieldValue;

                if (fieldName == "tag") {

                    if (fieldValue == "room") {

                        for (field1 in Iter.fromArray(e.fields)) {
                            let fieldName1 = field1.fieldName;
                            let fieldValue1 = field1.fieldValue;

                            if (fieldName1 == "users") {

                                if (Text.contains(fieldValue1, #text uid)) {

                                    let users = Text.split(fieldValue1, #char ',');

                                    return #ok(Iter.toArray(users));
                                };
                            };
                        };
                    };
                };
            };
        };

        return #err("User is not in a room. UserId: " # uid);
    };

    //# PERMISSIONS

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

    //# WORLD'S IMPORTS
    public shared ({ caller }) func importAllConfigsOfWorld(args : { ofWorldId : Text }) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let world = actor (args.ofWorldId) : actor {
            exportConfigs : shared () -> async ([TEntity.StableConfig]);
        };

        configsStorage := Trie.empty();
        for (i in (await world.exportConfigs()).vals()) {
            ignore createConfig(i);
        };
        return #ok("imported");
    };
    public shared ({ caller }) func importAllActionsOfWorld(args : { ofWorldId : Text }) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let world = actor (args.ofWorldId) : actor {
            exportActions : shared () -> async ([TAction.Action]);
        };

        actionsStorage := Trie.empty();

        for (i in (await world.exportActions()).vals()) {
            ignore createAction(i);
        };

        return #ok("imported");
    };

    public shared ({ caller }) func withdrawIcpFromWorld(args : { toPrincipal : Text }) : async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>) {
        assert (caller == owner);
        let ICP_Ledger : Ledger.ICP = actor (ENV.Ledger);
        var _amt = await ICP_Ledger.account_balance({
            account = Hex.decode(AccountIdentifier.fromText(Principal.toText(WorldId()), null));
        });
        _amt := {
            e8s = _amt.e8s - 10000;
        };
        var _req : ICP.TransferArgs = {
            to = Hex.decode(AccountIdentifier.fromText(args.toPrincipal, null));
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

    public shared ({ caller }) func withdrawIcrcFromWorld(args : { tokenCanisterId : Text; toPrincipal : Text }) : async (Result.Result<ICRC.Result, { #TxErr : ICRC.TransferError; #Err : Text }>) {
        assert (caller == owner);
        let ICRC_Ledger : Ledger.ICRC1 = actor (args.tokenCanisterId);
        var _amt = await ICRC_Ledger.icrc1_balance_of({
            owner = WorldId();
            subaccount = null;
        });
        var _fee = await ICRC_Ledger.icrc1_fee();
        _amt := _amt - _fee;
        var _req : ICRC.TransferArg = {
            to = {
                owner = Principal.fromText(args.toPrincipal);
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

    public shared ({ caller }) func importAllUsersDataOfWorld(args : { ofWorldId : Text }) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            importAllUsersDataOfWorld : (Text) -> async (Result.Result<Text, Text>);
        };
        return (await worldHub.importAllUsersDataOfWorld(args.ofWorldId));
    };

    public shared ({ caller }) func importAllPermissionsOfWorld(args : { ofWorldId : Text }) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            importAllPermissionsOfWorld : (Text) -> async (Result.Result<Text, Text>);
        };
        return (await worldHub.importAllPermissionsOfWorld(args.ofWorldId));
    };

    //# HANDLE FORMULAS
    private func replaceVariables(formula : Text, actionFields : [TGlobal.Field], worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<Text, Text>) {
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

                var variableFieldNameElements = Iter.toArray(Text.split(variable, #char '.'));

                //Entity field
                if (variableFieldNameElements.size() == 3) {
                    let source = variableFieldNameElements[0];
                    let id = variableFieldNameElements[1];
                    let variableName = variableFieldNameElements[2];
                    var variableValue = "";

                    if (source == "$caller") {
                        switch (getEntityField_(callerData, worldPrincipalId, id, variableName)) {
                            case (?_entityFieldValue) variableValue := _entityFieldValue;
                            case _ return #err("could not find field of source: " #source # " eid: " #id # " fieldName: " #variableName);
                        };
                    } else if (source == "$target") {

                        switch targetData {
                            case (?value) {
                                if (value.size() == 0) return #err "target data is empty";

                                switch (getEntityField_(value, worldPrincipalId, id, variableName)) {
                                    case (?_entityFieldValue) variableValue := _entityFieldValue;
                                    case _ return #err("could not find field of source: " #source # " eid: " #id # " fieldName: " #variableName);
                                };
                            };
                            case _ return #err "target data is null";
                        };
                    } else if (source == "$world") {
                        switch (getEntityField_(worldData, worldPrincipalId, id, variableName)) {
                            case (?_entityFieldValue) variableValue := _entityFieldValue;
                            case _ return #err("could not find field of source: " #source # "  eid: " #id # " fieldName: " #variableName);
                        };
                    } else if (source == "$config") {

                        var configResult = getSpecificConfig_(id);

                        var fields = Map.new<Text, Text>();

                        switch configResult {
                            case (?config) {
                                fields := config.fields;
                            };
                            case _ return #err("could not find config, cid: " #id # " fieldName: " #variableName);
                        };

                        switch (Map.get(fields, thash, variableValue)) {
                            case (?value) {

                                variableValue := value;
                            };
                            case _ return #err("could not find config field of source: config, cid: " #id # " fieldName: " #variableName);
                        };

                        if (Text.contains(variableValue, #char '@')) {

                            switch (evaluateFormula(variableValue, actionFields, worldData, callerData, targetData)) {
                                case (#ok configFormulaOutcome) {
                                    variableValue := Float.toText(configFormulaOutcome);
                                };
                                case (#err errMsg) {
                                    return #err errMsg;
                                };
                            };
                        };
                    };

                    returnValue := Text.replace(returnValue, #text("{" #variable # "}"), variableValue);
                } else if (variableFieldNameElements.size() == 2) {
                    if (variableFieldNameElements[0] == "$args") {
                        let actionArgFieldName = variableFieldNameElements[1];

                        switch (getActionArgByFieldName_(actionArgFieldName, actionFields)) {
                            case (#ok(fieldValue)) {
                                returnValue := Text.replace(returnValue, #text("{" #variable # "}"), fieldValue);
                            };
                            case (#err errMsg) return #err errMsg;
                        };

                    };
                };
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
        let getWorldEntitiesHandler = getAllUserEntities({
            uid = worldPrincipalId;
            page = null;
        });

        let getCallerEntitiesHandler = getAllUserEntities({
            uid = callerPrincipalId;
            page = null;
        });

        if (hasTarget) {
            let getTargetEntitiesHandler = getAllUserEntities({
                uid = _targetPrincipalId;
                page = null;
            });

            let targetDataResult = await getTargetEntitiesHandler;

            switch targetDataResult {
                case (#ok data) targetData := ?data;
                case (#err errMsg) return #err errMsg;
            };
        };

        let worldDataResult = await getWorldEntitiesHandler;

        let callerDataResult = await getCallerEntitiesHandler;

        switch worldDataResult {
            case (#ok data) worldData := data;
            case (#err errMsg) return #err errMsg;
        };

        switch callerDataResult {
            case (#ok data) callerData := data;
            case (#err errMsg) return #err errMsg;
        };

        return #ok(worldData, callerData, targetData);
    };
    //To be able to access entities fields of "caller" "target" and "world"; and to also be able to access configs
    private func evaluateFormula(formula : Text, actionFields : [TGlobal.Field], worldData : [TEntity.StableEntity], callerData : [TEntity.StableEntity], targetData : ?[TEntity.StableEntity]) : (Result.Result<Float, Text>) {
        var _formula = Text.replace(formula, #char ' ', "");
        //REPLACE VARIABLES

        switch (replaceVariables(_formula, actionFields, worldData, callerData, targetData)) {
            case (#ok value) {
                _formula := value;
            };
            case (#err errMsg) return #err errMsg;
        };

        //EXECUTE FORMULA
        return FormulaEvaluation.evaluate(_formula);
    };

    //# LOGS
    private var logs = Buffer.Buffer<Text>(0);
    private var logsCount = 0;
    public query func logsGet() : async ([Text]) {
        var a = Buffer.toArray(logs);
        return a;
    };

    public shared func logsClear() : async () {
        logs := Buffer.Buffer<Text>(0);
        logsCount := 0;
    };

    public query func logsGetCount() : async (Nat) {
        return logs.size();
    };
    private func debugLog(msg : Text) : () {
        logs.add("index: " #Nat.toText(logsCount) # " -> " #msg);
        logsCount += 1;
    };

    //

    // NFID <-> ICRC-28 implementation for trusted origins
    private stable var trusted_origins : [Text] = [];

    public shared ({ caller }) func get_trusted_origins() : async ([Text]) {
        return trusted_origins;
    };

    public shared ({ caller }) func addTrustedOrigins(args : { originUrl : Text }) : async () {
        var b : Buffer.Buffer<Text> = Buffer.fromArray(trusted_origins);
        b.add(args.originUrl);
        trusted_origins := Buffer.toArray(b);
    };

    public shared ({ caller }) func removeTrustedOrigins(args : { originUrl : Text }) : async () {
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in trusted_origins.vals()) {
            if (args.originUrl != i) {
                b.add(i);
            };
        };
        trusted_origins := Buffer.toArray(b);
    };
    //# Websocket

    let gateway_principal : Text = "3656s-3kqlj-dkm5d-oputg-ymybu-4gnuq-7aojd-w2fzw-5lfp2-4zhx3-4ae";

    var ws_state = IcWebSocketCdk.IcWebSocketState([gateway_principal]);

    public type WSSentArg = {
        #actionOutcomes : TAction.ActionReturn;
        #userIdsToFetchDataFrom : [Text];
    };

    /// A custom function to send the message to the client
    func send_app_message(client_principal : IcWebSocketCdk.ClientPrincipal, msg : WSSentArg) : async () {
        // here we call the ws_send from the CDK!!
        switch (await IcWebSocketCdk.ws_send(ws_state, client_principal, to_candid (msg))) {
            case (#Err(errMsg)) {
                debugLog("Websocket Error -> " #errMsg);
            };
            case (_) {};
        };
    };

    func on_open(args : IcWebSocketCdk.OnOpenCallbackArgs) : async () {

        let uid = Principal.toText(args.client_principal);

        ignore tryBroadcastFetchUsersDataRequest_(uid);
    };

    func on_message(args : IcWebSocketCdk.OnMessageCallbackArgs) : async () {};

    func on_close(args : IcWebSocketCdk.OnCloseCallbackArgs) : async () {
        let uid = Principal.toText(args.client_principal);

        //CHECK IF USER IS IN ANY ROOM
        switch (await isUserInRoom_(uid)) {
            case (#ok(room)) {

                //TRY RECREATE FIELDS WHERE USER IS REMOVED FROM USERS FIELD
                //WE DONT ADD USERS FIELD TO THE BUFFER UNTIL THE END
                var newFields = Buffer.Buffer<TGlobal.Field>(0);

                var newUsersValue : ?Text = null;
                label fieldsLoop for (field in Iter.fromArray(room.fields)) {

                    let fieldName = field.fieldName;
                    let fieldValue = field.fieldValue;

                    if (fieldName == "tag") {

                        if (fieldValue == "room") {

                            for (field1 in Iter.fromArray(room.fields)) {

                                let fieldName1 = field1.fieldName;
                                let fieldValue1 = field1.fieldValue;

                                if (fieldName == "users") {

                                    if (Text.contains(fieldValue, #text uid)) {

                                        let users = Text.split(fieldValue, #char ',');

                                        var elementRemoved = false;

                                        label usersLoop for (e in users) {

                                            if (elementRemoved == false) {

                                                if (e == uid) {
                                                    elementRemoved := true;
                                                    continue usersLoop;
                                                };
                                            };

                                            if (newUsersValue != ?"") {
                                                newUsersValue := ?(Option.get(newUsersValue, "") # "," #e);
                                            } else newUsersValue := ?e;
                                        };

                                        continue fieldsLoop;
                                    };
                                };
                            };
                        };
                    };

                    newFields.add({
                        fieldName = fieldName;
                        fieldValue = fieldValue;
                    });
                };

                //THIS IS TO CHECK IF THERE IS ANY USER IN THE ROOM OR WHETHER OR NOT THE ROOM REALLY EXIST
                switch (newUsersValue) {
                    case (?users) {
                        //HERE WE ADD THE USERS FIELD
                        newFields.add({
                            fieldName = "users";
                            fieldValue = users;
                        });

                        ignore editEntity_({
                            uid = worldPrincipalId;
                            eid = room.eid;
                            fields = Buffer.toArray(newFields);
                        });
                    };
                    case _ {} // No need to do anything here
                };
            };
            case (#err errMsg) {
                debugLog("Websocket Error -> " #errMsg);
            };
        };
    };

    let handlers = IcWebSocketCdk.WsHandlers(
        ?on_open,
        ?on_message,
        ?on_close,
    );

    let params = IcWebSocketCdk.WsInitParams(
        handlers,
        null,
        null,
        null,
    );

    var ws = IcWebSocketCdk.IcWebSocket(ws_state, params);

    // method called by the WS Gateway after receiving FirstMessage from the client
    public shared ({ caller }) func ws_open(args : IcWebSocketCdk.CanisterWsOpenArguments) : async IcWebSocketCdk.CanisterWsOpenResult {
        await ws.ws_open(caller, args);
    };

    // method called by the Ws Gateway when closing the IcWebSocket connection
    public shared ({ caller }) func ws_close(args : IcWebSocketCdk.CanisterWsCloseArguments) : async IcWebSocketCdk.CanisterWsCloseResult {
        await ws.ws_close(caller, args);
    };

    // method called by the frontend SDK to send a message to the canister
    public shared ({ caller }) func ws_message(args : IcWebSocketCdk.CanisterWsMessageArguments, msg : ?WSSentArg) : async IcWebSocketCdk.CanisterWsMessageResult {
        await ws.ws_message(caller, args, msg);
    };

    // method called by the WS Gateway to get messages for all the clients it serves
    public shared query ({ caller }) func ws_get_messages(args : IcWebSocketCdk.CanisterWsGetMessagesArguments) : async IcWebSocketCdk.CanisterWsGetMessagesResult {
        ws.ws_get_messages(caller, args);
    };

    // method to validate Entities and EntityConstraints for User Quest Status
    public query func validateEntityConstraints(entities : [TEntity.StableEntity], entityConstraints : [TConstraints.EntityConstraint]) : async (Bool) {
        switch (validateEntityConstraints_(entities, entityConstraints)) {
            case (#err(errMsg)) return false;
            case _ return true;
        };
    };

};
