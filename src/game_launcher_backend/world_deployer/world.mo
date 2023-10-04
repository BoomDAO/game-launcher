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

import Parser "../utils/Parser";
import ENV "../utils/Env";
import Utils "../utils/Utils";
import Leaderboard "../modules/Leaderboard";
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
    private stable var tokensDecimals : Trie.Trie<Text, Nat8> = Trie.empty();
    private stable var tokensFees : Trie.Trie<Text, Nat> = Trie.empty();
    private stable var totalNftCount : Trie.Trie<Text, Nat32> = Trie.empty();
    private stable var userPrincipalToUserNode : Trie.Trie<Text, Text> = Trie.empty();
    private func WorldId() : Principal = Principal.fromActor(this);

    //Interfaces
    type UserNode = actor {
        processAction : shared (uid : TGlobal.userId, aid : TGlobal.actionId, actionConstraint : ?TAction.ActionConstraint, outcomes : [TAction.ActionOutcomeOption]) -> async (Result.Result<[TEntity.StableEntity], Text>);
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

    type StakingHub = actor {
        getUserStakes : shared (Text) -> async ([TStaking.Stake]);
    };
    let stakingHub : StakingHub = actor (ENV.StakingHubCanisterId);

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
    };

    //stable memory
    private stable var _owner : Text = Principal.toText(owner);
    private stable var _admins : [Text] = [Principal.toText(owner)];

    //Configs
    private var configs = Buffer.Buffer<TEntity.Config>(0);
    private stable var tempUpdateConfig : Config.StableConfigs = [];

    private var action = Buffer.Buffer<TAction.Action>(0);
    private stable var tempUpdateAction : Config.Actions = [];

    system func preupgrade() {
        var b = Buffer.Buffer<TEntity.StableConfig>(0);
        for(i in Buffer.toArray(configs).vals()) {
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
        for(i in tempUpdateConfig.vals()) {
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
        for (config in configs.vals()) {
            if (config.cid == cid) {
                return ?config;
            };
        };
        return null;
    };
    private func getSpecificAction_(aid : Text) : (?TAction.Action) {
        for (config in action.vals()) {
            if (config.aid == aid) return ?config;
        };
        return null;
    };
    
    public query func getAllConfigs() : async ([TEntity.StableConfig]) {
        var b = Buffer.Buffer<TEntity.StableConfig>(0);
        for(i in Buffer.toArray(configs).vals()) {
            let fields_array : [(Text, Text)] = Map.toArray(i.fields);
            b.add({
                cid = i.cid;
                fields = fields_array;
            });
        };
        return Buffer.toArray(b);
    };
    public query func getAllActions() : async ([TAction.Action]) {
        return Buffer.toArray(action);
    };

    public func exportConfigs() : async ([TEntity.StableConfig]) {
        var b = Buffer.Buffer<TEntity.StableConfig>(0);
        for(i in Buffer.toArray(configs).vals()) {
            let fields_array : [(Text, Text)] = Map.toArray(i.fields);
            b.add({
                cid = i.cid;
                fields = fields_array;
            });
        };
        return Buffer.toArray(b);
    };
    public func exportActions() : async ([TAction.Action]) {
        return Buffer.toArray(action);
    };

    //CHECK CONFIG
    private func configExist_(cid : Text) : (Bool, Int) {
        var index = 0;
        for (configElement in configs.vals()) {
            if (configElement.cid == cid) {
                return (true, index);
            };
            index += 1;
        };
        return (false, -1);
    };
    private func actionExist_(aid : Text) : (Bool, Int) {
        var index = 0;
        for (configElement in action.vals()) {
            if (configElement.aid == aid) {
                return (true, index);
            };
            index += 1;
        };
        return (false, -1);
    };
    //CREATE CONFIG
    public shared ({ caller }) func createConfig(config : TEntity.StableConfig) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = configExist_(config.cid);
        if (configExist.0 == false) {
            let {thash} = Map;
            configs.add({
                cid = config.cid;
                fields = Map.fromIter(config.fields.vals(), thash);
            });
            return #ok("all good :)");
        };
        return #err("there is an entity already using that id, you can try updateConfig");
    };
    public shared ({ caller }) func createAction(config : TAction.Action) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = actionExist_(config.aid);
        if (configExist.0 == false) {
            action.add(config);
            return #ok("all good :)");
        };
        return #err("there is an action already using that id, you can try updateConfig");
    };
    //UPDATE CONFIG
    public shared ({ caller }) func updateConfig(config : TEntity.StableConfig) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = configExist_(config.cid);
        if (configExist.0) {
            var index = Utils.intToNat(configExist.1);
            let {thash} = Map;
            configs.put(index, {
                cid = config.cid;
                fields = Map.fromIter(config.fields.vals(), thash);
            });
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func updateAction(config : TAction.Action) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = actionExist_(config.aid);
        if (configExist.0) {
            var index = Utils.intToNat(configExist.1);
            action.put(index, config);
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //DELETE CONFIG
    public shared ({ caller }) func deleteConfig(cid : Text) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = configExist_(cid);
        if (configExist.0) {
            ignore configs.remove(Utils.intToNat(configExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func deleteAction(aid : Text) : async (Result.Result<Text, Text>) {
        assert (isAdmin_(caller));
        let configExist = actionExist_(aid);
        if (configExist.0) {
            ignore action.remove(Utils.intToNat(configExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //RESET CONFIG
    public shared ({ caller }) func resetConfig() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));
        let { thash } = Map;
        for(i in Config.configs.vals()) {
            configs.add({
                cid = i.cid;
                fields = Map.fromIter(i.fields.vals(), thash);
            });
        };
        action := Buffer.fromArray(Config.action);
        return #ok();
    };
    
    public shared ({ caller }) func resetActions() : async (Result.Result<(), ()>) {
        assert (isAdmin_(caller));
        action := Buffer.fromArray(Config.action);
        return #ok();
    };

    //Get Actions
    public func getAllUserActionStates(userPrincipal :Principal) : async (Result.Result<[TAction.ActionState], Text>) {
        let worldId = WorldId();

        var userNodeId : Text = "";

        let userPrincipalTxt = Principal.toText(userPrincipal);

        switch (await getUserNode_(userPrincipalTxt)) {
            case (#ok(content)) { userNodeId := content };
            case (#err(message)) {
                return #err(message);
            };
        };

        let userNode : UserNode = actor (userNodeId);
        return await userNode.getAllUserActionStates(userPrincipalTxt, Principal.toText(worldId));
    };
    //Get Entities
    public func getAllUserEntities(userPrincipal :Principal) : async (Result.Result<[TEntity.StableEntity], Text>) {
        let worldId = WorldId();

        var userNodeId : Text = "";

        let userPrincipalTxt = Principal.toText(userPrincipal);

        switch (await getUserNode_(userPrincipalTxt)) {
            case (#ok(content)) { userNodeId := content };
            case (#err(message)) {
                return #err(message);
            };
        };

        let userNode : UserNode = actor (userNodeId);
        return await userNode.getAllUserEntities(userPrincipalTxt, Principal.toText(worldId));
    };
    //Send or Burn (it will burn if in the burn plugin config, the "to" field is null or empty)
    private func verifyBurnNfts_(userPrincipal : Principal, burnActionArg : { actionId : Text; indexes : [Nat32] }, configs : TAction.Action, outcomes : [TAction.ActionOutcomeOption]) : async () {

        switch (configs.actionPlugin) {
            case (? #verifyBurnNfts(actionPluginConfig)) {
                //
                let accountId : Text = AccountIdentifier.fromPrincipal(userPrincipal, null);
                if (accountId == "") return; //  WE RETURN DUE TO ISSUE GETTING THE aid FROM userPrincipal

                let collection : EXTInterface = actor (actionPluginConfig.canister);

                //Indexes to fetch metadata from
                let indexes = burnActionArg.indexes;
                //List of fetched metadata
                var fetchedMetadata = Buffer.Buffer<Text>(0);
                //We try to collect all metadata from the given indexes
                for (index in indexes.vals()) {
                    let optionalMetadata = await collection.getTokenMetadata(index);

                    switch (optionalMetadata) {
                        case (?metadataVariant) {
                            switch (metadataVariant) {
                                case (#nonfungible noneFungibleMetadata) {
                                    switch (noneFungibleMetadata.metadata) {
                                        case (?optionalMetadataContainer) {
                                            switch (optionalMetadataContainer) {
                                                case (#json metadataAsJson) {
                                                    fetchedMetadata.add(metadataAsJson);
                                                };
                                                case _ {
                                                    return; //IF METADATA IS NOT FOUND FOR ANY OF THE GIVEN INDEXES WE FORCE THE OPERATION TO FAIL
                                                };
                                            };
                                        };
                                        case _ {
                                            return; //IF METADATA IS NOT FOUND FOR ANY OF THE GIVEN INDEXES WE FORCE THE OPERATION TO FAIL
                                        };
                                    };
                                };
                                case _ {
                                    return; //IF METADATA IS NOT FOUND FOR ANY OF THE GIVEN INDEXES WE FORCE THE OPERATION TO FAIL
                                };
                            };
                        };
                        case _ {
                            return; //IF METADATA IS NOT FOUND FOR ANY OF THE GIVEN INDEXES WE FORCE THE OPERATION TO FAIL
                        };
                    };
                };
                //Metadata to compare against
                var optionalRequiredNftMetadata = actionPluginConfig.requiredNftMetadata;
                //Validation

                switch (optionalRequiredNftMetadata) {
                    case (?requiredNftMetadata) {
                        for (requirement in requiredNftMetadata.vals()) {
                            var hasRequirement = false;

                            var innerLoopIndex = 0;
                            label fetchedMetadataLoop for (metadata in fetchedMetadata.vals()) {
                                if (requirement == metadata) {
                                    ignore fetchedMetadata.remove(innerLoopIndex);
                                    hasRequirement := true;
                                    break fetchedMetadataLoop;
                                };
                                innerLoopIndex += 1;
                            };

                            if (hasRequirement == false) return; //IF USER DOESNT HAVE ANY OF THE REQUIREMENT WE FORCE THE OPERATION TO FAIL
                        };
                    };
                    case _ {}; //DO NOTHING HERE
                };

                //There must be at least one specified index for the operation to succeed
                if (indexes.size() == 0) return;

                //Try burn all given nft indexes
                for (index in indexes.vals()) {
                    var tokenid : EXT.TokenIdentifier = EXTCORE.TokenIdentifier.fromText(actionPluginConfig.canister, index);
                    var res : Result.Result<(), EXT.CommonError> = await collection.ext_burn(tokenid, accountId);
                    switch (res) {
                        case (#ok _) {
                            //DO NOTHING HERE
                        };
                        case (#err e) {
                            return; //Skip cuz burning failed
                        };
                    };
                };

                ignore handleOutcomes_(Principal.toText(userPrincipal), burnActionArg.actionId, configs, ?outcomes);
            };
            case (_) {
                //WE DO NOTHING HERE
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
            var rand_perc : Float = 1;

            //A) Compute total weight on the current outcome
            if (outcome.possibleOutcomes.size() > 1) {
                for (outcomeOption in outcome.possibleOutcomes.vals()) {
                    accumulated_weight += outcomeOption.weight;
                };

                //B) Gen a random number using the total weight as max value
                rand_perc := await RandomUtil.get_random_perc();
            };

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

    private func handleOutcomes_(userPrincipalTxt : Text, actionId : Text, actionConfig : TAction.Action, preGeneratedOutcomes : ?[TAction.ActionOutcomeOption]) : async (Result.Result<[TAction.ActionOutcomeOption], Text>) {

        let outcomes = switch (preGeneratedOutcomes) {
            case (?value) {
                value;
            };
            case _ {
                await generateActionResultOutcomes_(actionConfig.actionResult);
            };
        };

        var userNodeId : Text = "2vxsx-fae";

        switch (await getUserNode_(userPrincipalTxt)) {
            case (#ok(content)) { userNodeId := content };
            case (#err(message)) {
                return #err(message);
            };
        };

        let userNode : UserNode = actor (userNodeId);

        ignore userNode.processAction(userPrincipalTxt, actionId, actionConfig.actionConstraint, outcomes);

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
                case (#mintToken val) {
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

        return #ok(Buffer.toArray(processedResult));
    };

    public shared ({ caller }) func processAction(actionArg : TAction.ActionArg) : async (Result.Result<[TAction.ActionOutcomeOption], Text>) {
        //Todo: Check for each action the timeConstraint
        switch (actionArg) {
            case (#default(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {

                        switch (configs.actionPlugin) {
                            case (null) {
                                return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs, null);
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"default\" must not have actionPlugin");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
            case (#verifyBurnNfts(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {

                        switch (configs.actionPlugin) {
                            case (? #verifyBurnNfts(actionPluginConfig)) {
                                let outcomes : [TAction.ActionOutcomeOption] = await generateActionResultOutcomes_(configs.actionResult);

                                ignore verifyBurnNfts_(caller, arg, configs, outcomes);

                                return #ok(outcomes);
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"verifyBurnNfts\" mismatches config type");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
            case (#verifyTransferIcp(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {
                        switch (configs.actionPlugin) {
                            case (? #verifyTransferIcp(actionPluginConfig)) {

                                let decimals = await tokenDecimal_(ENV.Ledger);

                                switch (await verifyTxIcp_(arg.blockIndex, actionPluginConfig.toPrincipal, Principal.toText(caller), Nat64.fromNat(Utils.convertToBaseUnit(actionPluginConfig.amt, decimals)))) {
                                    case (#ok()) {
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs, null);
                                    };
                                    case (#err(msg)) {
                                        let fee = await tokenFee_(ENV.Ledger);

                                        return #err(msg # ", amount:" #Float.toText(actionPluginConfig.amt) # ", baseUnitAmount: " #Nat.toText(Utils.convertToBaseUnit(actionPluginConfig.amt, decimals)) # ", decimals:" #Nat.toText(Nat8.toNat(decimals)) # ", fee:" #Nat.toText(fee));
                                    };
                                };
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"verifyTransferIcp\" mismatches config type");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
            case (#verifyTransferIcrc(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {
                        switch (configs.actionPlugin) {
                            case (? #verifyTransferIcrc(actionPluginConfig)) {

                                let decimals = await tokenDecimal_(actionPluginConfig.canister);

                                switch (await verifyTxIcrc_(arg.blockIndex, actionPluginConfig.toPrincipal, Principal.toText(caller), Utils.convertToBaseUnit(actionPluginConfig.amt, decimals), actionPluginConfig.canister)) {
                                    case (#ok()) {
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs, null);
                                    };
                                    case (#err(msg)) {
                                        let fee = await tokenFee_(actionPluginConfig.canister);

                                        return #err(msg # ", amount:" #Float.toText(actionPluginConfig.amt) # ", baseUnitAmount: " #Nat.toText(Utils.convertToBaseUnit(actionPluginConfig.amt, decimals)) # ", decimals:" #Nat.toText(Nat8.toNat(decimals)) # ", fee:" #Nat.toText(fee));
                                    };
                                };
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"verifyTransferIcp\" mismatches config type");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
            case (#claimStakingRewardNft(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {
                        switch (configs.actionPlugin) {
                            case (? #claimStakingRewardNft(actionPluginConfig)) {

                                let callerText = Principal.toText(caller);

                                let stakes = await stakingHub.getUserStakes(callerText);

                                var foundStake : ?TStaking.Stake = null;

                                label stakesLoop for (stake in stakes.vals()) {
                                    if (stake.canister_id == actionPluginConfig.canister) {
                                        foundStake := ?stake;
                                        break stakesLoop;
                                    };
                                };

                                switch (foundStake) {
                                    case (?selectedStakeData) {
                                        if (selectedStakeData.amount < actionPluginConfig.requiredAmount) return #err("stake of id: \"" #actionPluginConfig.canister # "\" doesnt meet amount requirement");
                                        //
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs, null);
                                    };
                                    case (_) {
                                        return #err("nft stake of id: \"" #actionPluginConfig.canister # "\" could not be found");
                                    };
                                };
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
            case (#claimStakingRewardIcp(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {
                        switch (configs.actionPlugin) {
                            case (? #claimStakingRewardIcp(actionPluginConfig)) {

                                let callerText = Principal.toText(caller);

                                let stakes = await stakingHub.getUserStakes(callerText);

                                var foundStake : ?TStaking.Stake = null;

                                label stakesLoop for (stake in stakes.vals()) {
                                    if (stake.canister_id == ENV.Ledger) {
                                        foundStake := ?stake;
                                        break stakesLoop;
                                    };
                                };

                                switch (foundStake) {
                                    case (?selectedStakeData) {

                                        let decimals = await tokenDecimal_(ENV.Ledger);

                                        if (selectedStakeData.amount < Utils.convertToBaseUnit(actionPluginConfig.requiredAmount, decimals)) return #err("icp stake doesnt meet amount requirement");
                                        //
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs, null);
                                    };
                                    case (_) {
                                        return #err("icp stake could not be found");
                                    };
                                };
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
            case (#claimStakingRewardIcrc(arg)) {
                var configType = getSpecificAction_(arg.actionId);

                switch (configType) {
                    case (?configs) {
                        switch (configs.actionPlugin) {
                            case (? #claimStakingRewardIcrc(actionPluginConfig)) {

                                let callerText = Principal.toText(caller);

                                let stakes = await stakingHub.getUserStakes(callerText);

                                var foundStake : ?TStaking.Stake = null;

                                label stakesLoop for (stake in stakes.vals()) {
                                    if (stake.canister_id == actionPluginConfig.canister) {
                                        foundStake := ?stake;
                                        break stakesLoop;
                                    };
                                };

                                switch (foundStake) {
                                    case (?selectedStakeData) {

                                        let decimals = await tokenDecimal_(actionPluginConfig.canister);

                                        if (selectedStakeData.amount < Utils.convertToBaseUnit(actionPluginConfig.requiredAmount, decimals)) return #err("stake of id: \"" #actionPluginConfig.canister # "\" doesnt meet amount requirement");
                                        //
                                        return await handleOutcomes_(Principal.toText(caller), arg.actionId, configs, null);
                                    };
                                    case (_) {
                                        return #err("icrc stake of id: \"" #actionPluginConfig.canister # "\" could not be found");
                                    };
                                };
                            };
                            case (_) {
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case (_) {
                        return #err("Config of id: \"" #arg.actionId # "\" could not be found");
                    };
                };
            };
        };
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
        for(i in (await world.exportConfigs()).vals()) {
            configs.add({
                cid = i.cid;
                fields = Map.fromIter(i.fields.vals(), thash);
            });
        };
        return #ok("imported");
    };
    public shared ({ caller }) func importAllActionsOfWorld(ofWorldId : Text) : async (Result.Result<Text, Text>) {
        assert (caller == owner);
        let world = actor (ofWorldId) : actor {
            exportActions : shared () -> async ([TAction.Action]);
        };
        action := Buffer.fromArray((await world.exportActions()));
        return #ok("imported");
    };

    public shared ({ caller }) func withdrawIcpFromPaymentHub() : async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>) {
        assert (caller == owner);
        let paymentHub = actor (ENV.PaymentHubCanisterId) : actor {
            withdrawIcp : () -> async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>);
        };
        await paymentHub.withdrawIcp();
    };

    public shared ({ caller }) func withdrawIcrcFromPaymentHub(tokenCanisterId : Text) : async (Result.Result<ICRC.Result, { #TxErr : ICRC.TransferError; #Err : Text }>) {
        assert (caller == owner);
        let paymentHub = actor (ENV.PaymentHubCanisterId) : actor {
            withdrawIcrc : (Text) -> async (Result.Result<ICRC.Result, { #TxErr : ICRC.TransferError; #Err : Text }>);
        };
        await paymentHub.withdrawIcrc(tokenCanisterId);
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

};