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

// import IcWebSocketCdk "mo:ic-websocket-cdk";
// import IcWebSocketCdkState "mo:ic-websocket-cdk/State";
// import IcWebSocketCdkTypes "mo:ic-websocket-cdk/Types";

import V1TGlobal "../migrations/v1.global.types";
import V1TEntity "../migrations/v1.entity.types";
import V1TAction "../migrations/v1.action.types";
import V2TEntity "../migrations/v2.entity.types";
import V2TAction "../migrations/v2.action.types";

actor class WorldTemplate(owner : Principal) = this {

  //# FIELDS
  //private let owner : Principal = Principal.fromText("wj7by-qfwwz-zulus-l3aye-h2cux-emwsr-c4sdc-hvq7r-mh7oa-ivuhp-3ae");
  private func WorldId() : Principal = Principal.fromActor(this);

  private stable var processActionCount : Nat = 0;
  private stable var tokensDecimals : Trie.Trie<Text, Nat8> = Trie.empty(); //token_canister_id -> decimals
  private stable var tokensFees : Trie.Trie<Text, Nat> = Trie.empty(); //token_canister_id -> fees
  private stable var totalNftCount : Trie.Trie<Text, Nat32> = Trie.empty();
  private stable var userPrincipalToUserNode : Trie.Trie<Text, Text> = Trie.empty();

  //stable memory
  private stable var _owner : Text = Principal.toText(owner);
  private stable var _admins : [Text] = [Principal.toText(owner)];
  private stable var _devWorldCanisterId : Text = "";

  //Configs
  // empty stable memory used for migration - (used in preupgrade currently)
  private stable var v1configsStorage : Trie.Trie<Text, V1TEntity.Config> = Trie.empty();
  private stable var v1actionsStorage : Trie.Trie<Text, V1TAction.Action> = Trie.empty();

  // empty stable memory used for migration - (for future migration)
  private stable var v2configsStorage : Trie.Trie<Text, V2TEntity.Config> = Trie.empty();
  private stable var v2actionsStorage : Trie.Trie<Text, V2TAction.Action> = Trie.empty();

  // active data of stable memory
  private stable var configsStorage : Trie.Trie<Text, TEntity.Config> = Trie.empty();
  private stable var actionsStorage : Trie.Trie<Text, TAction.Action> = Trie.empty();

  private var randomGeneratorGacha = RandomExt.RandomLCG();

  private stable var indexedKeyCount = 0;

  private var seedMod : ?Nat = null;

  let { ihash; nhash; thash; phash; calcHash } = Map;

  let worldHub : WorldHub = actor (ENV.WorldHubCanisterId);
  let ICP_Ledger : ICP.Self = actor (ENV.IcpLedgerCanisterId);
  let BOOM_Ledger : ICRC.Self = actor (ENV.BoomLedgerCanisterId);

  //# INTERFACES
  type UserNode = actor {
    createEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId, fields : [TGlobal.Field]) -> async (Result.Result<Text, Text>);
    editEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId, fields : [TGlobal.Field]) -> async (Result.Result<Text, Text>);
    deleteActionState : shared (uid : TGlobal.userId, wid : TGlobal.worldId, aid : TGlobal.actionId) -> async (Result.Result<Text, Text>);
    deleteEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId) -> async (Result.Result<Text, Text>);
    applyOutcomes : shared (uid : TGlobal.userId, actionState : TAction.ActionState, outcomes : [TAction.ActionOutcomeOption]) -> async (Result.Result<(), Text>);
    getAllUserEntities : shared (uid : TGlobal.userId, wid : TGlobal.worldId, page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
    getAllUserEntitiesComposite : composite query (uid : TGlobal.userId, wid : TGlobal.worldId, page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
    getAllUserActionStates : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TAction.ActionState], Text>);
    getAllUserActionStatesComposite : composite query (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TAction.ActionState], Text>);
    getActionState : query (uid : TGlobal.userId, wid : TGlobal.worldId, aid : TGlobal.actionId) -> async (?TAction.ActionState);
    getEntity : shared (uid : TGlobal.userId, wid : TGlobal.worldId, eid : TGlobal.entityId) -> async (TEntity.StableEntity);
    getAllUserEntitiesOfSpecificWorlds : shared (uid : TGlobal.userId, wids : [TGlobal.worldId], page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
    getAllUserEntitiesOfSpecificWorldsComposite : composite query (uid : TGlobal.userId, wids : [TGlobal.worldId], page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
    getUserActionHistory : query (uid : TGlobal.userId, wid : TGlobal.worldId) -> async ([TAction.ActionOutcomeHistory]);
    getUserActionHistoryComposite : composite query (uid : TGlobal.userId, wid : TGlobal.worldId) -> async ([TAction.ActionOutcomeHistory]);
    getAllUserActionHistoryOfSpecificWorlds : query (uid : TGlobal.userId, wids : [TGlobal.worldId], page : ?Nat) -> async ([TAction.ActionOutcomeHistory]);
    getAllUserActionHistoryOfSpecificWorldsComposite : composite query (uid : TGlobal.userId, wids : [TGlobal.worldId], page : ?Nat) -> async ([TAction.ActionOutcomeHistory]);
    deleteActionHistoryForUser : shared ({ uid : TGlobal.userId }) -> async ();
    deleteUserEntityFromWorldNode : shared ({ uid : TGlobal.userId }) -> async ();
    deleteUser : shared ({ uid : TGlobal.userId }) -> async ();
    getUserEntitiesFromWorldNodeComposite : composite query (uid : TGlobal.userId, wid : TGlobal.worldId, page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
    getUserEntitiesFromWorldNodeFilteredSortingComposite : composite query (uid : TGlobal.userId, wid : TGlobal.worldId, fieldName : Text, order : { #Ascending; #Descending }, page : ?Nat) -> async (Result.Result<[TEntity.StableEntity], Text>);
  };
  type WorldHub = actor {
    createNewUser : shared ({ user : Principal; requireEntireNode : Bool }) -> async (Result.Result<Text, Text>);
    getUserNodeCanisterId : shared (Text) -> async (Result.Result<Text, Text>);
    getUserNodeCanisterIdComposite : composite query (Text) -> async (Result.Result<Text, Text>);

    grantEntityPermission : shared (TEntity.EntityPermission) -> async ();
    removeEntityPermission : shared (TEntity.EntityPermission) -> async ();
    grantGlobalPermission : shared (TEntity.GlobalPermission) -> async ();
    removeGlobalPermission : shared (TEntity.GlobalPermission) -> async ();
    getAllNodeIds : shared () -> async ([Text]);
    getAllUserIds : shared () -> async ([Text]);
  };
  type NFT = actor {
    ext_mint : ([(EXT.AccountIdentifier, EXT.Metadata)]) -> async [EXT.TokenIndex];
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
    v2configsStorage := configsStorage;
    v2actionsStorage := actionsStorage;
  };
  system func postupgrade() {};

  private func worldPrincipalId() : Text {
    return Principal.toText(WorldId());
  };

  //# INTERNAL FUNCTIONS
  private func isDevWorldCanister_() : Bool {
    let currentWorldCanisterId = Principal.toText(WorldId());
    if (_devWorldCanisterId != "" and _devWorldCanisterId == currentWorldCanisterId) return true;
    return false;
  };

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
        let token : ICRC.Self = actor (tokenCanisterId);
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
        let token : ICRC.Self = actor (tokenCanisterId);
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
            var newUserNodeId = await worldHub.createNewUser({
              user = Principal.fromText(userPrincipalTxt);
              requireEntireNode = false;
            });
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

  public shared ({ caller }) func setDevWorldCanisterId(cid : Text) : async () {
    assert (caller == Principal.fromText("2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe"));
    _devWorldCanisterId := cid;
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

  public shared ({ caller }) func createTestQuestConfigs(args : [{ cid : Text; name : Text; description : Text; image_url : Text; quest_url : Text }]) : async (Result.Result<Text, Text>) {
    assert (isDevWorldCanister_());
    for (arg in args.vals()) {
      var fieldsBuffer = Buffer.Buffer<(Text, Text)>(0);
      fieldsBuffer.add(("name", arg.name));
      fieldsBuffer.add(("description", arg.description));
      fieldsBuffer.add(("image_url", arg.image_url));
      fieldsBuffer.add(("quest_url", arg.quest_url));
      let fields : Map.Map<Text, Text> = Map.fromIter(Iter.fromArray(Buffer.toArray(fieldsBuffer)), thash);
      configsStorage := Trie.put(
        configsStorage,
        Utils.keyT(arg.cid),
        Text.equal,
        {
          cid = arg.cid;
          fields = fields;
        },
      ).0;
    };
    return #ok("you have updated all the configs");
  };

  public shared ({ caller }) func createAction(config : TAction.Action) : async (Result.Result<Text, Text>) {
    assert (isAdmin_(caller) or caller == WorldId());
    let configExist = actionExist_(config.aid);

    actionsStorage := Trie.put(actionsStorage, Utils.keyT(config.aid), Text.equal, config).0;

    if (configExist) return #ok("you have overwriten the action");
    return #ok("you have created a new action");
  };

  public shared ({ caller }) func createTestQuestActions(arg : { game_world_canister_id : Text; actionId_1 : Text; actionId_2 : Text }) : async (Result.Result<Text, Text>) {
    assert (isDevWorldCanister_());
    // add Game Canister Id field in "games_world" config
    var configResult = getSpecificConfig_("games_world");
    switch configResult {
      case (?config) {
        var fieldsBuffer : Buffer.Buffer<(Text, Text)> = Buffer.fromArray(Map.toArray(config.fields));
        let fieldName : Text = "TEST WORLD " #Nat.toText(fieldsBuffer.size());
        fieldsBuffer.add((fieldName, arg.game_world_canister_id));
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
      };
      case _ return #err("could not find config, cid: games_world");
    };

    let newActionId_1 = arg.actionId_1;
    let newActionId_2 = arg.actionId_2;

    let ?_action_01 = getSpecificAction_("test_quest_01") else return #err("Test Quest 1 does not exist yet. Contact dev team.");
    let ?_action_02 = getSpecificAction_("test_quest_02") else return #err("Test Quest 2 does not exist yet. Contact dev team.");

    var new_action_01 = _action_01;
    var new_action_02 = _action_02;

    var newCallerAction_01 : ?TAction.SubAction = null;
    var newCallerAction_02 : ?TAction.SubAction = null;
    switch (new_action_01.callerAction) {
      case (?cAction) {
        switch (cAction.actionConstraint) {
          case (?cons) {
            switch (cons.timeConstraint) {
              case (?t_cons) {
                var _eid = "";
                var _updates : [TAction.UpdateEntityType] = [];
                switch (t_cons.actionHistory[0]) {
                  case (#updateEntity u) {
                    _eid := u.eid;
                    _updates := u.updates;
                  };
                  case _ {};
                };
                newCallerAction_01 := ?{
                  actionConstraint = ?{
                    timeConstraint = ?{
                      actionTimeInterval = t_cons.actionTimeInterval;
                      actionStartTimestamp = t_cons.actionStartTimestamp;
                      actionExpirationTimestamp = t_cons.actionExpirationTimestamp;
                      actionHistory = [
                        #updateEntity {
                          wid = ?arg.game_world_canister_id;
                          eid = _eid;
                          updates = _updates;
                        }
                      ];
                    };
                    entityConstraint = cons.entityConstraint;
                    icrcConstraint = cons.icrcConstraint;
                    nftConstraint = cons.nftConstraint;
                  };
                  actionResult = cAction.actionResult;
                };
              };
              case _ {};
            };
          };
          case _ {};
        };
      };
      case _ {};
    };

    new_action_01 := {
      aid = newActionId_1;
      callerAction = newCallerAction_01;
      targetAction = new_action_01.targetAction;
      worldAction = new_action_01.worldAction;
    };
    actionsStorage := Trie.put(actionsStorage, Utils.keyT(newActionId_1), Text.equal, new_action_01).0;

    switch (new_action_02.callerAction) {
      case (?cAction) {
        switch (cAction.actionConstraint) {
          case (?cons) {
            switch (cons.timeConstraint) {
              case (?t_cons) {
                var _eid = "";
                var _updates : [TAction.UpdateEntityType] = [];
                switch (t_cons.actionHistory[0]) {
                  case (#updateEntity u) {
                    _eid := u.eid;
                    _updates := u.updates;
                  };
                  case _ {};
                };
                newCallerAction_02 := ?{
                  actionConstraint = ?{
                    timeConstraint = ?{
                      actionTimeInterval = t_cons.actionTimeInterval;
                      actionStartTimestamp = t_cons.actionStartTimestamp;
                      actionExpirationTimestamp = t_cons.actionExpirationTimestamp;
                      actionHistory = [
                        #updateEntity {
                          wid = ?arg.game_world_canister_id;
                          eid = _eid;
                          updates = _updates;
                        }
                      ];
                    };
                    entityConstraint = cons.entityConstraint;
                    icrcConstraint = cons.icrcConstraint;
                    nftConstraint = cons.nftConstraint;
                  };
                  actionResult = cAction.actionResult;
                };
              };
              case _ {};
            };
          };
          case _ {};
        };
      };
      case _ {};
    };

    new_action_02 := {
      aid = newActionId_2;
      callerAction = newCallerAction_02;
      targetAction = new_action_02.targetAction;
      worldAction = new_action_02.worldAction;
    };
    actionsStorage := Trie.put(actionsStorage, Utils.keyT(newActionId_2), Text.equal, new_action_02).0;
    return #ok("You have created two actions : " #newActionId_1 # " and " #newActionId_2);
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
    return #ok();
  };

  public shared ({ caller }) func deleteActionStateForUser(args : { aid : Text; uid : Text }) : async (Result.Result<(), (Text)>) {
    assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId());

    switch ((Trie.find(userPrincipalToUserNode, Utils.keyT(args.uid), Text.equal))) {
      case (?nodeId) {
        let userNode : UserNode = actor (nodeId);
        var deleteActionStateResult = await userNode.deleteActionState(args.uid, worldPrincipalId(), args.aid);
        switch (deleteActionStateResult) {
          case (#ok _) {};
          case (#err errMsg) {
            return #err(errMsg);
          };
        };
      };
      case _ {
        return #err("Usernode doesn't exist!");
      };
    };
    return #ok();
  };

  public shared ({ caller }) func deleteTestQuestActionStateForUser(args : { aid : Text }) : async (Result.Result<(), (Text)>) {
    assert (isDevWorldCanister_());
    switch ((Trie.find(userPrincipalToUserNode, Utils.keyT(Principal.toText(caller)), Text.equal))) {
      case (?nodeId) {
        let userNode : UserNode = actor (nodeId);
        var deleteActionStateResult = await userNode.deleteActionState(Principal.toText(caller), worldPrincipalId(), args.aid);
        switch (deleteActionStateResult) {
          case (#ok _) {};
          case (#err errMsg) {
            return #err(errMsg);
          };
        };
      };
      case _ {
        return #err("Usernode doesn't exist!");
      };
    };
    return #ok();
  };

  public shared ({ caller }) func deleteActionStateForAllUsers(args : { aid : Text }) : async (Result.Result<(), ()>) {
    // assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId());

    for ((uid, nodeId) in Trie.iter(userPrincipalToUserNode)) {
      let userNode : UserNode = actor (nodeId);

      ignore userNode.deleteActionState(uid, worldPrincipalId(), args.aid);
    };

    return #ok();
  };

  public shared ({ caller }) func deleteUser(args : { uid : TGlobal.userId }) : async () {
    assert (isAdmin_(caller));
    switch ((Trie.find(userPrincipalToUserNode, Utils.keyT(args.uid), Text.equal))) {
      case (?nodeId) {
        let userNode : UserNode = actor (nodeId);
        await userNode.deleteUser(args);
      };
      case _ {};
    };
    switch (await getUserNode_(worldPrincipalId())) {
      case (#ok(worldNodeId)) {
        let worldNode : UserNode = actor (worldNodeId);
        await worldNode.deleteUserEntityFromWorldNode(args);
      };
      case (#err(errMsg)) {};
    };
    ignore await processActionAwait({
      actionId = "delete_profile";
      fields = [];
    });
    return ();
  };

  //# USER DATA
  //Get Actions
  public composite query func getAllUserActionStatesComposite(args : { uid : Text }) : async (Result.Result<[TAction.ActionState], Text>) {
    switch (await worldHub.getUserNodeCanisterIdComposite(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return await userNode.getAllUserActionStatesComposite(args.uid, worldPrincipalId());
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public func getAllUserActionStates(args : { uid : Text }) : async (Result.Result<[TAction.ActionState], Text>) {

    switch (await getUserNode_(args.uid)) {
      case (#ok(userNodeId)) {

        let userNode : UserNode = actor (userNodeId);

        return await userNode.getAllUserActionStates(args.uid, worldPrincipalId());
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
        return await userNode.getAllUserEntities(args.uid, worldPrincipalId(), args.page);
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public composite query func getAllUserEntitiesComposite(args : { uid : Text; page : ?Nat }) : async (Result.Result<[TEntity.StableEntity], Text>) {
    switch (await worldHub.getUserNodeCanisterIdComposite(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return await userNode.getAllUserEntitiesComposite(args.uid, worldPrincipalId(), args.page);
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public composite query func getUserEntitiesFromWorldNodeComposite(args : { uid : Text; page : ?Nat }) : async (Result.Result<[TEntity.StableEntity], Text>) {
    switch (await worldHub.getUserNodeCanisterIdComposite(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return await userNode.getUserEntitiesFromWorldNodeComposite(args.uid, worldPrincipalId(), args.page);
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public composite query func getUserEntitiesFromWorldNodeFilteredSortingComposite(args : { uid : Text; fieldName : Text; order : { #Ascending; #Descending }; page : ?Nat }) : async (Result.Result<[TEntity.StableEntity], Text>) {
    switch (await worldHub.getUserNodeCanisterIdComposite(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return await userNode.getUserEntitiesFromWorldNodeFilteredSortingComposite(args.uid, worldPrincipalId(), args.fieldName, args.order, args.page);
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public func getActionHistory(args : { uid : TGlobal.userId }) : async (Result.Result<[TAction.ActionOutcomeHistory], Text>) {
    switch (await getUserNode_(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return #ok(await userNode.getUserActionHistory(args.uid, worldPrincipalId()));
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public composite query func getActionHistoryComposite(args : { uid : TGlobal.userId }) : async (Result.Result<[TAction.ActionOutcomeHistory], Text>) {
    switch (await worldHub.getUserNodeCanisterIdComposite(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return #ok(await userNode.getUserActionHistoryComposite(args.uid, worldPrincipalId()));
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
    assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId());
    switch (await getUserNode_(entitySchema.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return await userNode.createEntity(entitySchema.uid, worldPrincipalId(), entitySchema.eid, entitySchema.fields);
      };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };
  };

  public shared ({ caller }) func createEntityForAllUsers(args : { eid : TGlobal.entityId; fields : [TGlobal.Field] }) : async (Result.Result<Text, Text>) {
    assert (isAdmin_(caller));
    let nodeIds : [Text] = await worldHub.getAllNodeIds();
    var res = Buffer.Buffer<async (Result.Result<Text, Text>)>(0);
    var b = Buffer.Buffer<(Result.Result<Text, Text>)>(0);
    for (id in nodeIds.vals()) {
      let userNode = actor (id) : actor {
        createEntityForAllUsers : shared (TGlobal.worldId, TGlobal.entityId, [TGlobal.Field]) -> async (Result.Result<Text, Text>);
      };
      ignore userNode.createEntityForAllUsers(worldPrincipalId(), args.eid, args.fields);
    };
    return #ok(":)");
  };

  public shared ({ caller }) func deleteEntity(args : { uid : Text; eid : Text }) : async (Result.Result<Text, Text>) {
    assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId());
    switch (await getUserNode_(args.uid)) {
      case (#ok(userNodeId)) {
        let userNode : UserNode = actor (userNodeId);
        return await userNode.deleteEntity(args.uid, worldPrincipalId(), args.eid);
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

        return await userNode.editEntity(entitySchema.uid, worldPrincipalId(), entitySchema.eid, entitySchema.fields);
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
        let entities = await userNode.getEntity(arg.userId, worldPrincipalId(), arg.entityId);
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
      memo = null;
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
            let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

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
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                case (_) {

                  if (update.fieldName != _fieldName) {
                    refinedUpdateEntityTypes.add(
                      #setNumber {
                        fieldName = _fieldName;
                        fieldValue = update.fieldValue;
                      }
                    );
                    continue updateTypes;
                  };
                };
              };

            };
            case (#decrementNumber update) {

              var _fieldName = update.fieldName;
              if (Text.contains(_fieldName, #text "$caller")) {
                _fieldName := caller;
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                case (_) {

                  if (update.fieldName != _fieldName) {
                    refinedUpdateEntityTypes.add(
                      #decrementNumber {
                        fieldName = _fieldName;
                        fieldValue = update.fieldValue;
                      }
                    );
                    continue updateTypes;
                  };
                };
              };

            };
            case (#incrementNumber update) {

              var _fieldName = update.fieldName;
              if (Text.contains(_fieldName, #text "$caller")) {
                _fieldName := caller;
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                case (_) {

                  if (update.fieldName != _fieldName) {
                    refinedUpdateEntityTypes.add(
                      #incrementNumber {
                        fieldName = _fieldName;
                        fieldValue = update.fieldValue;
                      }
                    );
                    continue updateTypes;
                  };
                };
              };

            };
            case (#renewTimestamp update) {

              var _fieldName = update.fieldName;
              if (Text.contains(_fieldName, #text "$caller")) {
                _fieldName := caller;
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                case (_) {

                  if (update.fieldName != _fieldName) {
                    refinedUpdateEntityTypes.add(
                      #renewTimestamp {
                        fieldName = _fieldName;
                        fieldValue = update.fieldValue;
                      }
                    );
                    continue updateTypes;
                  };
                };
              };
            };
            case (#setText update) {

              var _fieldName = update.fieldName;
              if (Text.contains(_fieldName, #text "$caller")) {
                _fieldName := caller;
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                  let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

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
              } else {

                if (update.fieldName != _fieldName) {
                  refinedUpdateEntityTypes.add(
                    #setText {
                      fieldName = _fieldName;
                      fieldValue = update.fieldValue;
                    }
                  );
                  continue updateTypes;
                };
              };
            };
            case (#addToList update) {

              var _fieldName = update.fieldName;
              if (Text.contains(_fieldName, #text "$caller")) {
                _fieldName := caller;
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                  let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

                  switch (getActionArgByFieldName_(argFieldName, actionFields)) {
                    case (#ok(fieldValue)) {

                      refinedUpdateEntityTypes.add(
                        #addToList {
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
              } else {

                if (update.fieldName != _fieldName) {
                  refinedUpdateEntityTypes.add(
                    #addToList {
                      fieldName = _fieldName;
                      value = update.value;
                    }
                  );
                  continue updateTypes;
                };
              };
            };
            case (#removeFromList update) {

              var _fieldName = update.fieldName;
              if (Text.contains(_fieldName, #text "$caller")) {
                _fieldName := caller;
              } else if (Text.contains(_fieldName, #text "$target")) _fieldName := target;

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
                  let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

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
              } else {

                if (update.fieldName != _fieldName) {
                  refinedUpdateEntityTypes.add(
                    #removeFromList {
                      fieldName = _fieldName;
                      value = update.value;
                    }
                  );
                  continue updateTypes;
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
                let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

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
                    let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

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
                    let argFieldName = Text.trimEnd(variableFieldNameElements[1], #char '}');

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

  private stable var _icp_blocks : Trie.Trie<Text, Text> = Trie.empty(); // Block_index -> ""
  private stable var _icrc_blocks : Trie.Trie<Text, Trie.Trie<Text, Text>> = Trie.empty(); // token_canister_id -> [Block_index -> ""]
  private stable var _nft_txs : Trie.Trie<Text, Trie.Trie<Text, EXT.TokenIndex>> = Trie.empty(); // nft_canister_id -> [TxId, TokenIndex]

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
          case (#Transfer { to; fee; from; amount; spender }) {
            if (Hex.encode(Blob.toArray(to)) == toAccountId and Hex.encode(Blob.toArray(from)) == fromAccountId and amount == amt) {
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
          case (#Approve _) {
            return #err("Approve tx!");
          };
        };
      };
      case _ {
        return #err("invalid tx!");
      };
    };
  };

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

  private func validateEntityConstraints_(callerPrincipalId : Text, entities : [TEntity.StableEntity], entityConstraints : [TConstraints.EntityConstraint]) : (Result.Result<(), Text>) {

    for (e in entityConstraints.vals()) {

      var wid = Option.get(e.wid, worldPrincipalId());

      switch (e.entityConstraintType) {
        case (#greaterThanNumber val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_float = Utils.textToFloat(currentVal);

              if (current_val_in_float <= val.value) {
                return #err("Constraint error, type: greaterThanNumber. Entity field : \"" #val.fieldName # "\" is less than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
              };

            };
            case _ {
              return #err(("Constraint error, type: greaterThanNumber. You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#lessThanNumber val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_float = Utils.textToFloat(currentVal);

              if (current_val_in_float >= val.value) {
                return #err("Constraint error, type: lessThanNumber. entity field : \"" #val.fieldName # "\"is greater than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
              };

            };
            case _ {
              //We are not longer returning false if entity or field doesnt exist
              //return #err(("You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#equalToNumber val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_float = Utils.textToFloat(currentVal);

              if (val.equal) {
                if (current_val_in_float != val.value) return #err("Constraint error, type: equalToNumber. Entity field : \"" #val.fieldName # "\" is not equal to " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
              } else {
                if (current_val_in_float == val.value) return #err("Constraint error, type: equalToNumber. Entity field : \"" #val.fieldName # "\" is equal to " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
              };

            };
            case _ {
              if (val.equal) return #err(("Constraint error, type: equalToNumber. You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#equalToText val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              if (val.equal) {
                if (currentVal != val.value) return #err("Constraint error, type: equalToText. Entity field : \"" #val.fieldName # "\" is not equal to " #val.value # ", therefore, does not pass EntityConstraints");
              } else {
                if (currentVal == val.value) return #err("Constraint error, type: equalToText. Entity field : \"" #val.fieldName # "\" is equal to " #val.value # ", therefore, does not pass EntityConstraints");
              };

            };
            case _ {
              if (val.equal) return #err(("Constraint error, type: EqualToText. You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#containsText val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              if (val.contains) {

                if (Text.contains(currentVal, #text(val.value)) == false) {
                  return #err("Constraint error, type: containsText. Entity field : \"" #val.fieldName # "\" doesn't contain " # (val.value) # ", therefore, does not pass EntityConstraints. current value: " #currentVal);
                };
              } else {

                if (Text.contains(currentVal, #text(val.value))) {
                  return #err("Constraint error, type: containsText. Entity field : \"" #val.fieldName # "\" contains " # (val.value) # ", therefore, does not pass EntityConstraints. current value: " #currentVal);
                };
              };

            };
            case _ {
              if (val.contains) return #err(("Constraint error, type: containsText. You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#greaterThanNowTimestamp val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_Nat = Utils.textToNat(currentVal);
              if (current_val_in_Nat < Time.now()) {
                return #err("Constraint error, type: greaterThanNowTimestamp. Entity field : \"" #val.fieldName # "\" Time.Now is greater than current value, therefore, does not pass EntityConstraints, " #Nat.toText(current_val_in_Nat) # " < " #Int.toText(Time.now()));
              };

            };
            case _ {
              return #err(("Constraint error, type: greaterThanNowTimestamp. You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#lessThanNowTimestamp val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_Nat = Utils.textToNat(currentVal);
              if (current_val_in_Nat > Time.now()) {
                return #err("Constraint error, type: lessThanNowTimestamp. Entity field : \"" #val.fieldName # "\" Time.Now is lesser than current value, therefore, does not pass EntityConstraints, " #Nat.toText(current_val_in_Nat) # " > " #Int.toText(Time.now()));
              };

            };
            case _ {
              //We are not longer returning false if entity or field doesnt exist
              //return #err(("You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#greaterThanEqualToNumber val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_float = Utils.textToFloat(currentVal);

              if (current_val_in_float < val.value) {
                return #err("Constraint error, type: greaterThanEqualToNumber. Entity field : \"" #val.fieldName # "\" is less than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
              };

            };
            case _ {
              return #err(("Constraint error, type: greaterThanEqualToNumber. You don't have entity of id: \"" #e.eid # "\" or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#lessThanEqualToNumber val) {

          switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
            case (?currentVal) {

              let current_val_in_float = Utils.textToFloat(currentVal);

              if (current_val_in_float > val.value) {
                return #err("Constraint error, type: lessThanEqualToNumber. Entity field : \"" #val.fieldName # "\" is greater than " #Float.toText(val.value) # ", therefore, does not pass EntityConstraints");
              };

            };
            case _ {
              //We are not longer returning false if entity or field doesnt exist
              // return #err(("You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
            };
          };

        };
        case (#existField val) {

          switch (getEntity_(entities, wid, e.eid)) {
            case (?entity) {

              switch (getEntityField_(entities, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  if (val.value == false) return #err(("Constraint error, type: existField. Field with fieldName : \"" #val.fieldName # "\" exist, therefore, doens't match entity constraints of \'exist field false\''."));
                };
                case _ {
                  if (val.value) return #err(("Constraint error, type: existField. Field with fieldName : \"" #val.fieldName # "\" doesn't exist, therefore, doens't match entity constraints of \'exist field true\''."));
                };
              };

            };
            case _ {
              if (val.value) return #err(("Constraint error, type: existField. Entity of id : " #e.eid # " doesn't exist, therefore, it is required to be able to check if field of id: \"" #val.fieldName # "\" exists"));
            };
          };
        };
        case (#exist val) {
          var _eid = e.eid;
          if (_eid == "$caller") {
            _eid := callerPrincipalId;
          };
          switch (getEntity_(entities, wid, _eid)) {
            case (?entity) {
              if (val.value == false) return #err(("Constraint error, type: exist. Entity of id : " #_eid # " exist, therefore, doens't match entity constraints of \'exist false\''."));
            };
            case _ {
              if (val.value) return #err(("Constraint error, type: exist. Entity of id : " #_eid # " doesn't exist, therefore, doens't match entity constraints of \'exist true\''."));
            };
          };
        };
      };

    };

    return #ok();
  };

  private func validateConstraints_(entities : [TEntity.StableEntity], actionHistory : [TAction.ActionOutcomeHistory], uid : TGlobal.userId, aid : TGlobal.actionId, actionConstraint : ?TAction.ActionConstraint, currentUserActionState : ?TAction.ActionState) : async (Result.Result<TAction.ActionState, Text>) {

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
        var last_action_time : Nat = _intervalStartTs; // For history outcome validation
        switch (constraints.timeConstraint) {
          case (?t) {
            //Start Time
            switch (t.actionStartTimestamp) {
              case (?actionStartTimestamp) {
                if (actionStartTimestamp > Time.now()) return #err("action is not yet enabled!");
              };
              case _ {};
            };
            //Expiration
            switch (t.actionExpirationTimestamp) {
              case (?actionExpirationTimestamp) {
                if (actionExpirationTimestamp < Time.now()) return #err("action is expired!");
              };
              case _ {};
            };
            //Time Interval
            switch (t.actionTimeInterval) {
              case (?actionTimeInterval) {
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

                if (last_action_time == 0 and (Int.abs(Time.now()) > actionTimeInterval.intervalDuration)) {
                  last_action_time := (Int.abs(Time.now()) - actionTimeInterval.intervalDuration);
                };
              };
              case _ {};
            };

            let actionHistoryConstraint = t.actionHistory;

            // ACTION HISTORY CONSTRAINTS
            var history_outcomes = actionHistory;

            for (expected in actionHistoryConstraint.vals()) {
              switch (expected) {
                case (#updateEntity outcome) {
                  let _entityId = outcome.eid;
                  let _worldId = Option.get(outcome.wid, worldPrincipalId());
                  var _fieldName = "";
                  for (update in outcome.updates.vals()) {
                    switch (update) {
                      case (#incrementNumber iv) {
                        _fieldName := iv.fieldName;
                        // Query history outcomes and validate
                        var updated_value : Float = 0.0;
                        for (i in history_outcomes.vals()) {
                          if (i.appliedAt >= last_action_time and _worldId == i.wid) {
                            switch (i.option) {
                              case (#updateEntity history_outcome) {
                                if (history_outcome.eid == _entityId) {
                                  for (history_update in history_outcome.updates.vals()) {
                                    switch (history_update) {
                                      case (#incrementNumber val) {
                                        if (val.fieldName == _fieldName) {
                                          switch (val.fieldValue) {
                                            case (#number n) {
                                              updated_value := updated_value + n;
                                            };
                                            case (#formula _) {};
                                          };
                                        };
                                      };
                                      case _ {};
                                    };
                                  };
                                };
                              };
                              case _ {};
                            };
                          };
                        };
                        // check
                        switch (iv.fieldValue) {
                          case (#number n) {
                            if (n > updated_value) {
                              return #err("actionHistory constraints failed to pass validation");
                            };
                          };
                          case _ {};
                        };
                      };
                      case _ {};
                    };
                  };
                };
                case _ {}; // other action history will be handled later
              };
            };
          };
          case _ {};
        };

        //ENTITY CONSTRAINTS
        switch (validateEntityConstraints_(uid, entities, constraints.entityConstraint)) {
          case (#err(errMsg)) return #err(errMsg);
          case _ {};
        };

        //ICRC CONSTRAINTS
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

            // If Ledger is ICP
            if (tx.canister == ENV.IcpLedgerCanisterId) {
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
              var toAccountId : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(tx.toPrincipal, null);
              var amt : Nat64 = Int64.toNat64(Float.toInt64(tx.amount * 100000000.0));
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
            } else {
              // Otherwise handle ICRC Ledger
              let ICRC_Ledger : ICRC.Self = actor (tx.canister);
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
        };

        //NFT CONSTRAINTS
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
    return #err("Requires action argument of fieldName: \"" #fieldName # "\"");
  };

  //
  private type SubAction = {
    sourcePrincipalId : Text;
    sourceActionConstraint : ?TAction.ActionConstraint;
    sourceOutcomes : [TAction.ActionOutcomeOption];
  };

  public shared ({ caller }) func processActionAwait(actionArg : TAction.ActionArg) : async (Result.Result<TAction.ActionReturn, Text>) {

    updateDauCount(Principal.toText(caller)); // Update DAU Count

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

    var worldAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };
    var callerAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };
    var targetAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };

    //world
    var hasSubActionWorld = false;
    //caller
    var hasSubActionCaller = false;
    //target
    var targetPrincipalId : Text = "";
    var hasSubActionTarget = false;

    var subActions = Buffer.Buffer<SubAction>(0);

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
          case (?_worldAction) {
            worldAction := _worldAction;
            hasSubActionWorld := true;
          };
          case (_) {};
        };
      };
      case (_) {
        changeActionLockState_(callerPrincipalId, actionId, false);
        debugLog("The '" #actionId # "' action failed to be executed, because it doesn't exist.");
        return #err("The '" #actionId # "' action failed to be executed, because it doesn't exist");
      };
    };

    //Generate Outcomes
    var worldOutcomes : [TAction.ActionOutcomeOption] = [];
    var callerOutcomes : [TAction.ActionOutcomeOption] = [];
    var targetOutcomes : [TAction.ActionOutcomeOption] = [];

    let generateActionResultOutcomesWorldHandler = generateActionResultOutcomes_(worldAction.actionResult);
    let generateActionResultOutcomesCallerandler = generateActionResultOutcomes_(callerAction.actionResult);
    let generateActionResultOutcomesTargetHandler = generateActionResultOutcomes_(targetAction.actionResult);

    worldOutcomes := await generateActionResultOutcomesWorldHandler;
    callerOutcomes := await generateActionResultOutcomesCallerandler;
    targetOutcomes := await generateActionResultOutcomesTargetHandler;

    //
    if (hasSubActionWorld) {
      subActions.add({
        sourcePrincipalId = worldPrincipalId();
        sourceActionConstraint = worldAction.actionConstraint;
        sourceOutcomes = worldOutcomes;
      });

    };
    if (hasSubActionCaller) {
      subActions.add({
        sourcePrincipalId = callerPrincipalId;
        sourceActionConstraint = callerAction.actionConstraint;
        sourceOutcomes = callerOutcomes;
      });
    };
    if (hasSubActionTarget) {
      //TRY SETUP TARGET PRINCIPAL ID

      switch (getActionArgByFieldName_("target_principal_id", actionArg.fields)) {
        case (#ok(fieldValue)) {
          targetPrincipalId := fieldValue;
        };
        case (#err(errMsg)) {
          changeActionLockState_(callerPrincipalId, actionId, false);
          debugLog("The '" #actionId # "' action failed to be executed, because this is a compound action, thus requires as ActionArg.field a fieldName of 'target_principal_id' whose value is the target principal");
          return #err("The '" #actionId # "' action failed to be executed, because this is a compound action, thus requires as ActionArg.field a fieldName of 'target_principal_id' whose value is the target principal ");
        };
      };

      targetOutcomes := await generateActionResultOutcomes_(targetAction.actionResult);

      subActions.add({
        sourcePrincipalId = targetPrincipalId;
        sourceActionConstraint = targetAction.actionConstraint;
        sourceOutcomes = targetOutcomes;
      });
    };

    await processActionNewAwait_(callerPrincipalId, targetPrincipalId, actionId, actionArg.fields, Buffer.toArray(subActions));

    let outcomes = {
      callerPrincipalId = callerPrincipalId;
      targetPrincipalId = targetPrincipalId;
      worldPrincipalId = worldPrincipalId();
      callerOutcomes = callerOutcomes;
      targetOutcomes = targetOutcomes;
      worldOutcomes = worldOutcomes;
    };

    ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
    return #ok(outcomes);
  };

  public shared ({ caller }) func processAction(actionArg : TAction.ActionArg) : async (Result.Result<TAction.ActionReturn, Text>) {

    updateDauCount(Principal.toText(caller)); // Update DAU Count

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

    var worldAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };
    var callerAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };
    var targetAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };

    //world
    var hasSubActionWorld = false;
    //caller
    var hasSubActionCaller = false;
    //target
    var targetPrincipalId : Text = "";
    var hasSubActionTarget = false;

    var subActions = Buffer.Buffer<SubAction>(0);

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
          case (?_worldAction) {
            worldAction := _worldAction;
            hasSubActionWorld := true;
          };
          case (_) {};
        };
      };
      case (_) {
        changeActionLockState_(callerPrincipalId, actionId, false);
        debugLog("The '" #actionId # "' action failed to be executed, because it doesn't exist.");
        return #err("The '" #actionId # "' action failed to be executed, because it doesn't exist");
      };
    };

    //Generate Outcomes
    var worldOutcomes : [TAction.ActionOutcomeOption] = [];
    var callerOutcomes : [TAction.ActionOutcomeOption] = [];
    var targetOutcomes : [TAction.ActionOutcomeOption] = [];

    let generateActionResultOutcomesWorldHandler = generateActionResultOutcomes_(worldAction.actionResult);
    let generateActionResultOutcomesCallerandler = generateActionResultOutcomes_(callerAction.actionResult);
    let generateActionResultOutcomesTargetHandler = generateActionResultOutcomes_(targetAction.actionResult);

    worldOutcomes := await generateActionResultOutcomesWorldHandler;
    callerOutcomes := await generateActionResultOutcomesCallerandler;
    targetOutcomes := await generateActionResultOutcomesTargetHandler;

    //
    if (hasSubActionWorld) {
      subActions.add({
        sourcePrincipalId = worldPrincipalId();
        sourceActionConstraint = worldAction.actionConstraint;
        sourceOutcomes = worldOutcomes;
      });

    };
    if (hasSubActionCaller) {
      subActions.add({
        sourcePrincipalId = callerPrincipalId;
        sourceActionConstraint = callerAction.actionConstraint;
        sourceOutcomes = callerOutcomes;
      });
    };
    if (hasSubActionTarget) {
      //TRY SETUP TARGET PRINCIPAL ID

      switch (getActionArgByFieldName_("target_principal_id", actionArg.fields)) {
        case (#ok(fieldValue)) {
          targetPrincipalId := fieldValue;
        };
        case (#err(errMsg)) {
          changeActionLockState_(callerPrincipalId, actionId, false);
          debugLog("The '" #actionId # "' action failed to be executed, because this is a compound action, thus requires as ActionArg.field a fieldName of 'target_principal_id' whose value is the target principal");
          return #err("The '" #actionId # "' action failed to be executed, because this is a compound action, thus requires as ActionArg.field a fieldName of 'target_principal_id' whose value is the target principal ");
        };
      };

      targetOutcomes := await generateActionResultOutcomes_(targetAction.actionResult);

      subActions.add({
        sourcePrincipalId = targetPrincipalId;
        sourceActionConstraint = targetAction.actionConstraint;
        sourceOutcomes = targetOutcomes;
      });
    };

    ignore processActionNew_(callerPrincipalId, targetPrincipalId, actionId, actionArg.fields, Buffer.toArray(subActions));

    let outcomes = {
      callerPrincipalId = callerPrincipalId;
      targetPrincipalId = targetPrincipalId;
      worldPrincipalId = worldPrincipalId();
      callerOutcomes = callerOutcomes;
      targetOutcomes = targetOutcomes;
      worldOutcomes = worldOutcomes;
    };

    ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
    return #ok(outcomes);
  };

  public shared ({ caller }) func processActionForAllUsers(actionArg : TAction.ActionArg) : async () {
    assert (isAdmin_(caller));
    let userIds : [Text] = await worldHub.getAllUserIds();
    for (uid in userIds.vals()) {
      let actionId = actionArg.actionId;
      let callerPrincipalId = Principal.toText(caller);
      processActionCount += 1;
      var worldAction : TAction.SubAction = {
        actionConstraint = null;
        actionResult = { outcomes = [] };
      };
      var callerAction : TAction.SubAction = {
        actionConstraint = null;
        actionResult = { outcomes = [] };
      };
      var targetAction : TAction.SubAction = {
        actionConstraint = null;
        actionResult = { outcomes = [] };
      };

      //world
      var hasSubActionWorld = false;
      //caller
      var hasSubActionCaller = false;
      //target
      var targetPrincipalId : Text = "";
      var hasSubActionTarget = false;

      var subActions = Buffer.Buffer<SubAction>(0);

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
            case (?_worldAction) {
              worldAction := _worldAction;
              hasSubActionWorld := true;
            };
            case (_) {};
          };
        };
        case (_) {};
      };

      //Generate Outcomes
      var worldOutcomes : [TAction.ActionOutcomeOption] = [];
      var callerOutcomes : [TAction.ActionOutcomeOption] = [];
      var targetOutcomes : [TAction.ActionOutcomeOption] = [];

      let generateActionResultOutcomesWorldHandler = generateActionResultOutcomes_(worldAction.actionResult);
      let generateActionResultOutcomesCallerandler = generateActionResultOutcomes_(callerAction.actionResult);
      let generateActionResultOutcomesTargetHandler = generateActionResultOutcomes_(targetAction.actionResult);

      worldOutcomes := await generateActionResultOutcomesWorldHandler;
      callerOutcomes := await generateActionResultOutcomesCallerandler;
      targetOutcomes := await generateActionResultOutcomesTargetHandler;

      //
      if (hasSubActionWorld) {
        subActions.add({
          sourcePrincipalId = worldPrincipalId();
          sourceActionConstraint = worldAction.actionConstraint;
          sourceOutcomes = worldOutcomes;
        });

      };
      if (hasSubActionCaller) {
        subActions.add({
          sourcePrincipalId = callerPrincipalId;
          sourceActionConstraint = callerAction.actionConstraint;
          sourceOutcomes = callerOutcomes;
        });
      };
      if (hasSubActionTarget) {
        targetPrincipalId := uid;
        targetOutcomes := await generateActionResultOutcomes_(targetAction.actionResult);
        subActions.add({
          sourcePrincipalId = targetPrincipalId;
          sourceActionConstraint = targetAction.actionConstraint;
          sourceOutcomes = targetOutcomes;
        });
      };
      ignore processActionNew_(callerPrincipalId, targetPrincipalId, actionId, actionArg.fields, Buffer.toArray(subActions));
      let outcomes = {
        callerPrincipalId = callerPrincipalId;
        targetPrincipalId = targetPrincipalId;
        worldPrincipalId = worldPrincipalId();
        callerOutcomes = callerOutcomes;
        targetOutcomes = targetOutcomes;
        worldOutcomes = worldOutcomes;
      };
      ignore tryBroadcastOutcomes_(callerPrincipalId, outcomes);
    };
  };

  //targetPrincipalId is optional, you can set it up as an empty string
  private func processActionNew_(callerPrincipalId : Text, targetPrincipalId : Text, actionId : Text, actionFields : [TGlobal.Field], subActions : [SubAction]) : async () {

    let worldPrincipalId_ = worldPrincipalId();

    var callerData : [TEntity.StableEntity] = [];
    var worldData : [TEntity.StableEntity] = [];
    var targetData : [TEntity.StableEntity] = [];

    var subActions_ : Trie.Trie<Text, { sourcePrincipalId : Text; sourceActionConstraint : ?TAction.ActionConstraint; sourceOutcomes : [TAction.ActionOutcomeOption]; worldsToFetchEntitiesFrom : [Text]; worldsToFetchActionHistoryFrom : [Text]; nodeId : Text; nodeIdTask : async Result.Result<Text, Text>; sourceNewActionState : TAction.ActionState; sourceData : [TEntity.StableEntity] }> = Trie.empty<Text, { sourcePrincipalId : Text; sourceActionConstraint : ?TAction.ActionConstraint; sourceOutcomes : [TAction.ActionOutcomeOption]; worldsToFetchEntitiesFrom : [Text]; worldsToFetchActionHistoryFrom : [Text]; nodeId : Text; nodeIdTask : async Result.Result<Text, Text>; sourceNewActionState : TAction.ActionState; sourceData : [TEntity.StableEntity] }>();

    var getActionStateTasks : Trie.Trie<Text, { actionStateTask : async ?TAction.ActionState; entitiesTask : async Result.Result<[TEntity.StableEntity], Text>; actionHistoryTask : async [TAction.ActionOutcomeHistory] }> = Trie.empty<Text, { actionStateTask : async ?TAction.ActionState; entitiesTask : async Result.Result<[TEntity.StableEntity], Text>; actionHistoryTask : async [TAction.ActionOutcomeHistory] }>();

    //Get all the worlds' to fetch entities from and store them in "subActionsTrie".
    //Fetch nodeId for each subaction's source.
    //Store the task of fetching each nodeId in "subActionsTrie".
    for (subAction in Iter.fromArray(subActions)) {

      var worldsToFetchEntitiesFrom : [Text] = [];
      var worldsToFetchActionHistoryFrom : [Text] = [];
      //GET WORLD IDS TO FETCH ENTITIE AND ACTION HISTORY FROM
      switch (subAction.sourceActionConstraint) {
        case (?constraints) {

          //Entity Action History World Ids
          var worldsToFetchActionHistoryFromBuffer = Buffer.Buffer<Text>(0);
          switch (constraints.timeConstraint) {
            case (?timeConstraint) {

              for (actionHistory in Iter.fromArray(timeConstraint.actionHistory)) {

                switch (actionHistory) {
                  case (#updateEntity entityActionHistory) {

                    let _wid = Option.get(entityActionHistory.wid, worldPrincipalId());
                    if (Buffer.contains(worldsToFetchActionHistoryFromBuffer, _wid, Text.equal) == false) worldsToFetchActionHistoryFromBuffer.add(_wid);

                  };
                  case _ {};
                };

              };

            };
            case _ {};
          };

          //Entity World Ids
          var worldsToFetchEntitiesFromBuffer = Buffer.Buffer<Text>(0);

          for (entityConstraint in Iter.fromArray(constraints.entityConstraint)) {
            let _wid = Option.get(entityConstraint.wid, worldPrincipalId());
            if (Buffer.contains(worldsToFetchEntitiesFromBuffer, _wid, Text.equal) == false) worldsToFetchEntitiesFromBuffer.add(_wid);
          };
          worldsToFetchActionHistoryFrom := Buffer.toArray(worldsToFetchActionHistoryFromBuffer);
          worldsToFetchEntitiesFrom := Buffer.toArray(worldsToFetchEntitiesFromBuffer);
        };
        case _ {};
      };

      var task = getUserNode_(subAction.sourcePrincipalId);

      var newTrie = {
        sourcePrincipalId = subAction.sourcePrincipalId;
        sourceActionConstraint = subAction.sourceActionConstraint;
        sourceOutcomes = subAction.sourceOutcomes;
        worldsToFetchEntitiesFrom = worldsToFetchEntitiesFrom;
        worldsToFetchActionHistoryFrom = worldsToFetchActionHistoryFrom;
        nodeId = "";
        nodeIdTask = task;
        sourceNewActionState = {
          actionId = "";
          intervalStartTs = 0;
          actionCount = 0;
        };
        sourceData : [TEntity.StableEntity] = [];
      };

      switch (Trie.find(subActions_, Utils.keyT(subAction.sourcePrincipalId), Text.equal)) {
        case (?tempStoredSubAction) {

          switch (tempStoredSubAction.sourceActionConstraint) {
            case (?storedConstraint) {

              switch (newTrie.sourceActionConstraint) {
                case (?constraint) {

                  newTrie := {
                    sourcePrincipalId = tempStoredSubAction.sourcePrincipalId;
                    sourceActionConstraint = ?{
                      timeConstraint = storedConstraint.timeConstraint;
                      entityConstraint = Array.append(storedConstraint.entityConstraint, constraint.entityConstraint);
                      icrcConstraint = Array.append(storedConstraint.icrcConstraint, constraint.icrcConstraint);
                      nftConstraint = Array.append(storedConstraint.nftConstraint, constraint.nftConstraint);
                    };
                    sourceOutcomes = Array.append(tempStoredSubAction.sourceOutcomes, newTrie.sourceOutcomes);
                    worldsToFetchEntitiesFrom = Array.append(tempStoredSubAction.worldsToFetchEntitiesFrom, newTrie.worldsToFetchEntitiesFrom);
                    worldsToFetchActionHistoryFrom = Array.append(tempStoredSubAction.worldsToFetchActionHistoryFrom, newTrie.worldsToFetchActionHistoryFrom);
                    nodeId = tempStoredSubAction.nodeId;
                    nodeIdTask = tempStoredSubAction.nodeIdTask;
                    sourceNewActionState = tempStoredSubAction.sourceNewActionState;
                    sourceData = tempStoredSubAction.sourceData;
                  };
                };
                case _ {

                  newTrie := {
                    sourcePrincipalId = tempStoredSubAction.sourcePrincipalId;
                    sourceActionConstraint = ?storedConstraint;
                    sourceOutcomes = Array.append(tempStoredSubAction.sourceOutcomes, newTrie.sourceOutcomes);
                    worldsToFetchEntitiesFrom = Array.append(tempStoredSubAction.worldsToFetchEntitiesFrom, newTrie.worldsToFetchEntitiesFrom);
                    worldsToFetchActionHistoryFrom = Array.append(tempStoredSubAction.worldsToFetchActionHistoryFrom, newTrie.worldsToFetchActionHistoryFrom);
                    nodeId = tempStoredSubAction.nodeId;
                    nodeIdTask = tempStoredSubAction.nodeIdTask;
                    sourceNewActionState = tempStoredSubAction.sourceNewActionState;
                    sourceData = tempStoredSubAction.sourceData;
                  };
                };
              };
            };
            case _ {

            };
          };
        };
        case _ {};
      };

      subActions_ := Trie.put(subActions_, Utils.keyT(subAction.sourcePrincipalId), Text.equal, newTrie).0;
    };

    //Await for nodeIds to be fetched.
    //Store nodeIds in "subActions_".
    //fetch action source's action state & entities,
    //and keep track of the  action state & entities tasks in "getActionStateTasks".
    for ((id, trie) in Trie.iter(subActions_)) {
      let sourcePrincipalId = id;

      let nodeTaskResult = await trie.nodeIdTask;

      var nodeId = "";

      switch (nodeTaskResult) {
        case (#ok(content)) { nodeId := content };
        case (#err(errMsg)) {
          debugLog("The '" #actionId # "' action failed because it could not get world node Id.\nExtra insight: " #errMsg);
          //UNLOCK ACTION
          changeActionLockState_(callerPrincipalId, actionId, false);
          return;
        };
      };

      var newTrie = {
        sourcePrincipalId = trie.sourcePrincipalId;
        sourceActionConstraint = trie.sourceActionConstraint;
        sourceOutcomes = trie.sourceOutcomes;
        worldsToFetchEntitiesFrom = trie.worldsToFetchEntitiesFrom;
        worldsToFetchActionHistoryFrom = trie.worldsToFetchActionHistoryFrom;
        //Store the NodeId
        nodeId = nodeId;
        nodeIdTask = trie.nodeIdTask;
        sourceNewActionState = {
          actionId = "";
          intervalStartTs = 0;
          actionCount = 0;
        };
        sourceData = [];
      };

      subActions_ := Trie.put(subActions_, Utils.keyT(sourcePrincipalId), Text.equal, newTrie).0;

      let sourceNode : UserNode = actor (nodeId);

      //Fetch Source's Action State
      let currentCallerActionStateResultHandler = sourceNode.getActionState(trie.sourcePrincipalId, worldPrincipalId(), actionId);
      //Fetch Source's Entities
      let sourceEntityResultHandler = sourceNode.getAllUserEntitiesOfSpecificWorlds(trie.sourcePrincipalId, trie.worldsToFetchEntitiesFrom, null);

      let sourceActionHistoryResultHandler = sourceNode.getAllUserActionHistoryOfSpecificWorlds(trie.sourcePrincipalId, trie.worldsToFetchActionHistoryFrom, null);

      getActionStateTasks := Trie.put(
        getActionStateTasks,
        Utils.keyT(trie.sourcePrincipalId),
        Text.equal,
        {
          actionStateTask = currentCallerActionStateResultHandler;
          entitiesTask = sourceEntityResultHandler;
          actionHistoryTask = sourceActionHistoryResultHandler;
        },
      ).0;
    };

    //Await for action state & entities tasks
    //Refine & validate constraints
    //Catch worldData, callerData, and optional targetData
    //Store new source's action state and data in "subActions_".
    for ((id, trie) in Trie.iter(getActionStateTasks)) {
      let sourcePrincipalId = id;

      let currentActionState = await trie.actionStateTask;

      let entitiesTaskResult = await trie.entitiesTask;

      let actionHistoryTaskResult = await trie.actionHistoryTask;

      var sourceData : [TEntity.StableEntity] = [];
      var sourceActionHistoryData : [TAction.ActionOutcomeHistory] = actionHistoryTaskResult;

      switch (entitiesTaskResult) {
        case (#ok data) sourceData := data;
        case (#err errMsg) {
          debugLog("The '" #actionId # "' action failed because it could not get source's entities\nSourceId: " #id # "\nExtra insight: " #errMsg);
          //UNLOCK ACTION
          changeActionLockState_(callerPrincipalId, actionId, false);
          return;
        };
      };

      //Catch world's data
      if (sourcePrincipalId == worldPrincipalId_) {
        worldData := sourceData;
      };
      //Catch caller's data
      if (sourcePrincipalId == callerPrincipalId) {
        callerData := sourceData;
      };
      //Catch target's data
      if (sourcePrincipalId == targetPrincipalId) {
        targetData := sourceData;
      };

      switch (Trie.find(subActions_, Utils.keyT(id), Text.equal)) {
        case (?subAction) {

          var sourceNewActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
          };

          switch (subAction.sourceActionConstraint) {
            case (?sc) {

              var sourceRefinedConstraints : ?TAction.ActionConstraint = ?{
                timeConstraint = null;
                containEntity = [];
                entityConstraint = [];
                icrcConstraint = [];
                nftConstraint = [];
              };

              //Refine Constraints
              let sourceRefinedConstraintsResult = refineConstraints_(subAction.sourceActionConstraint, callerPrincipalId, targetPrincipalId, actionFields);

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

              //Validate Constraints
              var sourceValidationResult = validateConstraints_(sourceData, sourceActionHistoryData, sourcePrincipalId, actionId, sourceRefinedConstraints, currentActionState);

              switch (await sourceValidationResult) {
                case (#ok(result)) {
                  sourceNewActionState := result;
                };
                case (#err(errMsg)) {
                  debugLog("The '" #actionId # "' action failed because it could not validate source action constraints\nExtra insight: " #errMsg);
                  //UNLOCK ACTION
                  changeActionLockState_(callerPrincipalId, actionId, false);
                  return;
                };
              };

            };
            case (_) {};
          };

          var newTrie = {
            sourcePrincipalId = subAction.sourcePrincipalId;
            sourceActionConstraint = subAction.sourceActionConstraint;
            sourceOutcomes = subAction.sourceOutcomes;
            worldsToFetchEntitiesFrom = subAction.worldsToFetchEntitiesFrom;
            worldsToFetchActionHistoryFrom = subAction.worldsToFetchActionHistoryFrom;
            nodeId = subAction.nodeId;
            nodeIdTask = subAction.nodeIdTask;
            //Store New Action State
            sourceNewActionState = sourceNewActionState;
            //Store Source's data
            sourceData = sourceData;
          };

          subActions_ := Trie.put(subActions_, Utils.keyT(sourcePrincipalId), Text.equal, newTrie).0;
        };
        case _ {

          debugLog("The '" #actionId # "' action failed because it could not find source id: " #id);
          //UNLOCK ACTION
          changeActionLockState_(callerPrincipalId, actionId, false);
          return;
        };
      };
    };

    //Refine outcomes
    label loop4 for ((id, trie) in Trie.iter(subActions_)) {

      if (trie.sourceOutcomes.size() == 0) continue loop4;

      let sourcePrincipalId = id;

      var sourceRefinedOutcome : [TAction.ActionOutcomeOption] = [];

      let sourceRefinedOutcomeResult = refineAllOutcomes_(trie.sourceOutcomes, callerPrincipalId, targetPrincipalId, actionFields, worldData, callerData, ?targetData);

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

      var newTrie = {
        sourcePrincipalId = trie.sourcePrincipalId;
        sourceActionConstraint = trie.sourceActionConstraint;
        //Overwrite sourceOutcome with refined sourceOutcome
        sourceOutcomes = sourceRefinedOutcome;
        worldsToFetchEntitiesFrom = trie.worldsToFetchEntitiesFrom;
        worldsToFetchActionHistoryFrom = trie.worldsToFetchActionHistoryFrom;
        nodeId = trie.nodeId;
        nodeIdTask = trie.nodeIdTask;
        sourceNewActionState = trie.sourceNewActionState;
        sourceData = trie.sourceData;
      };

      subActions_ := Trie.put(subActions_, Utils.keyT(sourcePrincipalId), Text.equal, newTrie).0;
    };

    //Apply outcomes
    label loop5 for ((id, trie) in Trie.iter(subActions_)) {

      if (trie.sourceOutcomes.size() == 0) continue loop5;

      let sourcePrincipalId = id;

      let sourceNode : UserNode = actor (trie.nodeId);

      ignore applyOutcomes_(trie.sourcePrincipalId, sourceNode, trie.sourceNewActionState, trie.sourceOutcomes);
    };

    //UNLOCK ACTION
    changeActionLockState_(callerPrincipalId, actionId, false);

    ignore tryBroadcastFetchUsersDataRequest_(callerPrincipalId);
  };

  private func processActionNewAwait_(callerPrincipalId : Text, targetPrincipalId : Text, actionId : Text, actionFields : [TGlobal.Field], subActions : [SubAction]) : async () {

    let worldPrincipalId_ = worldPrincipalId();

    var callerData : [TEntity.StableEntity] = [];
    var worldData : [TEntity.StableEntity] = [];
    var targetData : [TEntity.StableEntity] = [];

    var subActions_ : Trie.Trie<Text, { sourcePrincipalId : Text; sourceActionConstraint : ?TAction.ActionConstraint; sourceOutcomes : [TAction.ActionOutcomeOption]; worldsToFetchEntitiesFrom : [Text]; worldsToFetchActionHistoryFrom : [Text]; nodeId : Text; nodeIdTask : async Result.Result<Text, Text>; sourceNewActionState : TAction.ActionState; sourceData : [TEntity.StableEntity] }> = Trie.empty<Text, { sourcePrincipalId : Text; sourceActionConstraint : ?TAction.ActionConstraint; sourceOutcomes : [TAction.ActionOutcomeOption]; worldsToFetchEntitiesFrom : [Text]; worldsToFetchActionHistoryFrom : [Text]; nodeId : Text; nodeIdTask : async Result.Result<Text, Text>; sourceNewActionState : TAction.ActionState; sourceData : [TEntity.StableEntity] }>();

    var getActionStateTasks : Trie.Trie<Text, { actionStateTask : async ?TAction.ActionState; entitiesTask : async Result.Result<[TEntity.StableEntity], Text>; actionHistoryTask : async [TAction.ActionOutcomeHistory] }> = Trie.empty<Text, { actionStateTask : async ?TAction.ActionState; entitiesTask : async Result.Result<[TEntity.StableEntity], Text>; actionHistoryTask : async [TAction.ActionOutcomeHistory] }>();

    //Get all the worlds' to fetch entities from and store them in "subActionsTrie".
    //Fetch nodeId for each subaction's source.
    //Store the task of fetching each nodeId in "subActionsTrie".
    for (subAction in Iter.fromArray(subActions)) {

      var worldsToFetchEntitiesFrom : [Text] = [];
      var worldsToFetchActionHistoryFrom : [Text] = [];
      //GET WORLD IDS TO FETCH ENTITIE AND ACTION HISTORY FROM
      switch (subAction.sourceActionConstraint) {
        case (?constraints) {

          //Entity Action History World Ids
          var worldsToFetchActionHistoryFromBuffer = Buffer.Buffer<Text>(0);
          switch (constraints.timeConstraint) {
            case (?timeConstraint) {

              for (actionHistory in Iter.fromArray(timeConstraint.actionHistory)) {

                switch (actionHistory) {
                  case (#updateEntity entityActionHistory) {

                    let _wid = Option.get(entityActionHistory.wid, worldPrincipalId());
                    if (Buffer.contains(worldsToFetchActionHistoryFromBuffer, _wid, Text.equal) == false) worldsToFetchActionHistoryFromBuffer.add(_wid);

                  };
                  case _ {};
                };

              };

            };
            case _ {};
          };

          //Entity World Ids
          var worldsToFetchEntitiesFromBuffer = Buffer.Buffer<Text>(0);

          for (entityConstraint in Iter.fromArray(constraints.entityConstraint)) {
            let _wid = Option.get(entityConstraint.wid, worldPrincipalId());
            if (Buffer.contains(worldsToFetchEntitiesFromBuffer, _wid, Text.equal) == false) worldsToFetchEntitiesFromBuffer.add(_wid);
          };
          worldsToFetchActionHistoryFrom := Buffer.toArray(worldsToFetchActionHistoryFromBuffer);
          worldsToFetchEntitiesFrom := Buffer.toArray(worldsToFetchEntitiesFromBuffer);
        };
        case _ {};
      };

      var task = getUserNode_(subAction.sourcePrincipalId);

      var newTrie = {
        sourcePrincipalId = subAction.sourcePrincipalId;
        sourceActionConstraint = subAction.sourceActionConstraint;
        sourceOutcomes = subAction.sourceOutcomes;
        worldsToFetchEntitiesFrom = worldsToFetchEntitiesFrom;
        worldsToFetchActionHistoryFrom = worldsToFetchActionHistoryFrom;
        nodeId = "";
        nodeIdTask = task;
        sourceNewActionState = {
          actionId = "";
          intervalStartTs = 0;
          actionCount = 0;
        };
        sourceData : [TEntity.StableEntity] = [];
      };

      switch (Trie.find(subActions_, Utils.keyT(subAction.sourcePrincipalId), Text.equal)) {
        case (?tempStoredSubAction) {

          switch (tempStoredSubAction.sourceActionConstraint) {
            case (?storedConstraint) {

              switch (newTrie.sourceActionConstraint) {
                case (?constraint) {

                  newTrie := {
                    sourcePrincipalId = tempStoredSubAction.sourcePrincipalId;
                    sourceActionConstraint = ?{
                      timeConstraint = storedConstraint.timeConstraint;
                      entityConstraint = Array.append(storedConstraint.entityConstraint, constraint.entityConstraint);
                      icrcConstraint = Array.append(storedConstraint.icrcConstraint, constraint.icrcConstraint);
                      nftConstraint = Array.append(storedConstraint.nftConstraint, constraint.nftConstraint);
                    };
                    sourceOutcomes = Array.append(tempStoredSubAction.sourceOutcomes, newTrie.sourceOutcomes);
                    worldsToFetchEntitiesFrom = Array.append(tempStoredSubAction.worldsToFetchEntitiesFrom, newTrie.worldsToFetchEntitiesFrom);
                    worldsToFetchActionHistoryFrom = Array.append(tempStoredSubAction.worldsToFetchActionHistoryFrom, newTrie.worldsToFetchActionHistoryFrom);
                    nodeId = tempStoredSubAction.nodeId;
                    nodeIdTask = tempStoredSubAction.nodeIdTask;
                    sourceNewActionState = tempStoredSubAction.sourceNewActionState;
                    sourceData = tempStoredSubAction.sourceData;
                  };
                };
                case _ {

                  newTrie := {
                    sourcePrincipalId = tempStoredSubAction.sourcePrincipalId;
                    sourceActionConstraint = ?storedConstraint;
                    sourceOutcomes = Array.append(tempStoredSubAction.sourceOutcomes, newTrie.sourceOutcomes);
                    worldsToFetchEntitiesFrom = Array.append(tempStoredSubAction.worldsToFetchEntitiesFrom, newTrie.worldsToFetchEntitiesFrom);
                    worldsToFetchActionHistoryFrom = Array.append(tempStoredSubAction.worldsToFetchActionHistoryFrom, newTrie.worldsToFetchActionHistoryFrom);
                    nodeId = tempStoredSubAction.nodeId;
                    nodeIdTask = tempStoredSubAction.nodeIdTask;
                    sourceNewActionState = tempStoredSubAction.sourceNewActionState;
                    sourceData = tempStoredSubAction.sourceData;
                  };
                };
              };
            };
            case _ {

            };
          };
        };
        case _ {};
      };

      subActions_ := Trie.put(subActions_, Utils.keyT(subAction.sourcePrincipalId), Text.equal, newTrie).0;
    };

    //Await for nodeIds to be fetched.
    //Store nodeIds in "subActions_".
    //fetch action source's action state & entities,
    //and keep track of the  action state & entities tasks in "getActionStateTasks".
    for ((id, trie) in Trie.iter(subActions_)) {
      let sourcePrincipalId = id;

      let nodeTaskResult = await trie.nodeIdTask;

      var nodeId = "";

      switch (nodeTaskResult) {
        case (#ok(content)) { nodeId := content };
        case (#err(errMsg)) {
          debugLog("The '" #actionId # "' action failed because it could not get world node Id.\nExtra insight: " #errMsg);
          //UNLOCK ACTION
          changeActionLockState_(callerPrincipalId, actionId, false);
          return;
        };
      };

      var newTrie = {
        sourcePrincipalId = trie.sourcePrincipalId;
        sourceActionConstraint = trie.sourceActionConstraint;
        sourceOutcomes = trie.sourceOutcomes;
        worldsToFetchEntitiesFrom = trie.worldsToFetchEntitiesFrom;
        worldsToFetchActionHistoryFrom = trie.worldsToFetchActionHistoryFrom;
        //Store the NodeId
        nodeId = nodeId;
        nodeIdTask = trie.nodeIdTask;
        sourceNewActionState = {
          actionId = "";
          intervalStartTs = 0;
          actionCount = 0;
        };
        sourceData = [];
      };

      subActions_ := Trie.put(subActions_, Utils.keyT(sourcePrincipalId), Text.equal, newTrie).0;

      let sourceNode : UserNode = actor (nodeId);

      //Fetch Source's Action State
      let currentCallerActionStateResultHandler = sourceNode.getActionState(trie.sourcePrincipalId, worldPrincipalId(), actionId);
      //Fetch Source's Entities
      let sourceEntityResultHandler = sourceNode.getAllUserEntitiesOfSpecificWorlds(trie.sourcePrincipalId, trie.worldsToFetchEntitiesFrom, null);

      let sourceActionHistoryResultHandler = sourceNode.getAllUserActionHistoryOfSpecificWorlds(trie.sourcePrincipalId, trie.worldsToFetchActionHistoryFrom, null);

      getActionStateTasks := Trie.put(
        getActionStateTasks,
        Utils.keyT(trie.sourcePrincipalId),
        Text.equal,
        {
          actionStateTask = currentCallerActionStateResultHandler;
          entitiesTask = sourceEntityResultHandler;
          actionHistoryTask = sourceActionHistoryResultHandler;
        },
      ).0;
    };

    //Await for action state & entities tasks
    //Refine & validate constraints
    //Catch worldData, callerData, and optional targetData
    //Store new source's action state and data in "subActions_".
    for ((id, trie) in Trie.iter(getActionStateTasks)) {
      let sourcePrincipalId = id;

      let currentActionState = await trie.actionStateTask;

      let entitiesTaskResult = await trie.entitiesTask;

      let actionHistoryTaskResult = await trie.actionHistoryTask;

      var sourceData : [TEntity.StableEntity] = [];
      var sourceActionHistoryData : [TAction.ActionOutcomeHistory] = actionHistoryTaskResult;

      switch (entitiesTaskResult) {
        case (#ok data) sourceData := data;
        case (#err errMsg) {
          debugLog("The '" #actionId # "' action failed because it could not get source's entities\nSourceId: " #id # "\nExtra insight: " #errMsg);
          //UNLOCK ACTION
          changeActionLockState_(callerPrincipalId, actionId, false);
          return;
        };
      };

      //Catch world's data
      if (sourcePrincipalId == worldPrincipalId_) {
        worldData := sourceData;
      };
      //Catch caller's data
      if (sourcePrincipalId == callerPrincipalId) {
        callerData := sourceData;
      };
      //Catch target's data
      if (sourcePrincipalId == targetPrincipalId) {
        targetData := sourceData;
      };

      switch (Trie.find(subActions_, Utils.keyT(id), Text.equal)) {
        case (?subAction) {

          var sourceNewActionState : TAction.ActionState = {
            actionId = "";
            intervalStartTs = 0;
            actionCount = 0;
          };

          switch (subAction.sourceActionConstraint) {
            case (?sc) {

              var sourceRefinedConstraints : ?TAction.ActionConstraint = ?{
                timeConstraint = null;
                containEntity = [];
                entityConstraint = [];
                icrcConstraint = [];
                nftConstraint = [];
              };

              //Refine Constraints
              let sourceRefinedConstraintsResult = refineConstraints_(subAction.sourceActionConstraint, callerPrincipalId, targetPrincipalId, actionFields);

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

              //Validate Constraints
              var sourceValidationResult = validateConstraints_(sourceData, sourceActionHistoryData, sourcePrincipalId, actionId, sourceRefinedConstraints, currentActionState);

              switch (await sourceValidationResult) {
                case (#ok(result)) {
                  sourceNewActionState := result;
                };
                case (#err(errMsg)) {
                  debugLog("The '" #actionId # "' action failed because it could not validate source action constraints\nExtra insight: " #errMsg);
                  //UNLOCK ACTION
                  changeActionLockState_(callerPrincipalId, actionId, false);
                  return;
                };
              };

            };
            case (_) {};
          };

          var newTrie = {
            sourcePrincipalId = subAction.sourcePrincipalId;
            sourceActionConstraint = subAction.sourceActionConstraint;
            sourceOutcomes = subAction.sourceOutcomes;
            worldsToFetchEntitiesFrom = subAction.worldsToFetchEntitiesFrom;
            worldsToFetchActionHistoryFrom = subAction.worldsToFetchActionHistoryFrom;
            nodeId = subAction.nodeId;
            nodeIdTask = subAction.nodeIdTask;
            //Store New Action State
            sourceNewActionState = sourceNewActionState;
            //Store Source's data
            sourceData = sourceData;
          };

          subActions_ := Trie.put(subActions_, Utils.keyT(sourcePrincipalId), Text.equal, newTrie).0;
        };
        case _ {

          debugLog("The '" #actionId # "' action failed because it could not find source id: " #id);
          //UNLOCK ACTION
          changeActionLockState_(callerPrincipalId, actionId, false);
          return;
        };
      };
    };

    //Refine outcomes
    label loop4 for ((id, trie) in Trie.iter(subActions_)) {

      if (trie.sourceOutcomes.size() == 0) continue loop4;

      let sourcePrincipalId = id;

      var sourceRefinedOutcome : [TAction.ActionOutcomeOption] = [];

      let sourceRefinedOutcomeResult = refineAllOutcomes_(trie.sourceOutcomes, callerPrincipalId, targetPrincipalId, actionFields, worldData, callerData, ?targetData);

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

      var newTrie = {
        sourcePrincipalId = trie.sourcePrincipalId;
        sourceActionConstraint = trie.sourceActionConstraint;
        //Overwrite sourceOutcome with refined sourceOutcome
        sourceOutcomes = sourceRefinedOutcome;
        worldsToFetchEntitiesFrom = trie.worldsToFetchEntitiesFrom;
        worldsToFetchActionHistoryFrom = trie.worldsToFetchActionHistoryFrom;
        nodeId = trie.nodeId;
        nodeIdTask = trie.nodeIdTask;
        sourceNewActionState = trie.sourceNewActionState;
        sourceData = trie.sourceData;
      };

      subActions_ := Trie.put(subActions_, Utils.keyT(sourcePrincipalId), Text.equal, newTrie).0;
    };

    //Apply outcomes
    label loop5 for ((id, trie) in Trie.iter(subActions_)) {

      if (trie.sourceOutcomes.size() == 0) continue loop5;

      let sourcePrincipalId = id;

      let sourceNode : UserNode = actor (trie.nodeId);

      await applyOutcomes_(trie.sourcePrincipalId, sourceNode, trie.sourceNewActionState, trie.sourceOutcomes);
    };

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
            //ignore send_app_message(Principal.fromText(otherUserPrincipalId), #actionOutcomes outcomes);
          };
        };
      };
      case (#err errMsg) {
        debugLog("Error, source: tryBroadcastOutcomes_, extra details " #errMsg);
      };
    };
  };
  private func tryBroadcastFetchUsersDataRequest_(uid : Text) : async () {
    switch (await getAllUsersInTargetUserRoom_(uid)) {
      case (#ok(users)) {

        for (e in Iter.fromArray(users)) {
          let otherUserPrincipalId = e;
          //ignore send_app_message(Principal.fromText(otherUserPrincipalId), #userIdsToFetchDataFrom(users));
        };
      };
      case (#err errMsg) {
        debugLog("Error, source: tryBroadcastFetchUsersDataRequest_, extra details " #errMsg);
      };
    };
  };

  //If #ok it will return an Text of all users in room you are in separated by comma, including yourself
  private func isUserInRoom_(uid : Text) : async (Result.Result<TEntity.StableEntity, Text>) {

    //FETCH NODES IDS
    var worldNodeId : Text = "2vxsx-fae";

    let getWorldNodeHandler = getUserNode_(worldPrincipalId());

    switch (await getWorldNodeHandler) {
      case (#ok(content)) { worldNodeId := content };
      case (#err(errMsg)) {
        return #err(errMsg);
      };
    };

    let worldNode : UserNode = actor (worldNodeId);

    var worldData : [TEntity.StableEntity] = [];

    let worldEntityResultHandler = worldNode.getAllUserEntities(worldPrincipalId(), worldPrincipalId(), null);

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
        return #err("World Node not found, details: " #errMsg);
      };
    };

    let worldNode : UserNode = actor (worldNodeId);

    var worldData : [TEntity.StableEntity] = [];

    let worldEntityResultHandler = worldNode.getAllUserEntities(worldPrincipalId(), worldPrincipalId(), null);

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
    var _amt = await ICP_Ledger.account_balance({
      account = Blob.fromArray(Hex.decode(AccountIdentifier.fromText(Principal.toText(WorldId()), null)));
    });
    _amt := {
      e8s = _amt.e8s - 10000;
    };
    var _req : ICP.TransferArgs = {
      to = Blob.fromArray(Hex.decode(AccountIdentifier.fromText(args.toPrincipal, null)));
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

  public shared ({ caller }) func withdrawIcrcFromWorld(args : { tokenCanisterId : Text; toPrincipal : Text }) : async (Result.Result<ICRC.TransferResult, { #TxErr : ICRC.TransferError; #Err : Text }>) {
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
    var res : ICRC.TransferResult = await ICRC_Ledger.icrc1_transfer(_req);
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
            switch (getEntityField_(callerData, worldPrincipalId(), id, variableName)) {
              case (?_entityFieldValue) variableValue := _entityFieldValue;
              case _ return #err("could not find field of source: " #source # " eid: " #id # " fieldName: " #variableName);
            };
          } else if (source == "$target") {

            switch targetData {
              case (?value) {
                if (value.size() == 0) return #err "target data is empty";

                switch (getEntityField_(value, worldPrincipalId(), id, variableName)) {
                  case (?_entityFieldValue) variableValue := _entityFieldValue;
                  case _ return #err("could not find field of source: " #source # " eid: " #id # " fieldName: " #variableName);
                };
              };
              case _ return #err "target data is null";
            };
          } else if (source == "$world") {
            switch (getEntityField_(worldData, worldPrincipalId(), id, variableName)) {
              case (?_entityFieldValue) variableValue := _entityFieldValue;
              case _ return #err("could not find field of source: " #source # "  eid: " #id # " fieldName: " #variableName);
            };
          } else if (source == "$configs") {

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
      uid = worldPrincipalId();
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

  public shared ({ caller }) func icrc28_trusted_origins() : async ({
    trusted_origins : [Text];
  }) {
    return {
      trusted_origins = trusted_origins;
    };
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

  // let gateway_principal : Text = "3656s-3kqlj-dkm5d-oputg-ymybu-4gnuq-7aojd-w2fzw-5lfp2-4zhx3-4ae";

  // public type WSSentArg = {
  //     #actionOutcomes : TAction.ActionReturn;
  //     #userIdsToFetchDataFrom : [Text];
  // };

  // /// A custom function to send the message to the client
  public query func validateEntityConstraints(uid : Text, entities : [TEntity.StableEntity], entityConstraints : [TConstraints.EntityConstraint]) : async (Bool) {
    switch (validateEntityConstraints_(uid, entities, entityConstraints)) {
      case (#err(errMsg)) return false;
      case _ return true;
    };
  };

  public shared ({ caller }) func validateConstraints(uid : Text, aid : TGlobal.actionId, actionConstraint : ?TAction.ActionConstraint) : async ({
    aid : Text;
    status : Bool;
  }) {

    var worldsToFetchEntitiesFrom : [Text] = [];
    var worldsToFetchActionHistoryFrom : [Text] = [];
    //GET WORLD IDS TO FETCH ENTITIE AND ACTION HISTORY FROM
    switch (actionConstraint) {
      case (?constraints) {

        //Entity Action History World Ids
        var worldsToFetchActionHistoryFromBuffer = Buffer.Buffer<Text>(0);
        switch (constraints.timeConstraint) {
          case (?timeConstraint) {

            for (actionHistory in Iter.fromArray(timeConstraint.actionHistory)) {

              switch (actionHistory) {
                case (#updateEntity entityActionHistory) {

                  let _wid = Option.get(entityActionHistory.wid, worldPrincipalId());
                  if (Buffer.contains(worldsToFetchActionHistoryFromBuffer, _wid, Text.equal) == false) worldsToFetchActionHistoryFromBuffer.add(_wid);

                };
                case _ {};
              };
            };
          };
          case _ {};
        };

        //Entity World Ids
        var worldsToFetchEntitiesFromBuffer = Buffer.Buffer<Text>(0);

        for (entityConstraint in Iter.fromArray(constraints.entityConstraint)) {
          let _wid = Option.get(entityConstraint.wid, worldPrincipalId());
          if (Buffer.contains(worldsToFetchEntitiesFromBuffer, _wid, Text.equal) == false) worldsToFetchEntitiesFromBuffer.add(_wid);
        };
        worldsToFetchEntitiesFrom := Buffer.toArray(worldsToFetchEntitiesFromBuffer);

      };
      case _ {};
    };

    //TRY FETCH USERNODE
    var userNodeId : Text = "2vxsx-fae";

    var userNodeIdResult = await worldHub.getUserNodeCanisterId(uid);

    switch (userNodeIdResult) {
      case (#ok(content)) { userNodeId := content };
      case (#err(errMsg)) {
        //FAILURE
        return { aid = aid; status = false };
      };
    };

    let userNode : UserNode = actor (userNodeId);

    //TRY GETCH DEPENDENCIES
    let entitiesTask = userNode.getAllUserEntitiesOfSpecificWorlds(uid, worldsToFetchEntitiesFrom, null);
    let actionHistoryTask = userNode.getAllUserActionHistoryOfSpecificWorlds(uid, worldsToFetchActionHistoryFrom, null);

    var entityData : [TEntity.StableEntity] = [];
    var actionHistory : [TAction.ActionOutcomeHistory] = [];

    switch (await entitiesTask) {
      case (#ok _entityData) {
        entityData := _entityData;
      };
      case (#err errMsg) {
        //FAILURE
        return { aid = aid; status = false };
      };
    };

    actionHistory := await actionHistoryTask;

    //VALIDATE CONSTRAINTS
    switch (await validateConstraints_(entityData, actionHistory, uid, aid, actionConstraint, null)) {
      case (#err(errMsg)) return { aid = aid; status = false };
      case _ return { aid = aid; status = true };
    };
  };

  public composite query func getActionStatusComposite(args : { uid : Text; aid : TGlobal.actionId }) : async (Result.Result<TAction.ActionStatusReturn, Text>) {
    // Validate EntityConstraints - Composite query getAllUserEntitiesOfSpecificWorldsComposite() in UserNode for Entities.
    // Validate TimeConstraints (which now contains the new actionHistory constraints). Composite query getUserActionHistoryOfSpecificWorldsComposite() in UserNode for ActionHistory.
    // Ignore NFT and ICRC constraints because those require calls to other canisters. Those will be handled on client instead.
    // Return the ActionStatusReturn type

    //VARIABLES
    var returnValue = {
      isValid = true;
      timeStatus = {
        nextAvailableTimestamp : ?Nat = null;
        actionsLeft : ?Nat = null;
      };
      actionHistoryStatus : [TAction.ConstraintStatus] = [];
      entitiesStatus : [TAction.ConstraintStatus] = [];
    };
    var actionHistoryStatusBuffer = Buffer.Buffer<TAction.ConstraintStatus>(0);

    var entitiesStatusBuffer = Buffer.Buffer<TAction.ConstraintStatus>(0);

    var callerAction : TAction.SubAction = {
      actionConstraint = null;
      actionResult = { outcomes = [] };
    };
    var subActions = Buffer.Buffer<SubAction>(0);

    //CHECK IF ACTION EXIST
    switch (getSpecificAction_(args.aid)) {
      case (?_action) {
        //CHECK IF CALLER SUBACTION EXIST
        switch (_action.callerAction) {
          case (?_callerAction) {
            callerAction := _callerAction;
          };
          case (_) {
            return #err("The '" #args.aid # "' action failed to be executed, because it doesn't have a Caller SubAction");
          };
        };
      };
      case (_) {
        return #err("The '" #args.aid # "' action failed to be executed, because it doesn't exist");
      };
    };

    ///

    var worldsToFetchEntitiesFrom : [Text] = [];
    var worldsToFetchActionHistoryFrom : [Text] = [];

    //GET WORLD IDS TO FETCH ENTITIE AND ACTION HISTORY FROM
    switch (callerAction.actionConstraint) {
      case (?constraints) {
        //Entity Action History World Ids
        var worldsToFetchActionHistoryFromBuffer = Buffer.Buffer<Text>(0);
        switch (constraints.timeConstraint) {
          case (?timeConstraint) {
            for (actionHistory in Iter.fromArray(timeConstraint.actionHistory)) {
              switch (actionHistory) {
                case (#updateEntity entityActionHistory) {
                  let _wid = Option.get(entityActionHistory.wid, worldPrincipalId());
                  if (Buffer.contains(worldsToFetchActionHistoryFromBuffer, _wid, Text.equal) == false) worldsToFetchActionHistoryFromBuffer.add(_wid);
                };
                case _ {};
              };
            };
          };
          case _ {};
        };

        //Entity World Ids
        var worldsToFetchEntitiesFromBuffer = Buffer.Buffer<Text>(0);

        for (entityConstraint in Iter.fromArray(constraints.entityConstraint)) {
          let _wid = Option.get(entityConstraint.wid, worldPrincipalId());
          if (Buffer.contains(worldsToFetchEntitiesFromBuffer, _wid, Text.equal) == false) worldsToFetchEntitiesFromBuffer.add(_wid);
        };
        worldsToFetchEntitiesFrom := Buffer.toArray(worldsToFetchEntitiesFromBuffer);
        worldsToFetchActionHistoryFrom := Buffer.toArray(worldsToFetchActionHistoryFromBuffer);
      };
      case _ {};
    };

    //TRY FETCH USERNODE
    var userNodeId : Text = "2vxsx-fae";

    var userNodeIdResult = await worldHub.getUserNodeCanisterIdComposite(args.uid);

    switch (userNodeIdResult) {
      case (#ok(content)) { userNodeId := content };
      case (#err(errMsg)) {
        return #err("The '" #args.aid # "' action failed to be executed, User Node not found, details: " #errMsg);
      };
    };

    let userNode : UserNode = actor (userNodeId);

    //TRY GETCH DEPENDENCIES
    var actionState : ?TAction.ActionState = await userNode.getActionState(args.uid, worldPrincipalId(), args.aid);
    var entityData : [TEntity.StableEntity] = [];
    var actionHistory : [TAction.ActionOutcomeHistory] = await userNode.getAllUserActionHistoryOfSpecificWorldsComposite(args.uid, worldsToFetchActionHistoryFrom, null);

    switch (await userNode.getAllUserEntitiesOfSpecificWorldsComposite(args.uid, worldsToFetchEntitiesFrom, null)) {
      case (#ok _entityData) {
        entityData := _entityData;
      };
      case (#err errMsg) {
        return #err("The '" #args.aid # "' action failed to be executed, details: " #errMsg);
      };
    };

    //HANDLE CONSTRAINTS

    var _intervalStartTs : Nat = 0;
    var _actionCount : Nat = 0;

    switch (actionState) {
      case (?a) {
        _intervalStartTs := a.intervalStartTs;
        _actionCount := a.actionCount;
      };
      case _ {};
    };

    switch (callerAction.actionConstraint) {
      case (?constraints) {

        //TIME CONSTRAINT
        var last_action_time : Nat = _intervalStartTs; // Used for history outcome validation
        switch (constraints.timeConstraint) {
          case (?t) {
            //Start Time
            switch (t.actionStartTimestamp) {
              case (?actionStartTimestamp) {
                if (actionStartTimestamp > Time.now()) {};
              };
              case _ {};
            };
            //Expiration
            switch (t.actionExpirationTimestamp) {
              case (?actionExpirationTimestamp) {
                if (actionExpirationTimestamp < Time.now()) return #err("action is expired!");
              };
              case _ {};
            };
            //Time Interval
            switch (t.actionTimeInterval) {
              case (?actionTimeInterval) {

                let nextAvailableTimestamp = _intervalStartTs + actionTimeInterval.intervalDuration;

                // Assign actionsLeft for the success case
                returnValue := {
                  isValid = returnValue.isValid;
                  timeStatus = {
                    nextAvailableTimestamp = null;
                    actionsLeft = ?Nat.max((actionTimeInterval.actionsPerInterval - _actionCount), 0);
                  };
                  actionHistoryStatus = returnValue.actionHistoryStatus;
                  entitiesStatus = returnValue.entitiesStatus;
                };

                if ((nextAvailableTimestamp > Time.now()) and (_actionCount >= actionTimeInterval.actionsPerInterval)) {
                  //FAILURE: ACTION IS AVAILABLE IN THE FUTURE
                  returnValue := {
                    isValid = false;
                    timeStatus = {
                      nextAvailableTimestamp = ?nextAvailableTimestamp;
                      actionsLeft = null;
                    };
                    actionHistoryStatus = returnValue.actionHistoryStatus;
                    entitiesStatus = returnValue.entitiesStatus;
                  };
                };
                if (actionTimeInterval.actionsPerInterval == 0) {
                  //FAILURE: ACTION PER INTERVAL IS EQUAL TO 0 SO IT WILL NEVER BE VALID
                  returnValue := {
                    isValid = false;
                    timeStatus = {
                      nextAvailableTimestamp = null;
                      actionsLeft = null;
                    };
                    actionHistoryStatus = returnValue.actionHistoryStatus;
                    entitiesStatus = returnValue.entitiesStatus;
                  };
                };

                if (last_action_time == 0 and (Int.abs(Time.now()) > actionTimeInterval.intervalDuration)) {
                  last_action_time := (Int.abs(Time.now()) - actionTimeInterval.intervalDuration);
                };
              };
              case _ {};
            };

            switch (t.actionExpirationTimestamp) {
              case (?actionExpirationTimestamp) {
                if (actionExpirationTimestamp < Time.now()) {

                  //FAILURE: ACTION IS EXPIRED
                  returnValue := {
                    isValid = false;
                    timeStatus = {
                      nextAvailableTimestamp = null;
                      actionsLeft = null;
                    };
                    actionHistoryStatus = returnValue.actionHistoryStatus;
                    entitiesStatus = returnValue.entitiesStatus;
                  };
                };
              };
              case _ {};
            };

            let actionHistoryConstraint = t.actionHistory;

            // ACTION HISTORY CONSTRAINTS
            var history_outcomes = actionHistory;

            for (expected in actionHistoryConstraint.vals()) {
              switch (expected) {
                case (#updateEntity outcome) {
                  let _entityId = outcome.eid;
                  var _fieldName = "";
                  for (update in outcome.updates.vals()) {
                    switch (update) {
                      case (#incrementNumber iv) {
                        _fieldName := iv.fieldName;
                        // Query history outcomes and validate
                        var updated_value : Float = 0.0;
                        for (i in history_outcomes.vals()) {
                          if (i.appliedAt >= last_action_time) {
                            switch (i.option) {
                              case (#updateEntity history_outcome) {
                                if (history_outcome.eid == _entityId) {
                                  for (history_update in history_outcome.updates.vals()) {
                                    switch (history_update) {
                                      case (#incrementNumber val) {
                                        if (val.fieldName == _fieldName) {
                                          switch (val.fieldValue) {
                                            case (#number n) {
                                              updated_value := updated_value + n;
                                            };
                                            case (#formula _) {};
                                          };
                                        };
                                      };
                                      case _ {};
                                    };
                                  };
                                };
                              };
                              case _ {};
                            };
                          };
                        };
                        // check
                        switch (iv.fieldValue) {
                          case (#number n) {
                            //ADD ACTION HISTORY STATUS
                            actionHistoryStatusBuffer.add({
                              eid = _entityId;
                              fieldName = iv.fieldName;
                              currentValue = Float.toText(updated_value);
                              expectedValue = Float.toText(n);
                            });

                            if (n > updated_value) {
                              //FAILURE: ACTION HISTORY CONDITION DID NOT MET
                              returnValue := {
                                isValid = false;
                                timeStatus = returnValue.timeStatus;
                                actionHistoryStatus = returnValue.actionHistoryStatus;
                                entitiesStatus = returnValue.entitiesStatus;
                              };
                            };
                          };
                          case _ {};
                        };
                      };
                      case _ {};
                    };
                  };
                };
                case _ {}; // other action history will be handled later
              };
            };
          };
          case _ {};
        };

        //ENTITY CONSTRAINTS
        for (e in constraints.entityConstraint.vals()) {

          var wid = Option.get(e.wid, worldPrincipalId());

          switch (e.entityConstraintType) {
            case (#greaterThanNumber val) {
              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  let current_val_in_float = Utils.textToFloat(currentVal);

                  if (current_val_in_float < val.value) {
                    //FAILURE: ENTITY CONSTRAINT CONDITION DID NOT MET
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                  //ADD ACTION HISTORY STATUS
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = currentVal;
                    expectedValue = Float.toText(val.value);
                  });
                };
                case _ {
                  //ADD ACTION HISTORY STATUS
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = "0";
                    expectedValue = Float.toText(val.value);
                  });
                };
              };
            };
            case (#lessThanNumber val) {
              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  let current_val_in_float = Utils.textToFloat(currentVal);
                  if (current_val_in_float >= val.value) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                  //ADD ACTION HISTORY STATUS
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = currentVal;
                    expectedValue = Float.toText(val.value);
                  });
                };
                case _ {
                  //ADD ACTION HISTORY STATUS
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = "0";
                    expectedValue = Float.toText(val.value);
                  });
                };
              };

            };
            case (#equalToNumber val) {
              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  let current_val_in_float = Utils.textToFloat(currentVal);
                  if (val.equal) {
                    if (current_val_in_float != val.value) {
                      returnValue := {
                        isValid = false;
                        timeStatus = returnValue.timeStatus;
                        actionHistoryStatus = returnValue.actionHistoryStatus;
                        entitiesStatus = returnValue.entitiesStatus;
                      };
                    };
                  } else {
                    if (current_val_in_float == val.value) {
                      returnValue := {
                        isValid = false;
                        timeStatus = returnValue.timeStatus;
                        actionHistoryStatus = returnValue.actionHistoryStatus;
                        entitiesStatus = returnValue.entitiesStatus;
                      };
                    };
                  };
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = currentVal;
                    expectedValue = Float.toText(val.value);
                  });
                };
                case _ {
                  if (val.equal) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                    entitiesStatusBuffer.add({
                      eid = e.eid;
                      fieldName = val.fieldName;
                      currentValue = "0";
                      expectedValue = Float.toText(val.value);
                    });
                  };
                };
              };

            };
            case (#equalToText val) {

              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  if (val.equal) {
                    if (currentVal != val.value) {
                      returnValue := {
                        isValid = false;
                        timeStatus = returnValue.timeStatus;
                        actionHistoryStatus = returnValue.actionHistoryStatus;
                        entitiesStatus = returnValue.entitiesStatus;
                      };
                    };
                  } else {
                    if (currentVal == val.value) {
                      returnValue := {
                        isValid = false;
                        timeStatus = returnValue.timeStatus;
                        actionHistoryStatus = returnValue.actionHistoryStatus;
                        entitiesStatus = returnValue.entitiesStatus;
                      };
                    };
                  };
                };
                case _ {
                  if (val.equal) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                };
              };

            };
            case (#containsText val) {
              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  if (val.contains) {
                    if (Text.contains(currentVal, #text(val.value)) == false) {
                      returnValue := {
                        isValid = false;
                        timeStatus = returnValue.timeStatus;
                        actionHistoryStatus = returnValue.actionHistoryStatus;
                        entitiesStatus = returnValue.entitiesStatus;
                      };
                    };
                  } else {
                    if (Text.contains(currentVal, #text(val.value))) {
                      returnValue := {
                        isValid = false;
                        timeStatus = returnValue.timeStatus;
                        actionHistoryStatus = returnValue.actionHistoryStatus;
                        entitiesStatus = returnValue.entitiesStatus;
                      };
                    };
                  };
                };
                case _ {
                  if (val.contains) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                };
              };

            };
            case (#greaterThanNowTimestamp val) {

              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {

                  let current_val_in_Nat = Utils.textToNat(currentVal);
                  if (current_val_in_Nat < Time.now()) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                };
                case _ {
                  returnValue := {
                    isValid = false;
                    timeStatus = returnValue.timeStatus;
                    actionHistoryStatus = returnValue.actionHistoryStatus;
                    entitiesStatus = returnValue.entitiesStatus;
                  };
                };
              };

            };
            case (#lessThanNowTimestamp val) {

              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {

                  let current_val_in_Nat = Utils.textToNat(currentVal);
                  if (current_val_in_Nat > Time.now()) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                };
                case _ {
                  //We are not longer returning false if entity or field doesnt exist
                  //return #err(("You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
                };
              };

            };
            case (#greaterThanEqualToNumber val) {

              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {
                  let current_val_in_float = Utils.textToFloat(currentVal);
                  if (current_val_in_float < val.value) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = currentVal;
                    expectedValue = Float.toText(val.value);
                  });

                };
                case _ {
                  returnValue := {
                    isValid = false;
                    timeStatus = returnValue.timeStatus;
                    actionHistoryStatus = returnValue.actionHistoryStatus;
                    entitiesStatus = returnValue.entitiesStatus;
                  };
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = "0";
                    expectedValue = Float.toText(val.value);
                  });
                };
              };

            };
            case (#lessThanEqualToNumber val) {

              switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                case (?currentVal) {

                  let current_val_in_float = Utils.textToFloat(currentVal);

                  if (current_val_in_float > val.value) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                  entitiesStatusBuffer.add({
                    eid = e.eid;
                    fieldName = val.fieldName;
                    currentValue = currentVal;
                    expectedValue = Float.toText(val.value);
                  });
                };
                case _ {
                  //We are not longer returning false if entity or field doesnt exist
                  // return #err(("You don't have entity of id: " #e.eid # " or field with key : \"" #val.fieldName # "\" therefore, does not exist in respected entity to match entity constraints."));
                };
              };

            };
            case (#existField val) {

              switch (getEntity_(entityData, wid, e.eid)) {
                case (?entity) {

                  switch (getEntityField_(entityData, wid, e.eid, val.fieldName)) {
                    case (?currentVal) {
                      if (val.value == false) {
                        returnValue := {
                          isValid = false;
                          timeStatus = returnValue.timeStatus;
                          actionHistoryStatus = returnValue.actionHistoryStatus;
                          entitiesStatus = returnValue.entitiesStatus;
                        };
                      };
                    };
                    case _ {
                      if (val.value) {
                        returnValue := {
                          isValid = false;
                          timeStatus = returnValue.timeStatus;
                          actionHistoryStatus = returnValue.actionHistoryStatus;
                          entitiesStatus = returnValue.entitiesStatus;
                        };
                      };
                    };
                  };

                };
                case _ {
                  if (val.value) {
                    returnValue := {
                      isValid = false;
                      timeStatus = returnValue.timeStatus;
                      actionHistoryStatus = returnValue.actionHistoryStatus;
                      entitiesStatus = returnValue.entitiesStatus;
                    };
                  };
                };
              };
            };
            case _ {};
          };
        };
      };
      case _ {};
    };

    returnValue := {
      isValid = returnValue.isValid;
      timeStatus = returnValue.timeStatus;
      actionHistoryStatus = Buffer.toArray(actionHistoryStatusBuffer);
      entitiesStatus = Buffer.toArray(entitiesStatusBuffer);
    };

    //
    return #ok(returnValue);
  };

  public shared ({ caller }) func deleteActionHistoryForUser(args : { uid : TGlobal.userId }) : async () {
    assert (isAdmin_(caller) or Principal.toText(caller) == worldPrincipalId());

    switch (await getUserNode_(args.uid)) {
      case (#ok(userNodeId)) {
        let usernode : UserNode = actor (userNodeId);
        await usernode.deleteActionHistoryForUser(args);
      };
      case _ {};
    };
  };

  // BOOM token staking for DAO
  private var _proStake : Nat = 5000000000;
  private var _eliteStake : Nat = 10000000000;
  private stable var _boomStakes : Trie.Trie<Text, TStaking.ICRCStake> = Trie.empty(); // key -> (user principal id)
  //ICRC Stake verification checks and staking
  //1. If user already staked tokens, check for upgrading tier with token difference amount only (excess tokens will be transferred back) TO BE DECIDED
  //2. query token tx from ledger
  //3. init user stakes
  //4. Grant user an entity in DB for corresponding tier
  private func queryIcrcTx_(blockIndex : Nat, toPrincipal : Text, fromPrincipal : Text, amt : Nat, tokenCanisterId : Text) : async (Result.Result<Text, Text>) {
    var _req : ICRC.GetTransactionsRequest = {
      start = blockIndex;
      length = blockIndex + 1;
    };

    var to_ : ICRC.Account = {
      owner = Principal.fromText(toPrincipal);
      subaccount = null;
    };
    var from_ : ICRC.Account = {
      owner = Principal.fromText(fromPrincipal);
      subaccount = null;
    };
    let ICRC_Ledger : ICRC.Self = actor (tokenCanisterId);
    var t : ICRC.GetTransactionsResponse = {
      first_index = 0;
      log_length = 0;
      transactions = [];
      archived_transactions = [];
    };
    t := await ICRC_Ledger.get_transactions(_req);

    if ((t.transactions).size() == 0) {
      return #err("tx blockIndex does not exist");
    };
    let tx = t.transactions[0];
    if (tx.kind == "transfer") {
      let transfer = tx.transfer;
      switch (transfer) {
        case (?tt) {
          if (tt.from == from_ and tt.to == to_ and tt.amount == amt) {
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
          if (tt.to == to_ and tt.amount == amt) {
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

  private func transferBoom_(toPrincipal : Text, amt : Nat) : async (ICRC.TransferResult) {
    let req : ICRC.TransferArg = {
      to = {
        owner = Principal.fromText(toPrincipal);
        subaccount = null;
      };
      fee = ?100000;
      memo = ?Text.encodeUtf8("BOOM-Token-locking/unlocking");
      from_subaccount = null;
      created_at_time = null;
      amount = amt;
    };
    return (await BOOM_Ledger.icrc1_transfer(req));
  };

  public shared ({ caller }) func stakeBoomTokens(blockIndex : Nat, toPrincipal : Text, fromPrincipal : Text, amt : Nat, kind : TStaking.ICRCStakeKind) : async (Result.Result<Text, Text>) {
    assert (Principal.fromText(fromPrincipal) == caller);
    assert (Principal.fromText(toPrincipal) == WorldId());
    assert (amt == _proStake or amt == _eliteStake or amt == (_eliteStake - _proStake));
    let _staker : Text = Principal.toText(caller);
    switch (Trie.find(_boomStakes, Utils.keyT(_staker), Text.equal)) {
      case (?stakeInfo) {
        // Two cases to handle - 1. Upgrade 2. Re-Staking (after previous stakes got dissolved)
        if (stakeInfo.dissolvedAt == 0) {
          // Upgrade
          switch (stakeInfo.kind) {
            case (#pro) {
              let difference_for_tier_upgrade : Nat = _eliteStake - _proStake;
              if (amt < difference_for_tier_upgrade) {
                let _ = await transferBoom_(fromPrincipal, amt - 100000);
                return #err("you are already PRO staker and the amount transferred is not sufficient to upgrade tier to ELITE.");
              } else {
                switch (kind) {
                  case (#pro) {
                    let _ = await transferBoom_(fromPrincipal, amt - 100000);
                    return #err("you are already a PRO Staker. If you want to upgrade to ELITE, clicke on ELITE BOOM staker.");
                  };
                  case (#elite) {
                    switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                      case (#ok o) {
                        let newStakeInfo : TStaking.ICRCStake = {
                          staker = _staker;
                          tokenCanisterId = ENV.BoomLedgerCanisterId;
                          amount = _eliteStake;
                          kind = #elite;
                          stakedAt = Time.now();
                          dissolvedAt = 0;
                        };
                        _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                      };
                      case (#err e) {
                        return #err("We could not verify $BOOM transfer for staking, please contact dev team in discord.");
                      };
                    };
                  };
                };
              };
            };
            case (#elite) {
              return #err("you are already a ELITE staker.");
            };
          };
        } else if (stakeInfo.dissolvedAt != 0) {
          // Re-Staking
          switch (stakeInfo.kind) {
            case (#pro) {
              switch (kind) {
                case (#pro) {
                  switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                    case (#ok o) {
                      let newStakeInfo : TStaking.ICRCStake = {
                        staker = _staker;
                        tokenCanisterId = ENV.BoomLedgerCanisterId;
                        amount = _proStake;
                        kind = #pro;
                        stakedAt = Time.now();
                        dissolvedAt = 0;
                      };
                      let _ = await transferBoom_(fromPrincipal, stakeInfo.amount - 100000);
                      _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                    };
                    case (#err e) {
                      return #err("We could not verify $BOOM transfer for PRO re-staking, please contact dev team in discord.");
                    };
                  };
                };
                case (#elite) {
                  switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                    case (#ok o) {
                      let newStakeInfo : TStaking.ICRCStake = {
                        staker = _staker;
                        tokenCanisterId = ENV.BoomLedgerCanisterId;
                        amount = _eliteStake;
                        kind = #elite;
                        stakedAt = Time.now();
                        dissolvedAt = 0;
                      };
                      let _ = await transferBoom_(fromPrincipal, stakeInfo.amount - 100000);
                      _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                    };
                    case (#err e) {
                      return #err("We could not verify $BOOM transfer for ELITE re-staking, please contact dev team in discord.");
                    };
                  };
                };
              };
            };
            case (#elite) {
              switch (kind) {
                case (#pro) {
                  switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                    case (#ok o) {
                      let newStakeInfo : TStaking.ICRCStake = {
                        staker = _staker;
                        tokenCanisterId = ENV.BoomLedgerCanisterId;
                        amount = _proStake;
                        kind = #pro;
                        stakedAt = Time.now();
                        dissolvedAt = 0;
                      };
                      let _ = await transferBoom_(fromPrincipal, stakeInfo.amount - 100000);
                      _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                    };
                    case (#err e) {
                      return #err("We could not verify $BOOM transfer for PRO re-staking, please contact dev team in discord.");
                    };
                  };
                };
                case (#elite) {
                  switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                    case (#ok o) {
                      let newStakeInfo : TStaking.ICRCStake = {
                        staker = _staker;
                        tokenCanisterId = ENV.BoomLedgerCanisterId;
                        amount = _eliteStake;
                        kind = #elite;
                        stakedAt = Time.now();
                        dissolvedAt = 0;
                      };
                      let _ = await transferBoom_(fromPrincipal, stakeInfo.amount - 100000);
                      _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                    };
                    case (#err e) {
                      return #err("We could not verify $BOOM transfer for ELITE re-staking, please contact dev team in discord.");
                    };
                  };
                };
              };
            };
          };
        };
      };
      case _ {
        switch (kind) {
          case (#pro) {
            if (amt < _proStake) {
              return #err("amount transferred is not sufficient to become a PRO staker.");
            } else {
              switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                case (#ok o) {
                  let newStakeInfo : TStaking.ICRCStake = {
                    staker = _staker;
                    tokenCanisterId = ENV.BoomLedgerCanisterId;
                    amount = _proStake;
                    kind = #pro;
                    stakedAt = Time.now();
                    dissolvedAt = 0;
                  };
                  _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                };
                case (#err e) {
                  return #err("We could not verify $BOOM transfer for staking, please contact dev team in discord.");
                };
              };
            };
          };
          case (#elite) {
            if (amt < _eliteStake) {
              return #err("amount transferred is not sufficient to become a ELITE staker.");
            } else {
              switch (await queryIcrcTx_(blockIndex, toPrincipal, fromPrincipal, amt, ENV.BoomLedgerCanisterId)) {
                case (#ok o) {
                  let newStakeInfo : TStaking.ICRCStake = {
                    staker = _staker;
                    tokenCanisterId = ENV.BoomLedgerCanisterId;
                    amount = _eliteStake;
                    kind = #elite;
                    stakedAt = Time.now();
                    dissolvedAt = 0;
                  };
                  _boomStakes := Trie.put(_boomStakes, Utils.keyT(_staker), Text.equal, newStakeInfo).0;
                };
                case (#err e) {
                  return #err("We could not verify $BOOM transfer for staking, please contact dev team in discord.");
                };
              };
            };
          };
        };
      };
    };
    // update stakes entity value
    switch (kind) {
      case (#pro) {
        switch (await createEntity({ uid = fromPrincipal; eid = "PRO:BoomStake"; fields = [{ fieldName = "quantity"; fieldValue = "1.0" }] })) {
          case (#ok _) {};
          case _ {
            return #err("BOOM tokens staked successfully but some error occured on granting stake entity, contact dev team in discord.");
          };
        };
        switch (await createEntity({ uid = fromPrincipal; eid = "ELITE:BoomStake"; fields = [{ fieldName = "quantity"; fieldValue = "0.0" }] })) {
          case (#ok _) {};
          case _ {
            return #err("BOOM tokens staked successfully but some error occured on granting stake entity, contact dev team in discord.");
          };
        };
        return #ok("BOOM tokens staked successfully.");
      };
      case (#elite) {
        switch (await createEntity({ uid = fromPrincipal; eid = "PRO:BoomStake"; fields = [{ fieldName = "quantity"; fieldValue = "0.0" }] })) {
          case (#ok _) {};
          case _ {
            return #err("BOOM tokens staked successfully but some error occured on granting stake entity, contact dev team in discord.");
          };
        };
        switch (await createEntity({ uid = fromPrincipal; eid = "ELITE:BoomStake"; fields = [{ fieldName = "quantity"; fieldValue = "1.0" }] })) {
          case (#ok _) {};
          case _ {
            return #err("BOOM tokens staked successfully but some error occured on granting stake entity, contact dev team in discord.");
          };
        };
        return #ok("BOOM tokens staked successfully.");
      };
    };
  };

  public shared ({ caller }) func dissolveBoomStake() : async (Result.Result<Text, Text>) {
    let user : Text = Principal.toText(caller);
    switch (Trie.find(_boomStakes, Utils.keyT(user), Text.equal)) {
      case (?stake) {
        var e : TStaking.ICRCStake = {
          staker = stake.staker;
          tokenCanisterId = stake.tokenCanisterId;
          amount = stake.amount;
          kind = stake.kind;
          stakedAt = stake.stakedAt;
          dissolvedAt = Time.now();
        };
        _boomStakes := Trie.put(_boomStakes, Utils.keyT(user), Text.equal, e).0;
        // update BOOM stake entity value when stake is already dissolved
        switch (await createEntity({ uid = user; eid = "PRO:BoomStake"; fields = [{ fieldName = "quantity"; fieldValue = "0.0" }] })) {
          case (#ok _) {};
          case _ {
            return #err("$BOOM dissolved successfully but some error occured, contact dev team in discord.");
          };
        };
        switch (await createEntity({ uid = user; eid = "ELITE:BoomStake"; fields = [{ fieldName = "quantity"; fieldValue = "0.0" }] })) {
          case (#ok _) {};
          case _ {
            return #err("$BOOM dissolved successfully but some error occured, contact dev team in discord.");
          };
        };
        return #ok("$BOOM Stakes dissolved, now wait for 24 Hours to disburse $BOOM to your account.");
      };
      case _ {
        return #err("You do not have any $BOOM staked at BOOM DAO.");
      };
    };
  };

  public shared ({ caller }) func disburseBOOMStake() : async Result.Result<Text, Text> {
    // transfer boom tokens back to user after checking time-period
    let delay : Int = 86400000000000;
    let user : Text = Principal.toText(caller);
    switch (Trie.find(_boomStakes, Utils.keyT(user), Text.equal)) {
      case (?stake) {
        if (stake.dissolvedAt != 0 and stake.dissolvedAt + delay <= Time.now()) {
          switch (await transferBoom_(user, stake.amount)) {
            case (#Ok _) {
              _boomStakes := Trie.remove(_boomStakes, Utils.keyT(user), Text.equal).0;
              return #ok("BOOM tokens transferred back successfully.");
            };
            case (#Err e) {
              return #err("some error occured while transferring BOOM tokens from BOOM DAO vault back to user, contact dev team in discord.");
            };
          };
        } else {
          return #err("unfortunately you can not disburse your BOOM tokens before 24hrs, after dissolving it.");
        };
      };
      case _ {
        return #err("You do not have BOOM tokens staked with BOOM DAO.");
      };
    };
  };

  public query func getUserBoomStakeInfo(uid : Text) : async Result.Result<TStaking.ICRCStake, Text> {
    let ?stake = Trie.find(_boomStakes, Utils.keyT(uid), Text.equal) else return #err("User has no BOOM token stakes at BOOM DAO.");
    return #ok(stake);
  };

  public query func getUserBoomStakeTier(uid : Text) : async (Result.Result<Text, Text>) {
    let ?stake = Trie.find(_boomStakes, Utils.keyT(uid), Text.equal) else return #err("User has no BOOM token stakes at BOOM DAO.");
    if (stake.dissolvedAt != 0) {
      return #err("User has already dissolved BOOM token stakes, Re-Stake BOOM tokens.");
    };
    switch (stake.kind) {
      case (#pro) {
        return #ok("PRO");
      };
      case (#elite) {
        return #ok("ELITE");
      };
    };
  };

  public query func getEliteStakeUsers() : async [Text] {
    var b = Buffer.Buffer<Text>(0);
    for ((i, v) in Trie.iter(_boomStakes)) {
      switch (v.kind) {
        case (#elite) {
          b.add(i);
        };
        case _ {};
      };
    };
    return Buffer.toArray(b);
  };

  public query func getProStakeUsers() : async [Text] {
    var b = Buffer.Buffer<Text>(0);
    for ((i, v) in Trie.iter(_boomStakes)) {
      switch (v.kind) {
        case (#pro) {
          b.add(i);
        };
        case _ {};
      };
    };
    return Buffer.toArray(b);
  };

  // NFT Staking for Gaming Guild
  private stable var _extStakes : Trie.Trie<Text, TStaking.EXTStake> = Trie.empty(); // key -> (collection_canister_id + "|" + nft_index)
  //EXT tx verification checks
  //1. Our StakingHubCanister owns the NFT
  //2. NFT is not already staked by someone else in our NFT vault
  private func queryExtTx_(collectionCanisterId : Text, nftIndex : Nat32, fromPrincipal : Text, toPrincipal : Text) : async (Result.Result<Text, Text>) {
    let EXT = actor (collectionCanisterId) : actor {
      getRegistry : shared () -> async [(Nat32, Text)];
    };
    var _registry : [(Nat32, Text)] = await EXT.getRegistry();
    for (i in _registry.vals()) {
      if (i.0 == nftIndex) {
        if (i.1 != AccountIdentifier.fromText(toPrincipal, null)) {
          return #err("BOOM Gaming Guild do not hold this NFT of index : " # Nat32.toText(nftIndex) # ", contact dev team in discord.");
        };
      };
    };
    var key : Text = collectionCanisterId # "|" #Nat32.toText(nftIndex);
    switch (Trie.find(_extStakes, Utils.keyT(key), Text.equal)) {
      case (?stake) {
        return #err("NFT already staked by someone, contact dev team in discord.");
      };
      case _ {
        return #ok("");
      };
    };
  };

  public shared ({ caller }) func stakeExtNft(index : Nat32, toPrincipal : Text, fromPrincipal : Text, collectionCanisterId : Text) : async (Result.Result<Text, Text>) {
    assert (Principal.fromText(fromPrincipal) == caller);
    assert (Principal.fromText(toPrincipal) == WorldId());
    switch (await queryExtTx_(collectionCanisterId, index, fromPrincipal, toPrincipal)) {
      case (#ok _) {
        let key = collectionCanisterId # "|" #Nat32.toText(index); //key = "canisterId" + "|" + "nftIndex"
        var e : TStaking.EXTStake = {
          staker = fromPrincipal;
          tokenIndex = index;
          stakedAt = Time.now();
          dissolvedAt = 0;
        };
        _extStakes := Trie.put(_extStakes, Utils.keyT(key), Text.equal, e).0;

        // update stakes entity value
        let entityId : Text = collectionCanisterId # ":NftStake";
        var quantityText : Text = "0.0";
        var fieldsBuffer = Buffer.Buffer<TGlobal.Field>(0);
        switch (await getUserNode_(fromPrincipal)) {
          case (#ok(userNodeId)) {
            let userNode : UserNode = actor (userNodeId);
            let entities = await userNode.getEntity(fromPrincipal, worldPrincipalId(), entityId);
            for (i in entities.fields.vals()) {
              if (i.fieldName == "quantity") {
                quantityText := i.fieldValue;
              } else {
                fieldsBuffer.add(i);
              };
            };
          };
          case (#err(errMsg)) {};
        };

        var quantity : Float = Utils.textToFloat(quantityText);
        quantity := Float.add(quantity, 1.0);
        fieldsBuffer.add({
          fieldName = "quantity";
          fieldValue = Float.toText(quantity);
        });

        switch (await createEntity({ uid = fromPrincipal; eid = entityId; fields = Buffer.toArray(fieldsBuffer) })) {
          case (#ok _) {
            return #ok("NFT staked successfully.");
          };
          case _ {
            return #err("NFT staked successfully but some error occured on Gaming Guilds backend, contact dev team in discord");
          };
        };
      };
      case (#err e) {
        return #err(e);
      };
    };
  };

  public shared ({ caller }) func dissolveExtNft(collectionCanisterId : Text, index : Nat32) : async (Result.Result<Text, Text>) {
    let _of : Text = Principal.toText(caller);
    let key : Text = collectionCanisterId # "|" #Nat32.toText(index);
    switch (Trie.find(_extStakes, Utils.keyT(key), Text.equal)) {
      case (?stake) {
        if (stake.staker != _of) {
          return #err("You are not authorized to dissolve this NFT stake, NFT was staked by someone else.");
        };
        var e : TStaking.EXTStake = {
          staker = stake.staker;
          tokenIndex = stake.tokenIndex;
          stakedAt = stake.stakedAt;
          dissolvedAt = Time.now();
        };
        _extStakes := Trie.put(_extStakes, Utils.keyT(key), Text.equal, e).0;
        // update stake entity value when NFT is already dissolved
        let entityId : Text = collectionCanisterId # ":NftStake";
        var quantityText : Text = "0.0";
        var fieldsBuffer = Buffer.Buffer<TGlobal.Field>(0);
        switch (await getUserNode_(_of)) {
          case (#ok(userNodeId)) {
            let userNode : UserNode = actor (userNodeId);
            let entities = await userNode.getEntity(_of, worldPrincipalId(), entityId);
            for (i in entities.fields.vals()) {
              if (i.fieldName == "quantity") {
                quantityText := i.fieldValue;
              } else {
                fieldsBuffer.add(i);
              };
            };
          };
          case (#err(errMsg)) {};
        };

        var quantity : Float = Utils.textToFloat(quantityText);
        quantity := Float.sub(quantity, 1.0);
        fieldsBuffer.add({
          fieldName = "quantity";
          fieldValue = Float.toText(Float.max(quantity, 0.0));
        });

        switch (await createEntity({ uid = _of; eid = entityId; fields = Buffer.toArray(fieldsBuffer) })) {
          case (#ok _) {
            return #ok("NFT dissolved successfully, now wait for 24Hrs to withdraw/disburse this NFT to your Wallet.");
          };
          case _ {
            return #err("NFT dissolved successfully but some error occured on Gaming Guild backend, report this to dev team in discord");
          };
        };
        return #ok("");
      };
      case _ {
        return #err("You do not have NFT of this collection staked");
      };
    };
  };

  public shared ({ caller }) func disburseExtNft(collectionCanisterId : Text, index : Nat32) : async Result.Result<Text, Text> {
    // transfer EXT NFT to user back after checking time-period
    let delay : Int = 86400000000000;
    let _of : Text = Principal.toText(caller);
    let key : Text = collectionCanisterId # "|" #Nat32.toText(index);
    switch (Trie.find(_extStakes, Utils.keyT(key), Text.equal)) {
      case (?stake) {
        if (stake.dissolvedAt != 0 and stake.dissolvedAt + delay <= Time.now()) {
          var _req : EXTCORE.TransferRequest = {
            from = #principal(WorldId());
            to = #principal(Principal.fromText(stake.staker));
            token = EXTCORE.TokenIdentifier.fromText(collectionCanisterId, index);
            amount = 1;
            memo = Text.encodeUtf8("BGG-NFT-Unlocking");
            notify = false;
            subaccount = null;
          };
          let EXT : Ledger.EXT = actor (collectionCanisterId);
          var res : EXTCORE.TransferResponse = await EXT.transfer(_req);
          switch (res) {
            case (#ok _) {
              _extStakes := Trie.remove(_extStakes, Utils.keyT(key), Text.equal).0;
              return #ok("NFT transferred back successfully.");
            };
            case _ {
              return #err("some error occured while transferring NFT from BGG NFT Vault back to User, contact dev team in discord");
            };
          };
        } else {
          return #err("unfortunately you can not disburse your NFT before 24hrs after dissolving it.");
        };
      };
      case _ {
        return #err("You do not have NFT of this collection staked with BGG");
      };
    };
  };

  public query func getTokenIndex(id : Text) : async (Nat32) {
    return EXTCORE.TokenIdentifier.getIndex(id);
  };

  public query func getUserSpecificExtStakes(arg : { uid : Text; collectionCanisterId : Text }) : async [Text] {
    var b = Buffer.Buffer<Text>(0);
    for ((i, v) in Trie.iter(_extStakes)) {
      if (v.staker == arg.uid) {
        let key = Iter.toArray(Text.tokens(i, #text("|")));
        if (key[0] == arg.collectionCanisterId) {
          b.add(key[1]);
        };
      };
    };
    return Buffer.toArray(b);
  };

  public query func getUserExtStakes(uid : Text) : async [(Text, Text)] {
    var b = Buffer.Buffer<(Text, Text)>(0);
    for ((i, v) in Trie.iter(_extStakes)) {
      if (v.staker == uid) {
        let key = Iter.toArray(Text.tokens(i, #text("|")));
        b.add((key[0], key[1]));
      };
    };
    return Buffer.toArray(b);
  };

  public query func getUserExtStakesInfo(uid : Text) : async [(Text, TStaking.EXTStake)] {
    var b = Buffer.Buffer<(Text, TStaking.EXTStake)>(0);
    for ((i, v) in Trie.iter(_extStakes)) {
      if (v.staker == uid) {
        b.add((i, v));
      };
    };
    return Buffer.toArray(b);
  };

  // DAU tracking for BGG Games
  private stable var _dau : Trie.Trie<Text, Nat> = Trie.empty();

  private func updateDauCount(uid : Text) : () {
    let ?x = Trie.find(_dau, Utils.keyT(uid), Text.equal) else {
      _dau := Trie.put(_dau, Utils.keyT(uid), Text.equal, 1).0;
      return ();
    };
  };

  public shared ({ caller }) func storeDauCount() : async (Nat) {
    assert (caller == Principal.fromText(ENV.AnalyticsCanisterId));
    let currentDAU = Trie.size(_dau);
    _dau := Trie.empty();
    return currentDAU;
  };

  public query func getCurrentDauCount() : async Nat {
    return Trie.size(_dau);
  };
};
