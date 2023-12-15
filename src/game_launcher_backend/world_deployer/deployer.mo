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
import ENV "../utils/Env";

actor Deployer {

  //Stable Memory
  private func deployer() : Principal = Principal.fromActor(Deployer);
  private stable var _worlds : Trie.Trie<Text, World> = Trie.empty(); //mapping of world_canister_id -> World details
  private stable var _covers : Trie.Trie<Text, Text> = Trie.empty(); //mapping of world_canister_id -> base64
  private stable var _owners : Trie.Trie<Text, Text> = Trie.empty(); //mapping  world_canister_id -> owner principal id
  private stable var _versions : Trie.Trie<Text, Text> = Trie.empty(); // mapping of world_canister_id -> world_wasm_version
  private stable var _admins : [Text] = [];

  let IC : Management.Management = actor ("aaaaa-aa"); //IC Management Canister

  //Types
  public type World = {
    name : Text;
    cover : Text;
    canister : Text;
  };
  public type Wasm = {
    version : Text;
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
    let canister = await World.WorldTemplate();
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
    let world = actor (Principal.toText(cid.canister_id)) : actor {
      updateOwnership : shared (Principal) -> async ();
    };
    await world.updateOwnership(init_owner);
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
      case (?c) {
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
        cover = "https://" #Principal.toText(deployer()) # ".raw.icp0.io/cover/" #canister_id;
      },
    ).0;
    _covers := Trie.put(_covers, Helper.keyT(canister_id), Text.equal, cover_encoding).0;
    _owners := Trie.put(_owners, Helper.keyT(canister_id), Text.equal, Principal.toText(msg.caller)).0;
    return canister_id;
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

  public shared (msg) func updateWorldName(canister_id : Text, _name : Text) : async (Result.Result<(), Text>) {
    assert ((await _isOwner(msg.caller, canister_id)) == true);
    switch (Trie.find(_worlds, Helper.keyT(canister_id), Text.equal)) {
      case (?world) {
        _worlds := Trie.put(
          _worlds,
          Helper.keyT(canister_id),
          Text.equal,
          {
            name = _name;
            canister = canister_id;
            cover = "https://" #Principal.toText(deployer()) # ".raw.icp0.io/cover/" #canister_id;
          },
        ).0;
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

  // custom SNS functions for upgrading World nodes which are under control of World Deployer Canister
  private stable var world_wasm_module = {
    version : Text = "";
    wasm : Blob = Blob.fromArray([]);
    last_updated : Int = 0;
  };

  public query func getWorldWasmVersion() : async (Text) {
    return world_wasm_module.version;
  };

  public shared ({ caller }) func updateWorldWasmModule(
    arg : {
      version : Text;
      wasm : Blob;
    }
  ) : async (Int) {
    assert (caller == Principal.fromText("2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe"));
    world_wasm_module := {
      version = arg.version;
      wasm = arg.wasm;
      last_updated = Time.now();
    };
    return world_wasm_module.last_updated;
  };

  public shared ({ caller }) func validate_upgrade_worlds(last_verified_update : Int) : async ({
    #Ok : Text;
    #Err : Text;
  }) {
    if (world_wasm_module.last_updated == last_verified_update) {
      return #Ok("last_verified_update passed");
    } else {
      return #Err("last_verified_update failed");
    };
  };

  public shared ({ caller }) func upgrade_worlds(last_verified_update : Int) : async () {
    assert (caller == Principal.fromText("xomae-vyaaa-aaaaq-aabhq-cai")); //Only SNS governance canister can call generic methods via proposal
    var worlds_and_owners = Buffer.Buffer<(Text, Text)>(0);
    for ((i, v) in Trie.iter(_worlds)) {
      switch (Trie.find(_owners, Helper.keyT(i), Text.equal)) {
        case (?owner) {
          worlds_and_owners.add((i, owner));
        };
        case _ {};
      };
    };
    for ((worldId, ownerId) in worlds_and_owners.vals()) {
      let IC : Management.Management = actor (ENV.IC_Management);
      let upgrade_bool = ?{
        skip_pre_upgrade = ?false;
      };
      let res = await IC.install_code({
        arg = Blob.fromArray([]);
        wasm_module = world_wasm_module.wasm;
        mode = #upgrade upgrade_bool;
        canister_id = Principal.fromText(worldId);
        sender_canister_version = null;
      });
      let world = actor (worldId) : actor {
        updateOwnership : shared (Principal) -> async ();
      };
      await world.updateOwnership(Principal.fromText(ownerId));
    };
  };

};
