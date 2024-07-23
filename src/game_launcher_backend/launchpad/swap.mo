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
  private stable var _projects : Trie.Trie<Text, Swap.TokenProject> = Trie.empty(); // // token_canister_id <-> Token Project detail

  private stable var _swap_configs : Trie.Trie<Text, Swap.TokenSwapConfigs> = Trie.empty(); // token_canister_id <-> token_swap_details
  private stable var _swap_participants : Trie.Trie<Text, Trie.Trie<Text, Swap.ParticipantDetails>> = Trie.empty(); // token_canister_id <-> [participant_id <-> Participant details]
  private stable var _swap_status : Trie.Trie<Text, Swap.TokenSwapStatus> = Trie.empty(); // token_canister_id <-> True/False

  public func updateSwapConfig(cid : Text, due_timestamp_seconds : Int, start : ?Int) : async () {
    let ?configs = Trie.find(_swap_configs, Helper.keyT(cid), Text.equal) else return ();
    _swap_configs := Trie.put(
      _swap_configs,
      Helper.keyT(cid),
      Text.equal,
      {
        token_supply_configs = configs.token_supply_configs;
        min_token_e8s = configs.min_token_e8s;
        max_token_e8s = configs.max_token_e8s;
        min_participant_token_e8s = configs.min_participant_token_e8s;
        max_participant_token_e8s = configs.max_participant_token_e8s;
        swap_start_timestamp_seconds = Option.get(start, configs.swap_start_timestamp_seconds);
        swap_due_timestamp_seconds = due_timestamp_seconds;
        swap_type = configs.swap_type;
      },
    ).0;

    _swap_status := Trie.put(
      _swap_status,
      Helper.keyT(cid),
      Text.equal,
      {
        running = false;
        is_successfull = null;
      },
    ).0;
  };

  // actor interfaces
  let management_canister : Management.Self = actor (ENV.IC_Management);
  let icp_ledger : ICP.Self = actor (ENV.IcpLedgerCanisterId);
  let boom_ledger : ICRC.Self = actor (ENV.BoomLedgerCanisterId);

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
        if (arg.amount >= configs.min_participant_token_e8s and arg.amount <= configs.max_participant_token_e8s) {
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

  //ICRC1 Ledger Canister Query to verify ICRC-1 tx blockIndex
  //NOTE : Do Not Forget to change tokenCanisterId to query correct ICRC-1 Ledger
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

  private func error_refund_token(arg : { canister_id : Text }) : async () {
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
          case (?participants) {
            switch (configs.swap_type) {
              case (#icp) {
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
                        icp_e8s = info.icp_e8s;
                        boom_e8s = info.boom_e8s;
                        token_e8s = null;
                        icp_refund_result = ?res;
                        boom_refund_result = null;
                        mint_result = null;
                      };
                      _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
                    };
                    case (#Err e) {
                      let p_details : Swap.ParticipantDetails = {
                        account = info.account;
                        icp_e8s = info.icp_e8s;
                        boom_e8s = info.boom_e8s;
                        token_e8s = null;
                        icp_refund_result = ?res;
                        boom_refund_result = null;
                        mint_result = null;
                      };
                      _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
                    };
                  };
                };
              };
              case (#boom) {
                for ((principal, info) in Trie.iter(participants)) {
                  let req : ICRC.TransferArg = {
                    to = info.account;
                    fee = ?100000;
                    memo = null;
                    from_subaccount = null;
                    created_at_time = null;
                    amount = info.boom_e8s;
                  };
                  let res : ICRC.TransferResult = await boom_ledger.icrc1_transfer(req);
                  switch (res) {
                    case (#Ok index) {
                      let p_details : Swap.ParticipantDetails = {
                        account = info.account;
                        icp_e8s = info.icp_e8s;
                        boom_e8s = info.boom_e8s;
                        token_e8s = null;
                        icp_refund_result = null;
                        boom_refund_result = ?res;
                        mint_result = null;
                      };
                      _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
                    };
                    case (#Err e) {
                      let p_details : Swap.ParticipantDetails = {
                        account = info.account;
                        icp_e8s = info.icp_e8s;
                        boom_e8s = info.boom_e8s;
                        token_e8s = null;
                        icp_refund_result = null;
                        boom_refund_result = ?res;
                        mint_result = null;
                      };
                      _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
                    };
                  };
                };
              };
            };
          };
          case _ {};
        };
      };
      case _ {};
    };
  };

  private func success_mint_tokens(arg : { canister_id : Text }) : async () {
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
                boom_e8s = info.boom_e8s;
                token_e8s = info.token_e8s;
                icp_refund_result = null;
                boom_refund_result = null;
                mint_result = ?res;
              };
              _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
            };
            case (#Err e) {
              let p_details : Swap.ParticipantDetails = {
                account = info.account;
                icp_e8s = info.icp_e8s;
                boom_e8s = info.boom_e8s;
                token_e8s = info.token_e8s;
                refund_result = null;
                icp_refund_result = null;
                boom_refund_result = null;
                mint_result = ?res;
              };
              _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(Principal.toText(info.account.owner)), Text.equal, p_details);
            };
          };
        };
      };
      case _ {};
    };

    // allocate icrc-tokens and send token (icp/boom) to partners according to supply-configs
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {

        switch (configs.swap_type) {
          case (#icp) {
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
            let icp_req_boom_dao_treasury : ICP.TransferArgs = {
              to = Blob.fromArray(Hex.decode(configs.token_supply_configs.boom_dao_treasury.icp_account));
              fee = {
                e8s = 10000;
              };
              memo = 0;
              from_subaccount = null;
              created_at_time = null;
              amount = {
                e8s = configs.token_supply_configs.boom_dao_treasury.icp;
              };
            };
            icrc_req := {
              to = configs.token_supply_configs.boom_dao_treasury.icrc_account;
              fee = null;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.boom_dao_treasury.icrc;
            };
            let icp_res_boom_dao : ICP.TransferResult = await icp_ledger.transfer(icp_req_boom_dao_treasury);
            let icrc_res_boom_dao : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

            // others - transfer (if present)
            var other_config_with_transfer_result : ?{
              account : Swap.Account;
              icp : Nat64;
              boom : Nat;
              icrc : Nat;
              icp_result : ?ICP.Icrc1TransferResult;
              boom_result : ?ICRC.TransferResult;
              icrc_result : ?ICRC.TransferResult;
            } = null;
            switch (configs.token_supply_configs.other) {
              case (?other_info) {
                icp_req := {
                  to = other_info.account;
                  fee = ?10000;
                  memo = null;
                  from_subaccount = null;
                  created_at_time = null;
                  amount = Nat64.toNat(other_info.icp);
                };
                icrc_req := {
                  to = other_info.account;
                  fee = null;
                  memo = null;
                  from_subaccount = null;
                  created_at_time = null;
                  amount = other_info.icrc;
                };
                let icp_res_other : ICP.Icrc1TransferResult = await icp_ledger.icrc1_transfer(icp_req);
                let icrc_res_other : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

                other_config_with_transfer_result := ?{
                  account = other_info.account;
                  icp = other_info.icp;
                  boom = other_info.boom;
                  icrc = other_info.icrc;
                  icp_result = ?icp_res_other;
                  boom_result = null;
                  icrc_result = ?icrc_res_other;
                };
              };
              case _ {}; // ignored
            };

            let configs_with_transfer_results : Swap.TokenSwapConfigs = {
              token_supply_configs = {
                gaming_guilds = {
                  account = configs.token_supply_configs.gaming_guilds.account;
                  icp = configs.token_supply_configs.gaming_guilds.icp;
                  boom = configs.token_supply_configs.gaming_guilds.boom;
                  icrc = configs.token_supply_configs.gaming_guilds.icrc;
                  icp_result = ?icp_res_guilds;
                  boom_result = null;
                  icrc_result = ?icrc_res_guilds;
                };
                participants = {
                  icrc = configs.token_supply_configs.participants.icrc;
                };
                team = {
                  account = configs.token_supply_configs.team.account;
                  icp = configs.token_supply_configs.team.icp;
                  boom = configs.token_supply_configs.team.boom;
                  icrc = configs.token_supply_configs.team.icrc;
                  icp_result = ?icp_res_team;
                  boom_result = null;
                  icrc_result = ?icrc_res_team;
                };
                boom_dao_treasury = {
                  icp_account = configs.token_supply_configs.boom_dao_treasury.icp_account;
                  icrc_account = configs.token_supply_configs.boom_dao_treasury.icrc_account;
                  icp = configs.token_supply_configs.boom_dao_treasury.icp;
                  boom = configs.token_supply_configs.boom_dao_treasury.boom;
                  icrc = configs.token_supply_configs.boom_dao_treasury.icrc;
                  icp_result = ?icp_res_boom_dao;
                  boom_result = null;
                  icrc_result = ?icrc_res_boom_dao;
                };
                liquidity_pool = {
                  account = configs.token_supply_configs.liquidity_pool.account;
                  icp = configs.token_supply_configs.liquidity_pool.icp;
                  boom = configs.token_supply_configs.liquidity_pool.boom;
                  icrc = configs.token_supply_configs.liquidity_pool.icrc;
                  icp_result = ?icp_res_liquidity_pool;
                  boom_result = null;
                  icrc_result = ?icrc_res_liquidity_pool;
                };
                other = other_config_with_transfer_result;
              };
              min_token_e8s = configs.min_token_e8s;
              max_token_e8s = configs.max_token_e8s;
              min_participant_token_e8s = configs.min_participant_token_e8s;
              max_participant_token_e8s = configs.max_participant_token_e8s;
              swap_start_timestamp_seconds = configs.swap_start_timestamp_seconds;
              swap_due_timestamp_seconds = configs.swap_due_timestamp_seconds;
              swap_type = #icp;
            };
            _swap_configs := Trie.put(_swap_configs, Helper.keyT(arg.canister_id), Text.equal, configs_with_transfer_results).0;
          };
          case (#boom) {
            // guilds transfer
            var boom_req : ICRC.TransferArg = {
              to = configs.token_supply_configs.gaming_guilds.account;
              fee = ?100000;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.gaming_guilds.boom;
            };
            var icrc_req : ICRC.TransferArg = {
              to = configs.token_supply_configs.gaming_guilds.account;
              fee = null;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.gaming_guilds.icrc;
            };
            let boom_res_guilds : ICRC.TransferResult = await boom_ledger.icrc1_transfer(boom_req);
            let icrc_res_guilds : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

            // team transfer
            boom_req := {
              to = configs.token_supply_configs.team.account;
              fee = ?100000;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.team.boom;
            };
            icrc_req := {
              to = configs.token_supply_configs.team.account;
              fee = null;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.team.icrc;
            };
            let boom_res_team : ICRC.TransferResult = await boom_ledger.icrc1_transfer(boom_req);
            let icrc_res_team : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

            // lp transfer
            boom_req := {
              to = configs.token_supply_configs.liquidity_pool.account;
              fee = ?100000;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.liquidity_pool.boom;
            };
            icrc_req := {
              to = configs.token_supply_configs.liquidity_pool.account;
              fee = null;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.liquidity_pool.icrc;
            };
            let boom_res_liquidity_pool : ICRC.TransferResult = await boom_ledger.icrc1_transfer(boom_req);
            let icrc_res_liquidity_pool : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

            // boom dao treasury transfer
            boom_req := {
              to = configs.token_supply_configs.boom_dao_treasury.icrc_account;
              fee = ?100000;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.boom_dao_treasury.boom;
            };
            icrc_req := {
              to = configs.token_supply_configs.boom_dao_treasury.icrc_account;
              fee = null;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = configs.token_supply_configs.boom_dao_treasury.icrc;
            };
            let boom_res_boom_dao : ICRC.TransferResult = await boom_ledger.icrc1_transfer(boom_req);
            let icrc_res_boom_dao : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

            // others - transfer (if present)
            var other_config_with_transfer_result : ?{
              account : Swap.Account;
              icp : Nat64;
              boom : Nat;
              icrc : Nat;
              icp_result : ?ICP.Icrc1TransferResult;
              boom_result : ?ICRC.TransferResult;
              icrc_result : ?ICRC.TransferResult;
            } = null;
            switch (configs.token_supply_configs.other) {
              case (?other_info) {
                boom_req := {
                  to = other_info.account;
                  fee = ?100000;
                  memo = null;
                  from_subaccount = null;
                  created_at_time = null;
                  amount = other_info.boom;
                };
                icrc_req := {
                  to = other_info.account;
                  fee = null;
                  memo = null;
                  from_subaccount = null;
                  created_at_time = null;
                  amount = other_info.icrc;
                };
                let boom_res_other : ICRC.TransferResult = await boom_ledger.icrc1_transfer(boom_req);
                let icrc_res_other : ICRC.TransferResult = await icrc_ledger.icrc1_transfer(icrc_req);

                other_config_with_transfer_result := ?{
                  account = other_info.account;
                  icp = other_info.icp;
                  boom = other_info.boom;
                  icrc = other_info.icrc;
                  icp_result = null;
                  boom_result = ?boom_res_other;
                  icrc_result = ?icrc_res_other;
                };
              };
              case _ {}; // ignored
            };

            let configs_with_transfer_results : Swap.TokenSwapConfigs = {
              token_supply_configs = {
                gaming_guilds = {
                  account = configs.token_supply_configs.gaming_guilds.account;
                  icp = configs.token_supply_configs.gaming_guilds.icp;
                  boom = configs.token_supply_configs.gaming_guilds.boom;
                  icrc = configs.token_supply_configs.gaming_guilds.icrc;
                  icp_result = null;
                  boom_result = ?boom_res_guilds;
                  icrc_result = ?icrc_res_guilds;
                };
                participants = {
                  icrc = configs.token_supply_configs.participants.icrc;
                };
                team = {
                  account = configs.token_supply_configs.team.account;
                  icp = configs.token_supply_configs.team.icp;
                  boom = configs.token_supply_configs.team.boom;
                  icrc = configs.token_supply_configs.team.icrc;
                  icp_result = null;
                  boom_result = ?boom_res_team;
                  icrc_result = ?icrc_res_team;
                };
                boom_dao_treasury = {
                  icp_account = configs.token_supply_configs.boom_dao_treasury.icp_account;
                  icrc_account = configs.token_supply_configs.boom_dao_treasury.icrc_account;
                  icp = configs.token_supply_configs.boom_dao_treasury.icp;
                  boom = configs.token_supply_configs.boom_dao_treasury.boom;
                  icrc = configs.token_supply_configs.boom_dao_treasury.icrc;
                  icp_result = null;
                  boom_result = ?boom_res_boom_dao;
                  icrc_result = ?icrc_res_boom_dao;
                };
                liquidity_pool = {
                  account = configs.token_supply_configs.liquidity_pool.account;
                  icp = configs.token_supply_configs.liquidity_pool.icp;
                  boom = configs.token_supply_configs.liquidity_pool.boom;
                  icrc = configs.token_supply_configs.liquidity_pool.icrc;
                  icp_result = null;
                  boom_result = ?boom_res_liquidity_pool;
                  icrc_result = ?icrc_res_liquidity_pool;
                };
                other = other_config_with_transfer_result;
              };
              min_token_e8s = configs.min_token_e8s;
              max_token_e8s = configs.max_token_e8s;
              min_participant_token_e8s = configs.min_participant_token_e8s;
              max_participant_token_e8s = configs.max_participant_token_e8s;
              swap_start_timestamp_seconds = configs.swap_start_timestamp_seconds;
              swap_due_timestamp_seconds = configs.swap_due_timestamp_seconds;
              swap_type = #boom;
            };
            _swap_configs := Trie.put(_swap_configs, Helper.keyT(arg.canister_id), Text.equal, configs_with_transfer_results).0;
          };
        };
      };
      case _ {};
    };
  };

  // query methods
  public query func total_token_contributed_e8s_and_total_participants(arg : { canister_id : Text; token : Swap.TokenSwapType }) : async ((Nat, Nat)) {
    var total_token : Nat = 0;
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?participants) {
        switch (arg.token) {
          case (#icp) {
            for ((participant_id, info) in Trie.iter(participants)) {
              total_token := total_token + Nat64.toNat(info.icp_e8s);
            };
            return (total_token, Trie.size(participants));
          };
          case (#boom) {
            for ((participant_id, info) in Trie.iter(participants)) {
              total_token := total_token + info.boom_e8s;
            };
            return (total_token, Trie.size(participants));
          };
        };
      };
      case _ {
        return (0, 0);
      };
    };
  };

  public query func total_token_contributed_e8s(arg : { canister_id : Text; token : Swap.TokenSwapType }) : async (Nat) {
    var total_token : Nat = 0;
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?participants) {
        switch (arg.token) {
          case (#icp) {
            for ((participant_id, info) in Trie.iter(participants)) {
              total_token := total_token + Nat64.toNat(info.icp_e8s);
            };
            return total_token;
          };
          case (#boom) {
            for ((participant_id, info) in Trie.iter(participants)) {
              total_token := total_token + info.boom_e8s;
            };
            return total_token;
          };
        };
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

  public shared ({ caller }) func create_icrc_token(args : { project : Swap.TokenProject; token_init_arg : ICRC.InitArgs }) : async ({
    canister_id : Text;
  }) {
    Cycles.add(2000000000000);
    let res = await management_canister.create_canister({
      settings = ?{
        freezing_threshold = null;
        controllers = ?[dev_principal, Principal.fromActor(SwapCanister)];
        memory_allocation = null;
        compute_allocation = null;
      };
      sender_canister_version = null;
    });

    let canister_id = res.canister_id;
    let arg : {
      #Init : ICRC.InitArgs;
      #Upgrade : ?ICRC.UpgradeArgs;
    } = #Init({
      decimals = ?8; // token_decimals = 8 has been set as default for all tokens
      token_symbol = args.token_init_arg.token_symbol;
      transfer_fee = args.token_init_arg.transfer_fee;
      metadata = args.token_init_arg.metadata;
      minting_account = args.token_init_arg.minting_account;
      initial_balances = args.token_init_arg.initial_balances;
      maximum_number_of_accounts = args.token_init_arg.maximum_number_of_accounts;
      accounts_overflow_trim_quantity = args.token_init_arg.accounts_overflow_trim_quantity;
      fee_collector_account = args.token_init_arg.fee_collector_account;
      archive_options = args.token_init_arg.archive_options;
      max_memo_length = args.token_init_arg.max_memo_length;
      token_name = args.token_init_arg.token_name;
      feature_flags = args.token_init_arg.feature_flags;
    });
    await management_canister.install_code({
      arg = to_candid (arg);
      wasm_module = getLatestIcrcWasm_();
      mode = #reinstall;
      canister_id = canister_id;
      sender_canister_version = null;
    });
    let metadata = getFormattedMetadata_(args.token_init_arg.metadata);
    let token : Swap.Token = {
      name = args.token_init_arg.token_name;
      url = metadata.url;
      logo = metadata.logo;
      description = metadata.description;
      symbol = args.token_init_arg.token_symbol;
      decimals = ?8; // token_decimals = 8 has been set as default for all tokens
      fee = args.token_init_arg.transfer_fee;
      token_canister_id = Principal.toText(canister_id);
    };
    _tokens := Trie.put(_tokens, Helper.keyT(Principal.toText(canister_id)), Text.equal, token).0;
    _projects := Trie.put(_projects, Helper.keyT(Principal.toText(canister_id)), Text.equal, args.project).0;
    return { canister_id = Principal.toText(canister_id) };
  };

  public shared ({ caller }) func list_icrc_token(token : Swap.Token) : async () {
    // assert (caller == dev_principal);
    _tokens := Trie.put(_tokens, Helper.keyT(token.token_canister_id), Text.equal, token).0;
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
    let swap_time_for_elite_tier_in_seconds : Int = 21600; // 6 hours currently, will be adjusted later
    for ((i, v) in Trie.iter(_swap_status)) {
      if (v.running == true and i != arg.canister_id) {
        return #err("Other token swap is already running, wait for it to get over Or contact dev team.");
      } else if (v.running == true and i == arg.canister_id) {
        return #err("Token swap already running.");
      };
    };
    // Swap will get opened 6hours before for Stakers
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        let current_time_in_seconds : Int = Time.now() / 1000000000;
        if ((configs.swap_start_timestamp_seconds - swap_time_for_elite_tier_in_seconds) <= current_time_in_seconds and current_time_in_seconds <= (configs.swap_due_timestamp_seconds + configs.swap_start_timestamp_seconds)) {
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
  // 2. Is ICP BlockIndex Legit? / Is BOOM BlockIndex Legit?
  // 3. Is Amount specified is matching SwapConfigs?
  public shared ({ caller }) func participate_in_token_swap(arg : { canister_id : Text; amount : Nat64; blockIndex : Nat64 }) : async (Result.Result<Text, Text>) {
    // Check if token swap running or not
    if (isTokenSwapRunning_({ canister_id = arg.canister_id }) == false) {
      return #err("token swap is not yet started or ended already.");
    } else {
      switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
        case (?configs) {
          let current_time_in_seconds = Time.now() / 1000000000;
          if ((configs.swap_due_timestamp_seconds + configs.swap_start_timestamp_seconds) < current_time_in_seconds) {
            _swap_status := Trie.put(
              _swap_status,
              Helper.keyT(arg.canister_id),
              Text.equal,
              {
                running = false;
                is_successfull = null;
              },
            ).0;

            // Allocate tokens automatically and settle swap as well here only
            switch (await settle_swap_status_and_allocate_tokens_if_swap_successfull({ canister_id = arg.canister_id })) {
              case (#ok _) {
                switch (await finalise_token_swap({ canister_id = arg.canister_id })) {
                  case (#ok _) {
                    return #ok("token swap has already ended and tokens has been disbured to participants and partners already");
                  };
                  case (#err e) {
                    return #err e;
                  };
                };
              };
              case (#err e) {
                return #err e;
              };
            };
            return #err("token swap has ended already.");
          };
        };
        case _ {
          return #err("token swap configs not found, contact dev team in discord.");
        };
      };
    };

    // Check if user is staker or not and check swap time constraint for stakers/non-stakers
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        let swap_start_time_seconds = configs.swap_start_timestamp_seconds;
        let swap_time_for_elite_tier_in_seconds : Int = 21600; // 6 hours ELITE tier, will be adjusted later
        let swap_time_for_pro_tier_in_seconds : Int = 10800; // 3 hours for PRO tier, will be adjusted later
        let gamingGuild = actor (ENV.GamingGuildsCanisterId) : actor {
          getUserBoomStakeTier : shared query (Text) -> async (Result.Result<Text, Text>);
        };
        let current_time_in_seconds : Int = Time.now() / 1000000000;
        switch (await gamingGuild.getUserBoomStakeTier(Principal.toText(caller))) {
          case (#ok tier) {
            if (tier == "PRO") {
              if (swap_start_time_seconds - swap_time_for_pro_tier_in_seconds > current_time_in_seconds) {
                return #err("Being a PRO BOOM Staker you can only participate 3 hours before Token Swap becomes Public.");
              };
            } else if (tier == "ELITE") {
              if (swap_start_time_seconds - swap_time_for_elite_tier_in_seconds > current_time_in_seconds) {
                return #err("Being a ELITE BOOM Staker you can only participate 6 hours before Token Swap becomes Public.");
              };
            };
          };
          case (#err e) {
            if (swap_start_time_seconds > current_time_in_seconds) {
              return #err("Unfortunately you are not a BOOM Staker, its always a good time to be a BOOM Staker.");
            };
          };
        };
      };
      case _ {
        return #err("token swap configs not found, contact dev team in discord");
      };
    };

    // Check-1
    if (isAmountValid_({ canister_id = arg.canister_id; amount = arg.amount }) == false) {

      return #err("amount passed does not fullfill participants requirements of min/max tokens.");
    };
    // Check-2
    let swap_canister_id : Text = Principal.toText(Principal.fromActor(SwapCanister));
    let participant_id : Text = Principal.toText(caller);
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        switch (configs.swap_type) {
          case (#icp) {
            switch (await queryIcpTx_(arg.blockIndex, swap_canister_id, participant_id, { e8s = arg.amount })) {
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
                            icp_e8s = info.icp_e8s + arg.amount;
                            boom_e8s = 0;
                            token_e8s = null;
                            icp_refund_result = null;
                            boom_refund_result = null;
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
                            icp_e8s = arg.amount;
                            boom_e8s = 0;
                            token_e8s = null;
                            icp_refund_result = null;
                            boom_refund_result = null;
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
                        icp_e8s = arg.amount;
                        boom_e8s = 0;
                        token_e8s = null;
                        icp_refund_result = null;
                        boom_refund_result = null;
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
          case (#boom) {
            switch (await queryIcrcTx_(Nat64.toNat(arg.blockIndex), swap_canister_id, participant_id, Nat64.toNat(arg.amount), ENV.BoomLedgerCanisterId)) {
              // Check-2
              case (#ok _) {
                switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
                  case (?participants) {
                    switch (Trie.find(participants, Helper.keyT(participant_id), Text.equal)) {
                      case (?info) {
                        let p_details : Swap.ParticipantDetails = {
                          account = {
                            owner = caller;
                            subaccount = null;
                          };
                          icp_e8s = 0;
                          boom_e8s = info.boom_e8s + Nat64.toNat(arg.amount);
                          token_e8s = null;
                          icp_refund_result = null;
                          boom_refund_result = null;
                          mint_result = null;
                        };
                        _swap_participants := Trie.put2D(
                          _swap_participants,
                          Helper.keyT(arg.canister_id),
                          Text.equal,
                          Helper.keyT(participant_id),
                          Text.equal,
                          p_details,
                        );
                        return #ok("");
                      };
                      case _ {
                        let p_details : Swap.ParticipantDetails = {
                          account = {
                            owner = caller;
                            subaccount = null;
                          };
                          icp_e8s = 0;
                          boom_e8s = Nat64.toNat(arg.amount);
                          token_e8s = null;
                          icp_refund_result = null;
                          boom_refund_result = null;
                          mint_result = null;
                        };
                        _swap_participants := Trie.put2D(
                          _swap_participants,
                          Helper.keyT(arg.canister_id),
                          Text.equal,
                          Helper.keyT(participant_id),
                          Text.equal,
                          p_details,
                        );
                        return #ok("");
                      };
                    };
                  };
                  case _ {
                    let p_details : Swap.ParticipantDetails = {
                      account = {
                        owner = caller;
                        subaccount = null;
                      };
                      icp_e8s = 0;
                      boom_e8s = Nat64.toNat(arg.amount);
                      token_e8s = null;
                      icp_refund_result = null;
                      boom_refund_result = null;
                      mint_result = null;
                    };
                    _swap_participants := Trie.put2D(
                      _swap_participants,
                      Helper.keyT(arg.canister_id),
                      Text.equal,
                      Helper.keyT(participant_id),
                      Text.equal,
                      p_details,
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
        };
      };
      case _ {
        return #err("token swap configs not found, contact dev team in discord");
      };
    };
  };

  // Checks :
  // 1. Sale timestamp is it over or not?
  // 2. total_icp/total_boom reached the goal?
  public shared ({ caller }) func settle_swap_status_and_allocate_tokens_if_swap_successfull(arg : { canister_id : Text }) : async (Result.Result<Text, Text>) {
    // assert (caller == dev_principal);
    var swap_type : Swap.TokenSwapType = #boom;
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        swap_type := configs.swap_type;
        let current_time_in_seconds = Time.now() / 1000000000;
        if ((configs.swap_due_timestamp_seconds + configs.swap_start_timestamp_seconds) > current_time_in_seconds) {
          return #err("token swap is still running or due time not passed yet.");
        };
      };
      case _ {
        return #err("token is not registered with BOOM DAO.");
      };
    };

    var total_token_e8s : Nat = await total_token_contributed_e8s({
      canister_id = arg.canister_id;
      token = swap_type;
    });

    let ?_current_swap_configs = Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal) else return #err("swap configs not found.");
    total_token_e8s := Nat.min(total_token_e8s, Nat64.toNat(_current_swap_configs.max_token_e8s));
    let total_token_float : Float = Helper.natToFloat(total_token_e8s) / 100000000.0;
    var participants : Trie.Trie<Text, Swap.ParticipantDetails> = Trie.empty();
    switch (Trie.find(_swap_participants, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?par) {
        participants := par;
      };
      case _ {};
    };
    switch (Trie.find(_swap_configs, Helper.keyT(arg.canister_id), Text.equal)) {
      case (?configs) {
        // if (configs.min_token_e8s <= total_token_e8s and configs.max_token_e8s >= total_token_e8s) {
        if (Nat64.toNat(configs.min_token_e8s) <= total_token_e8s) {
          // currently only Minimum ICP/BOOM raised constraint is getting checked, no constraints on Maximum ICP/BOOM raised
          let total_participants_tokens_float : Float = Helper.nat64ToFloat(Nat64.fromNat(configs.token_supply_configs.participants.icrc)) / 100000000.0;
          switch (swap_type) {
            case (#boom) {
              for ((id, info) in Trie.iter(participants)) {
                var tokens_amount_float : Float = ((Helper.natToFloat(info.boom_e8s) * total_participants_tokens_float) / total_token_float);
                let tokens_amount : Int = Float.toInt(tokens_amount_float);
                let p_details : Swap.ParticipantDetails = {
                  account = info.account;
                  icp_e8s = info.icp_e8s;
                  boom_e8s = info.boom_e8s;
                  token_e8s = ?Helper.intToNat(tokens_amount);
                  icp_refund_result = null;
                  boom_refund_result = null;
                  mint_result = null;
                };
                _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(id), Text.equal, p_details);
              };
            };
            case (#icp) {
              for ((id, info) in Trie.iter(participants)) {
                var tokens_amount_float : Float = ((Helper.nat64ToFloat(info.icp_e8s) * total_participants_tokens_float) / total_token_float);
                let tokens_amount : Int = Float.toInt(tokens_amount_float);
                let p_details : Swap.ParticipantDetails = {
                  account = info.account;
                  icp_e8s = info.icp_e8s;
                  boom_e8s = info.boom_e8s;
                  token_e8s = ?Helper.intToNat(tokens_amount);
                  icp_refund_result = null;
                  boom_refund_result = null;
                  mint_result = null;
                };
                _swap_participants := Trie.put2D(_swap_participants, Helper.keyT(arg.canister_id), Text.equal, Helper.keyT(id), Text.equal, p_details);
              };
            };
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
          await error_refund_token(arg);
          return #ok("token swap failed, refunded tokens to participants.");
        };
      };
      case _ {
        return #err("token swap status not found.");
      };
    };
  };

  public query func getTokenSwapType(tokenCanisterId : Text) : async (Text) {
    let ?swap_configs = Trie.find(_swap_configs, Helper.keyT(tokenCanisterId), Text.equal) else return "";
    switch (swap_configs.swap_type) {
      case (#boom) return "BOOM";
      case (#icp) return "ICP";
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

  public shared ({ caller }) func removeLedgerWasmVersion(arg : { version : Nat32 }) : async () {
    _ledger_wasms := Trie.remove(_ledger_wasms, Helper.key(arg.version), Nat32.equal).0;
  };

  public query func cycleBalance() : async (Nat) {
    return Cycles.balance();
  };

  public query func getAllTokensInfo() : async (Result.Result<Swap.TokensInfo, Text>) {
    var active = Buffer.Buffer<Swap.TokenInfo>(0);
    var inactive = Buffer.Buffer<Swap.TokenInfo>(0);
    var upcoming = Buffer.Buffer<Swap.TokenInfo>(0);
    for ((i, v) in Trie.iter(_swap_status)) {
      if (v.running) {
        let ?swap_config = Trie.find(_swap_configs, Helper.keyT(i), Text.equal) else {
          return #err("Token : " #i # " swap is active but swap configs not found");
        };
        let ?token_config = Trie.find(_tokens, Helper.keyT(i), Text.equal) else {
          return #err("Token : " #i # " swap is active but token configs not found");
        };
        let ?project_config = Trie.find(_projects, Helper.keyT(i), Text.equal) else {
          return #err("Token : " #i # " swap is active but token project configs not found");
        };
        active.add({
          token_canister_id = i;
          token_configs = token_config;
          token_project_configs = project_config;
          token_swap_configs = swap_config;
        });
      } else {
        let ?swap_config = Trie.find(_swap_configs, Helper.keyT(i), Text.equal) else {
          return #err("Token : " #i # " swap is inactive but swap configs not found");
        };
        let ?token_config = Trie.find(_tokens, Helper.keyT(i), Text.equal) else {
          return #err("Token : " #i # " swap is inactive but token configs not found");
        };
        let ?project_config = Trie.find(_projects, Helper.keyT(i), Text.equal) else {
          return #err("Token : " #i # " swap is inactive but token project configs not found");
        };
        if (swap_config.swap_start_timestamp_seconds > (Time.now() / 1000000000)) {
          upcoming.add({
            token_canister_id = i;
            token_configs = token_config;
            token_project_configs = project_config;
            token_swap_configs = swap_config;
          });
        } else {
          inactive.add({
            token_canister_id = i;
            token_configs = token_config;
            token_project_configs = project_config;
            token_swap_configs = swap_config;
          });
        };
      };
    };

    return #ok({
      active = Buffer.toArray(active);
      inactive = Buffer.toArray(inactive);
      upcoming = Buffer.toArray(upcoming);
    });
  };

  public query func getParticipationDetails(args : { participantId : Text; tokenCanisterId : Text }) : async (Result.Result<Swap.ParticipantDetails, Text>) {
    let ?allParticipants = Trie.find(_swap_participants, Helper.keyT(args.tokenCanisterId), Text.equal) else {
      return #err("There are no swap participants yet.");
    };
    let ?details = Trie.find(allParticipants, Helper.keyT(args.participantId), Text.equal) else {
      return #err("no current participation");
    };
    return #ok(details);
  };

  public query func getAllParticipantsDetails(args : { tokenCanisterId : Text }) : async (Result.Result<[Swap.ParticipantDetails], Text>) {
    var b = Buffer.Buffer<Swap.ParticipantDetails>(0);
    let ?allParticipants = Trie.find(_swap_participants, Helper.keyT(args.tokenCanisterId), Text.equal) else {
      return #err("There are no swap participants yet.");
    };
    for ((i, v) in Trie.iter(allParticipants)) {
      b.add(v);
    };
    return #ok(Buffer.toArray(b));
  };

};
