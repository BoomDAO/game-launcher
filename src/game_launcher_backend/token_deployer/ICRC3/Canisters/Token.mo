import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Buffer "mo:base/Buffer";

import SB "../../../utils/StableBuffer";

import ICRC3 "..";

shared ({ caller = _owner }) actor class Token(
  init_args : ICRC3.TokenInitArgs
) : async ICRC3.FullInterface {

  let icrc2_args : ICRC3.InitArgs = {
    init_args with minting_account = Option.get(
      init_args.minting_account,
      {
        owner = _owner;
        subaccount = null;
      },
    );
  };

  stable let token = ICRC3.init(icrc2_args);

  /// Functions for the ICRC3 token standard
  public shared query func icrc1_name() : async Text {
    ICRC3.name(token);
  };

  public shared query func icrc1_symbol() : async Text {
    ICRC3.symbol(token);
  };

  public shared query func icrc1_decimals() : async Nat8 {
    ICRC3.decimals(token);
  };

  public shared query func icrc1_fee() : async ICRC3.Balance {
    ICRC3.fee(token);
  };

  public shared query func icrc1_metadata() : async [ICRC3.MetaDatum] {
    ICRC3.metadata(token);
  };

  public shared query func icrc1_total_supply() : async ICRC3.Balance {
    ICRC3.total_supply(token);
  };

  public shared query func icrc1_minting_account() : async ?ICRC3.Account {
    ?ICRC3.minting_account(token);
  };

  public shared query func icrc1_balance_of(args : ICRC3.Account) : async ICRC3.Balance {
    ICRC3.balance_of(token, args);
  };

  public shared query func icrc1_supported_standards() : async [ICRC3.SupportedStandard] {
    ICRC3.supported_standards(token);
  };

  public shared ({ caller }) func icrc1_transfer(args : ICRC3.TransferArgs) : async ICRC3.TransferResult {
    await* ICRC3.transfer(token, args, caller);
  };

  public shared ({ caller }) func mint(args : ICRC3.Mint) : async ICRC3.TransferResult {
    await* ICRC3.mint(token, args, caller);
  };

  public shared ({ caller }) func burn(args : ICRC3.BurnArgs) : async ICRC3.TransferResult {
    await* ICRC3.burn(token, args, caller);
  };

  public shared ({ caller }) func icrc2_approve(args : ICRC3.ApproveArgs) : async ICRC3.ApproveResult {
    await* ICRC3.approve(token, args, caller);
  };

  public shared ({ caller }) func icrc2_transfer_from(args : ICRC3.TransferFromArgs) : async ICRC3.TransferFromResult {
    await* ICRC3.transfer_from(token, args, caller);
  };

  public shared query func icrc2_allowance(args : ICRC3.AllowanceArgs) : async ICRC3.Allowance {
    ICRC3.allowance(token, args);
  };

  public shared query func get_transactions(req : ICRC3.GetTransactionsRequest) : async ICRC3.GetTransactionsResponse {
    ICRC3.get_transactions(token, req);
  };

  // Additional functions not included in the ICRC3 standard
  public shared func get_transaction(i : ICRC3.TxIndex) : async ?ICRC3.Transaction {
    await* ICRC3.get_transaction(token, i);
  };

  // Deposit cycles into this canister.
  public shared func deposit_cycles() : async () {
    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept(amount);
    assert (accepted == amount);
  };

  // NFID <-> ICRC-28 implementation for trusted origins
  private stable var trusted_origins : [Text] = [];

  public shared ({ caller }) func get_trusted_origins() : async ([Text]) {
    return trusted_origins;
  };

  public shared ({ caller }) func addTrustedOrigins(v : Text) : async () {
    assert(caller == token.minting_account.owner);
    var b : Buffer.Buffer<Text> = Buffer.fromArray(trusted_origins);
    b.add(v);
    trusted_origins := Buffer.toArray(b);
  };

  public shared ({ caller }) func removeTrustedOrigins(v : Text) : async () {
    assert(caller == token.minting_account.owner);
    var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
    for (i in trusted_origins.vals()) {
      if (v != i) {
        b.add(i);
      };
    };
    trusted_origins := Buffer.toArray(b);
  };

};
