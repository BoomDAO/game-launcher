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
import Float "mo:base/Float";
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

import Helper "../utils/Helpers";
import ENV "../utils/Env";
import Swap "../types/swap.types";
import ICRC "../types/icrc.types";
import Management "../types/management.types";
import ICP "../types/icp.types";
import AccountIdentifier "../utils/AccountIdentifier";
import Hex "../utils/Hex";

actor SwapCanister {

  // Stable memory
  private var dev_principal = Principal.fromText("2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe");
  private stable var _wasm_version_id : Nat32 = 0;
  private stable var _participant_id : Nat = 0;

  private stable var _ledger_wasms : Trie.Trie<Nat32, [Nat8]> = Trie.empty(); // version_number <-> icrc_ledger_wasm
  private stable var _tokens : Trie.Trie<Text, Swap.Token> = Trie.empty(); // token_canister_id <-> Token detail

  private stable var _swap_configs : Trie.Trie<Text, Swap.TokenSwapConfigs> = Trie.empty(); // token_canister_id <-> token_swap_details
  private stable var _swap_participants : Trie.Trie<Text, Trie.Trie<Text, Swap.ParticipantDetails>> = Trie.empty(); // token_canister_id <-> [participant_id <-> Participant details]
  private stable var _swap_status : Trie.Trie<Text, Swap.TokenSwapStatus> = Trie.empty(); // token_canister_id <-> True/False

  // actor interfaces
  let management_canister : Management.Self = actor (ENV.IC_Management);
  let icp_ledger : ICP.Self = actor (ENV.IcpLedgerCanisterId);

  // private methods
  private func getLatestIcrcWasm_() : (Blob) {
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

  private func getFormattedMetadata_(metadata : [(Text, ICRC.MetadataValue)]) : ({
    logo : Text;
    description : Text;
    url : Text;
  }) {
    var icrc_logo = "";
    var icrc_description = "";
    var icrc_url = "";
    for (i in metadata.vals()) {
      if (i.0 == "icrc:logo") {
        switch (i.1) {
          case (#Text logo) {
            icrc_logo := logo;
          };
          case _ {};
        };
      };
      if (i.0 == "icrc:description") {
        switch (i.1) {
          case (#Text desc) {
            icrc_description := desc;
          };
          case _ {};
        };
      };
      if (i.0 == "icrc:url") {
        switch (i.1) {
          case (#Text url) {
            icrc_url := url;
          };
          case _ {};
        };
      };
    };
    return ({
      logo = icrc_logo;
      description = icrc_description;
      url = icrc_url;
    });
  };

  private func isTokenSwapRunning_(arg : { canister_id : Text }) : Bool {
    switch (Trie.find(_swap_status, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?status) {
        return status.running;
      };
      case _ {
        return false;
      };
    };
  };

  private func isAmountValid_(arg : { canister_id : Text; amount : Nat64 }) : Bool {
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        if (arg.amount >= configs.min_participant_icp_e8s and arg.amount <= configs.max_participant_icp_e8s) {
          return true;
        } else {
          return false;
        };
      };
      case _ {
        return false;
      };
    };
  };

  private func queryIcpTx_(blockIndex : Nat64, toPrincipal : Text, fromPrincipal : Text, amt : ICP.Tokens) : async (Result.Result<Text, Text>) {
    var req : ICP.GetBlocksArgs = {
      start = blockIndex;
      length = 1;
    };
    let ICP_Ledger : ICP.Self = actor (ENV.IcpLedgerCanisterId);
    var res : ICP.QueryBlocksResponse = await ICP_Ledger.query_blocks(req);
    var toAccountId : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(toPrincipal, null);
    var fromAccountId : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(fromPrincipal, null);

    var blocks : [ICP.Block] = res.blocks;
    var base_block : ICP.Block = blocks[0];
    var tx : ICP.Transaction = base_block.transaction;
    var op : ?ICP.Operation = tx.operation;
    switch (op) {
      case (?op) {
        switch (op) {
          case (#Transfer { to; fee; from; amount }) {
            if (Hex.encode(Blob.toArray(to)) == toAccountId and Hex.encode(Blob.toArray(from)) == fromAccountId and amount == amt) {
              return #ok("verified");
            } else {
              return #err("invalid tx");
            };
          };
          case (#Burn {}) {
            return #err("burn tx");
          };
          case (#Mint {}) {
            return #err("mint tx");
          };
          case (#Approve _) {
            return #err("approve tx");
          };
        };
      };
      case _ {
        return #err("invalid tx");
      };
    };

    return #ok("");
  };

  private func error_refund_icp(arg : { canister_id : Text }) : async () {
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?participants) {
        for ((principal, info) in Trie.iter(participants)) {
          let req : ICP.TransferArg = {
            to = info.account;
            fee = ?10000;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = Nat64.toNat(info.icp_e8s);
          };
          let res : ICP.Icrc1TransferResult = await icp_ledger.icrc1_transfer(req);
          switch (res) {
            case (#Ok index) {
              let p_details : Swap.ParticipantDetails = {
                account = info.account;
                icp_e8s = 0;
                token_e8s = null;
                refund_result = ?res;
                mint_result = null;
              };
              _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
            };
            case (#Err e) {
              let p_details : Swap.ParticipantDetails = {
                account = info.account;
                icp_e8s = info.icp_e8s;
                token_e8s = null;
                refund_result = ?res;
                mint_result = null;
              };
              _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
            };
          };
        };
      };
      case _ {};
    };
  };

  private func success_mint_tokens(arg : { canister_id : Text }) : async () {
    //TODO: might need a fix at passing token_fee correctly
    let icrc_ledger : ICRC.Self = actor (arg.canister_id);

    // mint tokens to participants
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?participants) {
        for ((principal, info) in Trie.iter(participants)) {
          let token_amount = Option.get(info.token_e8s, 0);
          let req : ICRC.TransferArg = {
            to = info.account;
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = token_amount;
          };
          let res : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(req);
          switch (res) {
            case (#Ok index) {
              let p_details : Swap.ParticipantDetails = {
                account = info.account;
                icp_e8s = info.icp_e8s;
                token_e8s = info.token_e8s;
                refund_result = null;
                mint_result = ?res;
              };
              _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
            };
            case (#Err e) {
              let p_details : Swap.ParticipantDetails = {
                account = info.account;
                icp_e8s = info.icp_e8s;
                token_e8s = info.token_e8s;
                refund_result = null;
                mint_result = ?res;
              };
              _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
            };
          };
        };
      };
      case _ {};
    };

    // mint icrc-tokens and send icp to supply receivers
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        // guilds transfer
        var icp_req : ICP.TransferArg = {
          to = configs.token_supply_configs.gaming_guilds.account;
          fee = ?10000;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = Nat64.toNat(configs.token_supply_configs.gaming_guilds.icp);
        };
        var icrc_req : ICRC.TransferArg = {
          to = configs.token_supply_configs.gaming_guilds.account;
          fee = null;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = configs.token_supply_configs.gaming_guilds.icrc;
        };
        let icp_res_guilds : ICP.Icrc1TransferResult = await icp_ledger.icrc1_transfer(icp_req);
        let icrc_res_guilds : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

        // team transfer
        icp_req := {
          to = configs.token_supply_configs.team.account;
          fee = ?10000;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = Nat64.toNat(configs.token_supply_configs.team.icp);
        };
        icrc_req := {
          to = configs.token_supply_configs.team.account;
          fee = null;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = configs.token_supply_configs.team.icrc;
        };
        let icp_res_team : ICP.Icrc1TransferResult = await icp_ledger.icrc1_transfer(icp_req);
        let icrc_res_team : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

        // lp transfer
        icp_req := {
          to = configs.token_supply_configs.liquidity_pool.account;
          fee = ?10000;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = Nat64.toNat(configs.token_supply_configs.liquidity_pool.icp);
        };
        icrc_req := {
          to = configs.token_supply_configs.liquidity_pool.account;
          fee = null;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = configs.token_supply_configs.liquidity_pool.icrc;
        };
        let icp_res_liquidity_pool : ICP.Icrc1TransferResult = await icp_ledger.icrc1_transfer(icp_req);
        let icrc_res_liquidity_pool : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

        // boom dao treasury transfer
        let icp_req_boom_dao : ICP.TransferArgs = {
          to = Text.encodeUtf8(configs.token_supply_configs.boom_dao.icp_account);
          fee = {
            e8s = 10000;
          };
          memo = 0;
          from_subaccount = null;
          created_at_time = null;
          amount = {
            e8s = configs.token_supply_configs.boom_dao.icp;
          };
        };
        icrc_req := {
          to = configs.token_supply_configs.boom_dao.icrc_account;
          fee = null;
          memo = null;
          from_subaccount = null;
          created_at_time = null;
          amount = configs.token_supply_configs.boom_dao.icrc;
        };
        let icp_res_boom_dao : ICP.TransferResult = await icp_ledger.transfer(icp_req_boom_dao);
        let icrc_res_boom_dao : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

        let configs_with_transfer_results : Swap.TokenSwapConfigs = {
          token_supply_configs = {
            gaming_guilds = {
              account = configs.token_supply_configs.gaming_guilds.account;
              icp = configs.token_supply_configs.gaming_guilds.icp;
              icrc = configs.token_supply_configs.gaming_guilds.icrc;
              icp_result = ?icp_res_guilds;
              icrc_result = ?icrc_res_guilds;
            };
            participants = {
              icrc = configs.token_supply_configs.participants.icrc;
            };
            team = {
              account = configs.token_supply_configs.team.account;
              icp = configs.token_supply_configs.team.icp;
              icrc = configs.token_supply_configs.team.icrc;
              icp_result = ?icp_res_team;
              icrc_result = ?icrc_res_team;
            };
            boom_dao = {
              icp_account = configs.token_supply_configs.boom_dao.icp_account;
              icrc_account = configs.token_supply_configs.boom_dao.icrc_account;
              icp = configs.token_supply_configs.boom_dao.icp;
              icrc = configs.token_supply_configs.boom_dao.icrc;
              icp_result = ?icp_res_boom_dao;
              icrc_result = ?icrc_res_boom_dao;
            };
            liquidity_pool = {
              account = configs.token_supply_configs.liquidity_pool.account;
              icp = configs.token_supply_configs.liquidity_pool.icp;
              icrc = configs.token_supply_configs.liquidity_pool.icrc;
              icp_result = ?icp_res_liquidity_pool;
              icrc_result = ?icrc_res_liquidity_pool;
            };
          };
          min_icp_e8s = configs.min_icp_e8s;
          max_icp_e8s = configs.max_icp_e8s;
          min_participant_icp_e8s = configs.min_participant_icp_e8s;
          max_participant_icp_e8s = configs.max_participant_icp_e8s;
          swap_start_timestamp_seconds = configs.swap_start_timestamp_seconds;
          swap_due_timestamp_seconds = configs.swap_due_timestamp_seconds;
        };
        _swap_configs := Trie.put(_swap_configs, Helper.keyT(arg.canister_id), Text.equal, configs_with_transfer_results).0;
      };
      case _ {};
    };

  };

  // query methods
  public query func total_icp_contributed_e8s(arg : { canister_id : Text }) : async (Nat64) {
    var total_icp : Nat64 = 0;
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?participants) {
        for ((participant_id, info) in Trie.iter(participants)) {
          total_icp := total_icp + info.icp_e8s;
        };
        return total_icp;
      };
      case _ {
        return 0;
      };
    };
  };

  // Update methods
  public shared ({ caller }) func upload_ledger_wasm(arg : { ledger_wasm : [Nat8] }) : async () {
    // assert (caller == dev_principal);
    _ledger_wasms := Trie.put(_ledger_wasms, Helper.key(_wasm_version_id), Nat32.equal, arg.ledger_wasm).0;
    _wasm_version_id := _wasm_version_id + 1;
  };

  public shared ({ caller }) func create_icrc_token(init_arg : ICRC.InitArgs) : async ({
    canister_id : Text;
  }) {
    // assert (caller == dev_principal);
    let res = await management_canister.create_canister({
      settings = ?{
        freezing_threshold = null;
        controllers = ?[dev_principal, Principal.fromActor(SwapCanister)];
        memory_allocation = null;
        compute_allocation = null;
      };
      sender_canister_version = ?Nat64.fromNat32(_wasm_version_id);
    });

    let canister_id = res.canister_id;
    let arg : {
      #Init : ICRC.InitArgs;
      #Upgrade : ?ICRC.UpgradeArgs;
    } = #Init init_arg;
    await management_canister.install_code({
      arg = to_candid (arg);
      wasm_module = getLatestIcrcWasm_();
      mode = #install;
      canister_id = canister_id;
      sender_canister_version = ?Nat64.fromNat32(_wasm_version_id);
    });
    let metadata = getFormattedMetadata_(init_arg.metadata);
    let token : Swap.Token = {
      name = init_arg.token_name;
      url = metadata.url;
      logo = metadata.logo;
      description = metadata.description;
      symbol = init_arg.token_symbol;
      decimals = init_arg.decimals;
      fee = init_arg.transfer_fee;
      token_canister_id = Principal.toText(canister_id);
    };
    _tokens := Trie.put(_tokens, Helper.keyT(Principal.toText(canister_id)), Text.equal, token).0;
    return { canister_id = Principal.toText(canister_id) };
  };

  public shared ({ caller }) func set_token_swap_configs(arg : { configs : Swap.TokenSwapConfigs; canister_id : Text }) : async (Result.Result<Swap.TokenSwapConfigs, Text>) {
    // assert (caller == dev_principal);
    switch (Trie.find(_tokens, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?_) {
        _swap_configs := Trie.put(_swap_configs, Helper.keyT(arg.canister_id), Text.equal, arg.configs).0;
        return #ok(arg.configs);
      };
      case _ {
        return #err("token not authorised to token swap via BOOM DAO.");
      };
    };
  };

  public shared ({ caller }) func start_token_swap(arg : { canister_id : Text }) : async (Result.Result<Text, Text>) {
    for ((i, v) in Trie.iter(_swap_status)) {
      if (v.running == true and i != arg.canister_id) {
        return #err("Other token swap is already running, wait for it to get over Or contact dev team.");
      } else if (v.running == true and i == arg.canister_id) {
        return #err("Token swap already running.");
      };
    };
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        let current_time_in_seconds : Int = Time.now() / 1000000000;
        if (configs.swap_start_timestamp_seconds <= current_time_in_seconds and current_time_in_seconds <= (configs.swap_due_timestamp_seconds + configs.swap_start_timestamp_seconds)) {
          _swap_status := Trie.put(
            _swap_status,
            Helper.keyT(arg.canister_id),
            Text.equal,
            {
              running = true;
              is_successfull = null;
            },
          ).0;
          return #ok("token swap started.");
        } else {
          return #err("start token swap according to settled configurations please.");
        };
      };
      case _ {
        return #err("configs not found");
      };
    };
  };

  // Checks :
  // 1. Is Swap Running?
  // 2. Is ICP BlockIndex Legit?
  // 3. Is Amount specified is matching SwapConfigs?
  public shared ({ caller }) func participate_in_token_swap(arg : { canister_id : Text; amount : ICP.Tokens; blockIndex : Nat64 }) : async (Result.Result<Text, Text>) {
    if (isTokenSwapRunning_({ canister_id = arg.canister_id }) == false) {
      return #err("token swap is not yet started or ended already.");
    }; // Check-1
    if (isAmountValid_({ canister_id = arg.canister_id; amount = arg.amount.e8s }) == false) {
      return #err("amount passed does not fullfill participants requirements of min/max ICP.");
    }; // Check-2
    let swap_canister_id : Text = Principal.toText(Principal.fromActor(SwapCanister));
    let participant_id : Text = Principal.toText(caller);
    switch (await queryIcpTx_(arg.blockIndex, swap_canister_id, participant_id, arg.amount)) {
      // Check-2
      case (#ok _) {
        switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
          case (?participants) {
            switch (Trie.find(participants, Helper.keyT(participant_id), Text.equal)) {
              case (?info) {
                _swap_participants := Trie.put2D(
                  _swap_participants,
                  Helper.keyT(arg.canister_id),
                  Text.equal,
                  Helper.keyT(participant_id),
                  Text.equal,
                  {
                    account = {
                      owner = caller;
                      subaccount = null;
                    };
                    icp_e8s = info.icp_e8s + arg.amount.e8s;
                    token_e8s = null;
                    refund_result = null;
                    mint_result = null;
                  },
                );
                return #ok("");
              };
              case _ {
                _swap_participants := Trie.put2D(
                  _swap_participants,
                  Helper.keyT(arg.canister_id),
                  Text.equal,
                  Helper.keyT(participant_id),
                  Text.equal,
                  {
                    account = {
                      owner = caller;
                      subaccount = null;
                    };
                    icp_e8s = arg.amount.e8s;
                    token_e8s = null;
                    refund_result = null;
                    mint_result = null;
                  },
                );
                return #ok("");
              };
            };
          };
          case _ {
            _swap_participants := Trie.put2D(
              _swap_participants,
              Helper.keyT(arg.canister_id),
              Text.equal,
              Helper.keyT(participant_id),
              Text.equal,
              {
                account = {
                  owner = caller;
                  subaccount = null;
                };
                icp_e8s = arg.amount.e8s;
                token_e8s = null;
                refund_result = null;
                mint_result = null;
              },
            );
            return #ok("");
          };
        };
      };
      case (#err e) {
        return #err(e);
      };
    };
  };

  // Checks :
  // 1. Sale timestamp is it over or not?
  // 2. total_icp reached the goal?
  public shared ({ caller }) func settle_swap_status_and_allocate_tokens_if_swap_successfull(arg : { canister_id : Text }) : async (Result.Result<Text, Text>) {
    // assert (caller == dev_principal);
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        let current_time_in_seconds = Time.now() / 1000000000;
        if ((configs.swap_due_timestamp_seconds + configs.swap_start_timestamp_seconds) > current_time_in_seconds) {
          return #err("token swap is still running.");
        };
      };
      case _ {
        return #err("token is not registered with BOOM DAO.");
      };
    };

    // Test Float and Nat64 conversion
    let total_icp_e8s : Nat64 = await total_icp_contributed_e8s({
      canister_id = arg.canister_id;
    });
    let total_icp_float : Float = Helper.nat64ToFloat(total_icp_e8s) / 100000000.0;
    var participants : Trie.Trie<Text, Swap.ParticipantDetails> = Trie.empty();
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?par) {
        participants := par;
      };
      case _ {};
    };
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        if (configs.min_icp_e8s >= total_icp_e8s and configs.max_icp_e8s <= total_icp_e8s) {
          let total_participants_tokens_float : Float = Helper.nat64ToFloat(Nat64.fromNat(configs.token_supply_configs.participants.icrc)) / 100000000.0;
          for ((id, info) in Trie.iter(participants)) {
            var tokens_amount_float : Float = ((Helper.nat64ToFloat(info.icp_e8s) * total_participants_tokens_float) / total_icp_float);
            tokens_amount_float := tokens_amount_float * 100000000.0;
            let tokens_amount : Int = Float.toInt(tokens_amount_float);
            let p_details : Swap.ParticipantDetails = {
              account = info.account;
              icp_e8s = info.icp_e8s;
              token_e8s = ?Helper.intToNat(tokens_amount);
              refund_result = null;
              mint_result = null;
            };
            _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(id), Text.equal, p_details);
          };
          _swap_status := Trie.put(
            _swap_status,
            Helper.keyT(arg.canister_id),
            Text.equal,
            {
              running = false;
              is_successfull = ?true;
            },
          ).0;
          return #ok("token swap successfull, tokens_e8s allocated to participants.");
        } else {
          _swap_status := Trie.put(
            _swap_status,
            Helper.keyT(arg.canister_id),
            Text.equal,
            {
              running = false;
              is_successfull = ?false;
            },
          ).0;
          return #ok("token swap failed, icp will be refunded to participants.");
        };
      };
      case _ {
        return #err("swap configs not found.");
      };
    };
  };

  public shared ({ caller }) func finalise_token_swap(arg : { canister_id : Text }) : async (Result.Result<Text, Text>) {
    // assert (caller == dev_principal);
    switch (Trie.find(_swap_status, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?status) {
        let ?is_successfull = status.is_successfull else {
          if (status.running) {
            return #err("token swap still running.");
          } else {
            return #err("token swap stopped, but status not found.");
          };
        };
        if (is_successfull) {
          await success_mint_tokens(arg);
          return #ok("token swap success, minted tokens.");
        } else {
          await error_refund_icp(arg);
          return #ok("token swap failed, refunded icp.");
        };
      };
      case _ {
        return #err("token swap status not found.");
      };
    };
  };

  public query func getAllTokenDetails() : async [(Text, Swap.Token)] {
    var b = Buffer.Buffer<(Text, Swap.Token)>(0);
    for ((i, v) in Trie.iter(_tokens)) {
      b.add((i, v));
    };
    return Buffer.toArray(b);
  };

  public query func getLedgerWasmDetails() : async [(Nat32, [Nat8])] {
    var b = Buffer.Buffer<(Nat32, [Nat8])>(0);
    for ((i, v) in Trie.iter(_ledger_wasms)) {
      b.add((i, v));
    };
    return Buffer.toArray(b);
  };

  public query func getTotalLedgerWasms() : async (Nat) {
    return Trie.size(_ledger_wasms);
  };

  public shared ({caller}) func removeLedgerWasmVersion(arg : {version : Nat32}) : async () {
    _ledger_wasms := Trie.remove(_ledger_wasms, Helper.key(arg.version), Nat32.equal).0;
  };

};