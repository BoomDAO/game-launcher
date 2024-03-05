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

import Constants "../utils/Env";
import ICRC "../types/icrc.types";
import Helper "../utils/Helpers";
import Management "../types/management.types";

actor Deployer {

  //Stable Memory
  private func deployer() : Principal = Principal.fromActor(Deployer);
  private stable var _tokens : Trie.Trie<Text, Token> = Trie.empty(); //mapping of token_canister_id -> Token details
  private stable var _logos : Trie.Trie<Text, Text> = Trie.empty(); //mapping of token_canister_id -> base64
  private stable var _owners : Trie.Trie<Text, Text> = Trie.empty(); //mapping  token_canister_id -> owner principal id
  private stable var _admins : [Text] = [];
  private stable var _wasm_version_id : Nat32 = 0;
  private stable var _ledger_wasms : Trie.Trie<Nat32, [Nat8]> = Trie.empty(); // version_number -> icrc_ledger_wasm

  //Types
  //
  public type Token = {
    name : Text;
    symbol : Text;
    description : Text;
    canister : Text;
    cover : Text;
  };

  let IC : Management.Self = actor (Constants.IC_Management);

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

  private func _getLatestIcrcWasm() : (Blob) {
    if (_wasm_version_id == 0) {
      return Blob.fromArray([]);
    } else {
      let latest_available_wasm_version : Nat32 = _wasm_version_id - 1;
      let ?wasm = Trie.find(_ledger_wasms, Helper.key(latest_available_wasm_version), Nat32.equal) else {
        return Blob.fromArray([]);
      };
      return Blob.fromArray(wasm);
    };
  };

  //Queries
  //
  public query func cycleBalance() : async Nat {
    Cycles.balance();
  };

  public query func getAllAdmins() : async ([Text]) {
    return _admins;
  };

  public query func getOwner(canister_id : Text) : async (?Text) {
    var owner : ?Text = Trie.find(_owners, Helper.keyT(canister_id), Text.equal);
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
        switch (Trie.find(_tokens, Helper.keyT(i), Text.equal)) {
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
      switch (Trie.find(_tokens, Helper.keyT(i), Text.equal)) {
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
  public shared ({ caller }) func uploadLedgerWasm(arg : { ledger_wasm : [Nat8] }) : async () {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    _ledger_wasms := Trie.put(_ledger_wasms, Helper.key(_wasm_version_id), Nat32.equal, arg.ledger_wasm).0;
    _wasm_version_id := _wasm_version_id + 1;
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

  public shared ({ caller }) func createTokenCanister(_name : Text, _symbol : Text, _desc : Text, _amt : Nat, logo_encoding : Text, _decimals : Nat8, tx_fee : Nat) : async (Text) {
    Cycles.add(1000000000000);
    let res = await IC.create_canister({
      settings = ?{
        freezing_threshold = null;
        controllers = ?[deployer()];
        memory_allocation = null;
        compute_allocation = null;
      };
      sender_canister_version = null;
    });
    let canister_id = Principal.toText(res.canister_id);
    let init_arg : ICRC.InitArgs = {
      decimals = ?_decimals;
      token_symbol = _symbol;
      transfer_fee = tx_fee;
      metadata = [];
      minting_account = {
        owner = caller;
        subaccount = null;
      };
      initial_balances = [];
      maximum_number_of_accounts = null;
      accounts_overflow_trim_quantity = null;
      fee_collector_account = null;
      archive_options = {
        num_blocks_to_archive = 2000;
        max_transactions_per_response = null;
        trigger_threshold = 1000;
        max_message_size_bytes = null;
        cycles_for_archive_creation = null;
        node_max_memory_size_bytes = null;
        controller_id = deployer();
      };
      max_memo_length = null;
      token_name = _name;
      feature_flags = null;
    };
    let arg : {
      #Init : ICRC.InitArgs;
      #Upgrade : ?ICRC.UpgradeArgs;
    } = #Init init_arg;

    await IC.install_code({
      arg = to_candid (arg);
      wasm_module = _getLatestIcrcWasm();
      mode = #install;
      canister_id = res.canister_id;
      sender_canister_version = null;
    });
    _tokens := Trie.put(
      _tokens,
      Helper.keyT(canister_id),
      Text.equal,
      {
        name = _name;
        symbol = _symbol;
        description = _desc;
        canister = canister_id;
        cover = "https://" #Principal.toText(deployer()) # ".raw.icp0.io/logo/" #canister_id;
      },
    ).0;
    _logos := Trie.put(_logos, Helper.keyT(canister_id), Text.equal, logo_encoding).0;
    _owners := Trie.put(_owners, Helper.keyT(canister_id), Text.equal, Principal.toText(caller)).0;
    return canister_id;
  };

  //Queries
  public query func getTokenDetails(canister_id : Text) : async (?Token) {
    switch (Trie.find(_tokens, Helper.keyT(canister_id), Text.equal)) {
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
    switch (Trie.find(_owners, Helper.keyT(canister_id), Text.equal)) {
      case (?o) {
        assert (Principal.fromText(o) == msg.caller);
        _logos := Trie.put(_logos, Helper.keyT(canister_id), Text.equal, base64).0;
        return #ok();
      };
      case null {
        return #err("canister owner not found");
      };
    };
  };

  public query func http_request(req : Management.HttpRequest) : async (Management.HttpResponse) {
    let path = Iter.toArray(Text.tokens(req.url, #text("/")));
    let collection = path[1];
    switch (req.method, (path[0] == "logo")) {
      case ("GET", true) {
        switch (Trie.find(_logos, Helper.keyT(collection), Text.equal)) {
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
