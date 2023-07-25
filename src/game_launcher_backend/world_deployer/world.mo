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

import JSON "../utils/Json";
import Parser "../utils/Parser";
import ENV "../utils/Env";
import Utils "../utils/Utils";
import Leaderboard "../modules/Leaderboard";
import Json "../utils/Json";
import RandomUtil "../utils/RandomUtil";
import EXTCORE "../utils/Core";
import EXT "../types/ext.types";
import AccountIdentifier "../utils/AccountIdentifier";
import ICP "../types/icp.types";
import ICRC "../types/icrc.types";
import TGlobal "../types/global.types";
import TEntity "../types/entity.types";
import TAction "../types/action.types";
import TStaking "../types/staking.types";

import Config "../modules/Configs";

actor class WorldTemplate(owner : Principal) = this {
    private stable var tokens_decimals : Trie.Trie<Text, Nat8> = Trie.empty();
    private stable var tokens_fees : Trie.Trie<Text, Nat> = Trie.empty();
    private stable var total_nft_count : Trie.Trie<Text, Nat32> = Trie.empty();
    private func WorldId() : Principal = Principal.fromActor(this);

    //Interfaces
    type EntityPermission = {};
    type UserNode = actor {
        processAction : shared (uid : TGlobal.userId, aid : TGlobal.actionId, actionConstraint : ?TAction.ActionConstraint, outcomes : [TAction.ActionOutcomeOption]) -> async (Result.Result<[TEntity.Entity], Text>);
        getAllUserWorldEntities : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TEntity.Entity], Text>);
        getAllUserWorldActions : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TAction.Action], Text>);
    };
    type WorldHub = actor {
        createNewUser : shared (Principal) -> async (Result.Result<Text, Text>);
        getUserNodeCanisterId : shared (Text) -> async (Result.Result<Text, Text>);

        grantEntityPermission : shared (Text, Text, Text, TEntity.EntityPermission) -> async (); //args -> (groupId, entityId, principal, permissions)
        removeEntityPermission : shared (Text, Text, Text) -> async (); //args -> (groupId, entityId, principal)
        grantGlobalPermission : shared (Text) -> async (); //args -> (principal)
        removeGlobalPermission : shared (Text) -> async (); //args -> (principal)
    };
    let worldHub : WorldHub = actor(ENV.WorldHubCanisterId);
    
    type StakingHub = actor {
        getUserStakes : shared (Text) -> async ([TStaking.Stake]);
    };
    let stakingHub : StakingHub = actor(ENV.StakingHubCanisterId);
    
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
    let paymentHub : PaymentHub = actor(ENV.PaymentHubCanisterId);

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

    //stable memory
    private stable var _owner : Text = Principal.toText(owner);
    private stable var _admins : [Text] = [Principal.toText(owner)]; 

    //Configs
    private var entityConfigs = Buffer.Buffer<TEntity.EntityConfig>(0);
    private stable var tempUpdateEntityConfig : Config.EntityConfigs = [];

    private var actionConfigs = Buffer.Buffer<TAction.ActionConfig>(0);
    private stable var tempUpdateActionConfig : Config.ActionConfigs = [];

    system func preupgrade() {        
        tempUpdateEntityConfig := Buffer.toArray(entityConfigs);

        tempUpdateActionConfig := Buffer.toArray(actionConfigs);
    };
    system func postupgrade() {
        entityConfigs := Buffer.fromArray(tempUpdateEntityConfig);
        tempUpdateEntityConfig := [];

        actionConfigs := Buffer.fromArray(tempUpdateActionConfig);
        tempUpdateActionConfig := [];
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
        switch (Trie.find(tokens_fees, Utils.keyT(tokenCanisterId), Text.equal)) {
            case (?f){
                return f;
            };
            case _ {
                let token : ICRC = actor (tokenCanisterId);
                let fee = await token.icrc1_fee();
                tokens_fees := Trie.put(tokens_fees, Utils.keyT(tokenCanisterId), Text.equal, fee).0;
                return fee;
            };
        }
    };

    private func tokenDecimal_(tokenCanisterId : Text) : async (Nat8) {
        switch (Trie.find(tokens_decimals, Utils.keyT(tokenCanisterId), Text.equal)) {
            case (?d){
                return d;
            };
            case _ {
                let token : ICRC = actor (tokenCanisterId);
                let decimals = await token.icrc1_decimals();
                tokens_decimals := Trie.put(tokens_decimals, Utils.keyT(tokenCanisterId), Text.equal, decimals).0;
                return decimals;
            };
        }
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

    public query func getOwner() : async Text {return Principal.toText(owner)};

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    //GET CONFIG
    private func _getSpecificEntityConfig(eid : Text, gid : Text) : (? TEntity.EntityConfig) {
        for (config in entityConfigs.vals()) {
            if(config.eid == eid) {
                if(config.gid == gid){
                    return ? config;
                };
            };
        };
        return null;
    };
    private func _getSpecificActionConfig(aid : Text) : (? TAction.ActionConfig) {
        for (config in actionConfigs.vals()) {
            if(config.aid == aid) return ? config;
        };
        return null;
    };

    public query func getEntityConfigs() : async ([TEntity.EntityConfig]){
        return Buffer.toArray(entityConfigs);
    };
    public query func getActionConfigs() : async ([TAction.ActionConfig]){
        return Buffer.toArray(actionConfigs);
    };

    public func importEntityConfigs() : async ([TEntity.EntityConfig]){
        return Buffer.toArray(entityConfigs);
    };
    public func importActionConfigs() : async ([TAction.ActionConfig]){
        return Buffer.toArray(actionConfigs);
    };

    //CHECK CONFIG
    private func _configEntityExist(eid : Text, gid : Text) : (Bool, Int){
        var index = 0;
        for(configElement in entityConfigs.vals()){
            if(configElement.eid == eid) {
                if(configElement.gid == gid){
                    return (true, index);
                };
            };
            index += 1;
        };
        return (false, -1);
    };
    private func _configActionExist(aid : Text) : (Bool, Int){
        var index = 0;
        for(configElement in actionConfigs.vals()){
            if(configElement.aid == aid) {
                return (true, index);
            };
            index += 1;
        };
        return (false, -1);
    };
    //CREATE CONFIG
    public shared ({ caller }) func createEntityConfig(config : TEntity.EntityConfig) : async (Result.Result<Text, Text>) {
        assert(isAdmin_(caller));
        let configExist = _configEntityExist(config.eid, config.gid);
        if(configExist.0 == false){
            entityConfigs.add(config);
            return #ok("all good :)");
        };
        return #err("there is an entity already using that id, you can try updateConfig");
    };
    public shared ({ caller }) func createActionConfig(config : TAction.ActionConfig) : async (Result.Result<Text, Text>) {
        assert(isAdmin_(caller));
        let configExist = _configActionExist(config.aid);
        if(configExist.0 == false){
            actionConfigs.add(config);
            return #ok("all good :)");
        };
        return #err("there is an action already using that id, you can try updateConfig");
    };
    //UPDATE CONFIG
    public shared ({ caller }) func updateEntityConfig(config : TEntity.EntityConfig) : async (Result.Result<Text, Text>) {
        assert(isAdmin_(caller));
        let configExist = _configEntityExist(config.eid, config.gid);
        if(configExist.0){
            var index = Utils.intToNat(configExist.1);
            entityConfigs.put(index, config);
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func updateActionConfig(config : TAction.ActionConfig) : async (Result.Result<Text, Text>) {
        assert(isAdmin_(caller));
        let configExist = _configActionExist(config.aid);
        if(configExist.0){
            var index = Utils.intToNat(configExist.1);
            actionConfigs.put(index, config);
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //DELETE CONFIG
    public shared ({ caller }) func deleteEntityConfig(eid : Text, gid : Text) : async (Result.Result<Text, Text>) {
        assert(isAdmin_(caller));
        let configExist = _configEntityExist(eid, gid);
        if(configExist.0){
            ignore entityConfigs.remove(Utils.intToNat(configExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func deleteActionConfig(aid : Text) : async (Result.Result<Text, Text>) {
        assert(isAdmin_(caller));
        let configExist = _configActionExist(aid);
        if(configExist.0){
            ignore actionConfigs.remove(Utils.intToNat(configExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //RESET CONFIG
    public shared ({ caller }) func resetConfig() : async (Result.Result<(), ()>) {
        assert(isAdmin_(caller));
        entityConfigs := Buffer.fromArray(Config.entityConfigs);
        actionConfigs := Buffer.fromArray(Config.actionConfigs);
        return #ok();
    };

    //Get Actions
    public shared ({ caller }) func getAllUserWorldActions() : async (Result.Result<[TAction.Action], Text>){
        let worldId = WorldId();

        var userNodeId : Text = "2vxsx-fae";

        let uid = Principal.toText(caller);
        switch (await worldHub.getUserNodeCanisterId(uid)){
            case (#ok(okMsg0)){
                userNodeId := okMsg0;
            };
            case(#err(errMsg0)) {

                var newUserNodeId = await worldHub.createNewUser(caller);
                switch(newUserNodeId){
                    case(#ok(okMsg1)){
                        userNodeId := okMsg1;
                    };
                    case(#err(errMsg1)){
                        return #err("user doesnt exist, thus, tried to created it, but failed on the attempt, msg: "#(errMsg0# " " #errMsg1));
                    };
                };
            };
        };
        
        let userNode : UserNode = actor(userNodeId);
        return await userNode.getAllUserWorldActions(uid, Principal.toText(worldId))
    };
    //Get Entities
    public shared ({ caller }) func getAllUserWorldEntities() : async (Result.Result<[TEntity.Entity], Text>){
        let worldId = WorldId();

        var userNodeId : Text = "2vxsx-fae";

        let uid = Principal.toText(caller);
        switch (await worldHub.getUserNodeCanisterId(uid)){
            case (#ok(okMsg0)){
                userNodeId := okMsg0;
            };
            case(#err(errMsg0)) {

                var newUserNodeId = await worldHub.createNewUser(caller);
                switch(newUserNodeId){
                    case(#ok(okMsg1)){
                        userNodeId := okMsg1;
                    };
                    case(#err(errMsg1)){
                        return #err("user doesnt exist, thus, tried to created it, but failed on the attempt, msg: "#(errMsg0# " " #errMsg1));
                    };
                };
            };
        };
        
        let userNode : UserNode = actor(userNodeId);
        return await userNode.getAllUserWorldEntities(uid, Principal.toText(worldId))
    };
    //Burn and Mint NFT's
    private func burnNft_(collectionCanisterId : Text, tokenindex : EXT.TokenIndex, uid : Principal) : async (Result.Result<(), Text>) {
        let accountId : Text = AccountIdentifier.fromPrincipal(uid, null);
        if(accountId == "") return #err("Issue getting aid from uid");
        var tokenid : EXT.TokenIdentifier = EXTCORE.TokenIdentifier.fromText(collectionCanisterId, tokenindex);
        let collection = actor (collectionCanisterId) : actor {
            ext_burn : (EXT.TokenIdentifier, EXT.AccountIdentifier) -> async (Result.Result<(), EXT.CommonError>);
        };
        var res : Result.Result<(), EXT.CommonError> = await collection.ext_burn(tokenid, accountId);
        switch (res) {
            case (#ok _) {
                return #ok();
            };
            case (#err e) {
                return #err("Nft Burn, Something went wrong while burning nft");
            };
        };
    };
    //Payments : redirected to PaymentHub for verification and holding update.
    private func verifyTxIcp_(blockIndex : Nat64, toPrincipal : Text, fromPrincipal : Text, amt : Nat64) : async (Result.Result<(), Text>) {
    
        switch (await paymentHub.verifyTxIcp(blockIndex, toPrincipal, fromPrincipal, amt)) {
            case (#Success s) {
                return #ok();
            };
            case (#Err e) {
                return #err(e);
            };
        };
    };
    private func verifyTxIcrc_(blockIndex : Nat, toPrincipal : Text, fromPrincipal : Text, amt : Nat, tokenCanisterId : Text) : async (Result.Result<(), Text>) {

        switch (await paymentHub.verifyTxIcrc(blockIndex, toPrincipal, fromPrincipal, amt, tokenCanisterId)) {
            case (#Success s) {
                
                return #ok();
            };
            case (#Err e) {
                return #err(e);
            };
        };
    };

    //Process Action
    private func generateActionResultOutcomes_(actionResult : TAction.ActionResult) : async ([TAction.ActionOutcomeOption]) {
        var outcomes = Buffer.Buffer<TAction.ActionOutcomeOption>(0);
        for (outcome in actionResult.outcomes.vals()) {
        var accumulated_weight : Float = 0;

        //A) Compute total weight on the current outcome
        for (outcomeOption in outcome.possibleOutcomes.vals()) {
            accumulated_weight += outcomeOption.weight;
        };

        //B) Gen a random number using the total weight as max value
        let rand_perc = await RandomUtil.get_random_perc();
        var dice_outcome = (rand_perc * 1.0 * accumulated_weight);

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
    private func handleOutcomes_(uid : Text, actionId: Text, actionConfig : TAction.ActionConfig) : async (Result.Result<[TAction.ActionOutcomeOption], Text>){
        
        let outcomes : [TAction.ActionOutcomeOption] = await generateActionResultOutcomes_(actionConfig.actionResult);

        var userNodeId : Text = "2vxsx-fae";
        switch (await worldHub.getUserNodeCanisterId(uid)){
            case (#ok c){
                userNodeId := c;
            };
            case _ {
                return #err("user node id not found");
            };
        };
        
        let userNode : UserNode = actor(userNodeId);

        ignore userNode.processAction(uid, actionId, actionConfig.actionConstraint, outcomes);

        let accountId : Text = AccountIdentifier.fromText(uid, null);

        var processedResult = Buffer.Buffer<TAction.ActionOutcomeOption>(0);

        var nftsToMint : Trie.Trie<Text, Buffer.Buffer<(EXT.AccountIdentifier, EXT.Metadata)>>  = Trie.empty();

        //Mint Tokens and add them along with entities to the return value
        for(outcome in outcomes.vals()) {
            switch (outcome.option) {
                case (#mintNft val){ 
                    let nftCollection : NFT = actor(val.canister);
                    switch (Trie.find(total_nft_count, Utils.keyT(val.canister), Text.equal)) {
                        case (?collectionNftCount){
                            ignore nftCollection.ext_mint([(accountId,
                            #nonfungible {
                                name = "";
                                asset = val.assetId;
                                thumbnail = val.assetId;
                                metadata = ? #json(val.metadata);
                            })]);

                            processedResult.add({
                                weight = outcome.weight;
                                option = #mintNft {
                                    index = ? collectionNftCount;
                                    canister  = val.canister;
                                    assetId = val.assetId;
                                    metadata = val.metadata;
                                };
                            });

                            ignore Trie.put(total_nft_count, Utils.keyT(val.canister), Text.equal, collectionNftCount + 1);
                        };
                        case _ {

                            var mintResult = await nftCollection.ext_mint([(accountId,
                            #nonfungible {
                                name = "";
                                asset = val.assetId;
                                thumbnail = val.assetId;
                                metadata = ? #json(val.metadata);
                            })]);
                            //
                            processedResult.add({
                                weight = outcome.weight;
                                option = #mintNft {
                                    index = ? mintResult[0];
                                    canister  = val.canister;
                                    assetId = val.assetId;
                                    metadata = val.metadata;
                                };
                            });

                            ignore Trie.put(total_nft_count, Utils.keyT(val.canister), Text.equal, mintResult[0] + 1).0;
                        };
                    };

                }; //DO NOTHING HERE
                //Mint Tokens
                case (#mintToken val){
                    //
                    processedResult.add(outcome);
                    //
                    let icrcLedger : ICRC.Self = actor(val.canister);
                    let fee = await tokenFee_(val.canister);
                    let decimals = await tokenDecimal_(val.canister);


                    //IF YOU WANT TO HANDLE ERRORS COMMENT OUT THIS CODE AND UNCOMMENT OUT THE ONE BELOW
                    ignore icrcLedger.icrc1_transfer({
                        to  = {owner = Principal.fromText(uid); subaccount = null};
                        fee = ? fee;
                        memo = ? []; 
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

        return #ok(Buffer.toArray(processedResult));
    };
    
    public shared ({ caller }) func processAction(actionArg: TAction.ActionArg): async (Result.Result<[TAction.ActionOutcomeOption], Text>) { 
        //Todo: Check for each action the timeConstraint
        switch(actionArg){
            case(#default(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
            case(#burnNft(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);

                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #burnNft(actionPluginConfig)){
                                switch(await burnNft_(actionPluginConfig.canister, arg.index, caller))
                                {
                                    case(#ok()){
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(#err(msg)){
                                        return #err(msg)
                                    };
                                }
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"burnNft\" mismatches config type")
                            }
                        }
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    }
                }
            };
            case(#verifyTransferIcp(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);

                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #verifyTransferIcp(actionPluginConfig)){

                                let decimals = await tokenDecimal_(ENV.Ledger);

                                switch(await verifyTxIcp_(arg.blockIndex, actionPluginConfig.toPrincipal, Principal.toText(caller) , Nat64.fromNat(Utils.convertToBaseUnit(actionPluginConfig.amt, decimals)))){
                                    case(#ok()){
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(#err(msg)){
                                        let fee = await tokenFee_(ENV.Ledger);

                                        return #err(msg#", amount:"#Float.toText(actionPluginConfig.amt)#", baseUnitAmount: "#Nat.toText (Utils.convertToBaseUnit(actionPluginConfig.amt, decimals))#", decimals:"#Nat.toText (Nat8.toNat(decimals))#", fee:"#Nat.toText(fee))
                                    };
                                }
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"spendTokens\" mismatches config type")
                            }
                        }
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    }
                };
            };
            case(#verifyTransferIcrc(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);

                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #verifyTransferIcrc(actionPluginConfig)){
                                
                                let decimals = await tokenDecimal_(actionPluginConfig.canister);

                                switch(await verifyTxIcrc_(arg.blockIndex, actionPluginConfig.toPrincipal, Principal.toText(caller), Utils.convertToBaseUnit(actionPluginConfig.amt, decimals), actionPluginConfig.canister))
                                {
                                    case(#ok()){
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(#err(msg)){
                                        let fee = await tokenFee_(actionPluginConfig.canister);

                                        return #err(msg#", amount:"#Float.toText(actionPluginConfig.amt)#", baseUnitAmount: "#Nat.toText (Utils.convertToBaseUnit(actionPluginConfig.amt, decimals))#", decimals:"#Nat.toText (Nat8.toNat(decimals))#", fee:"#Nat.toText(fee))
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"spendTokens\" mismatches config type")
                            }
                        }
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    }
                };
            };
            case(#claimStakingRewardNft(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #claimStakingRewardNft(actionPluginConfig)){

                                let callerText = Principal.toText(caller);

                                let stakes = await stakingHub.getUserStakes(callerText);

                                var foundStake : ? TStaking.Stake = null;

                                label stakesLoop for(stake in stakes.vals()){
                                    if(stake.canister_id == actionPluginConfig.canister){
                                        foundStake := ? stake;
                                        break stakesLoop;
                                    };
                                };
                                
                                switch(foundStake){
                                    case(? selectedStakeData){
                                        if(selectedStakeData.amount < actionPluginConfig.requiredAmount)  return #err("stake of id: \""#actionPluginConfig.canister#"\" doesnt meet amount requirement");
                                        //
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(_){
                                        return #err("nft stake of id: \""#actionPluginConfig.canister#"\" could not be found");
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
            case(#claimStakingRewardIcp(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #claimStakingRewardIcp(actionPluginConfig)){

                                let callerText = Principal.toText(caller);

                                let stakes = await stakingHub.getUserStakes(callerText);

                                var foundStake : ? TStaking.Stake = null;

                                label stakesLoop for(stake in stakes.vals()){
                                    if(stake.canister_id == ENV.Ledger){
                                        foundStake := ? stake;
                                        break stakesLoop;
                                    };
                                };
                                
                                switch(foundStake){
                                    case(? selectedStakeData){
                                        
                                        let decimals = await tokenDecimal_(ENV.Ledger);

                                        if(selectedStakeData.amount < Utils.convertToBaseUnit(actionPluginConfig.requiredAmount, decimals))  return #err("icp stake doesnt meet amount requirement");
                                        //
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(_){
                                        return #err("icp stake could not be found");
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
            case(#claimStakingRewardIcrc(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #claimStakingRewardIcrc(actionPluginConfig)){

                                let callerText = Principal.toText(caller);

                                let stakes = await stakingHub.getUserStakes(callerText);

                                var foundStake : ? TStaking.Stake = null;

                                label stakesLoop for(stake in stakes.vals()){
                                    if(stake.canister_id == actionPluginConfig.canister){
                                        foundStake := ? stake;
                                        break stakesLoop;
                                    };
                                };
                                
                                switch(foundStake){
                                    case(? selectedStakeData){

                                        let decimals = await tokenDecimal_(actionPluginConfig.canister);

                                        if(selectedStakeData.amount < Utils.convertToBaseUnit(actionPluginConfig.requiredAmount, decimals))  return #err("stake of id: \""#actionPluginConfig.canister#"\" doesnt meet amount requirement");
                                        //
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(_){
                                        return #err("icrc stake of id: \""#actionPluginConfig.canister#"\" could not be found");
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
        }
    };

    // for permissions
    public shared ({ caller }) func grantEntityPermission(groupId : Text, entityId : Text, principal : Text, permission : TEntity.EntityPermission) : async () {
        assert(isAdmin_(caller));
        await worldHub.grantEntityPermission(groupId, entityId, principal, permission);
    };

    public shared ({ caller }) func removeEntityPermission(groupId : Text, entityId : Text, principal : Text) : async () {
        assert(isAdmin_(caller));
        await worldHub.removeEntityPermission(groupId, entityId, principal);
    };

    public shared ({ caller }) func grantGlobalPermission(principal : Text) : async () {
        assert(isAdmin_(caller));
        await worldHub.grantGlobalPermission(principal);
    };

    public shared ({ caller }) func removeGlobalPermission(principal : Text) : async () {
        assert(isAdmin_(caller));
        await worldHub.removeGlobalPermission(principal);
    };


    // Import other worlds Configs endpoints
    public shared ({ caller }) func importAllConfigsOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert(caller == owner);
        let world = actor (ofWorldId) : actor {
            importEntityConfigs : shared () -> async ([TEntity.EntityConfig]);
            importActionConfigs : shared () -> async ([TAction.ActionConfig]);
        };
        entityConfigs := Buffer.fromArray((await world.importEntityConfigs()));
        actionConfigs := Buffer.fromArray((await world.importActionConfigs()));
        return #ok("imported");
    };

    public shared ({caller}) func withdrawIcpFromPaymentHub() : async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>) {
        assert(caller == owner);
        let paymentHub = actor (ENV.PaymentHubCanisterId) : actor {
            withdrawIcp : () -> async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>);
        };
        await paymentHub.withdrawIcp();
    };

    public shared ({caller}) func withdrawIcrcFromPaymentHub(tokenCanisterId : Text) : async (Result.Result<ICRC.Result, { #TxErr : ICRC.TransferError; #Err : Text }>) {
        assert(caller == owner);
        let paymentHub = actor (ENV.PaymentHubCanisterId) : actor {
            withdrawIcrc : (Text) -> async (Result.Result<ICRC.Result, { #TxErr : ICRC.TransferError; #Err : Text }>);
        };
        await paymentHub.withdrawIcrc(tokenCanisterId);
    };

    public shared ({caller}) func getEntityPermissionsOfWorld() : async [(Text, [(Text, EntityPermission)])] {
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            getEntityPermissionsOfWorld : () -> async ([(Text, [(Text, EntityPermission)])]);
        };
        return (await worldHub.getEntityPermissionsOfWorld());
    };

    public shared ({caller}) func getGlobalPermissionsOfWorld() : async ([TGlobal.userId]) {
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            getGlobalPermissionsOfWorld : () -> async [TGlobal.userId];
        };
        return (await worldHub.getGlobalPermissionsOfWorld());
    };

    public shared({caller}) func importAllUsersDataOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert(caller == owner);
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            importAllUsersDataOfWorld : (Text) -> async (Result.Result<Text, Text>);
        };
        return (await worldHub.importAllUsersDataOfWorld(ofWorldId));
    };

    public shared({caller}) func importAllPermissionsOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert(caller == owner);
        let worldHub = actor (ENV.WorldHubCanisterId) : actor {
            importAllPermissionsOfWorld : (Text) -> async (Result.Result<Text, Text>);
        };
        return (await worldHub.importAllPermissionsOfWorld(ofWorldId));
    };

};