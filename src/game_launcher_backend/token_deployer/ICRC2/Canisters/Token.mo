import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";

import ExperimentalCycles "mo:base/ExperimentalCycles";

import SB "../../../utils/StableBuffer";

import ICRC2 "..";

shared ({ caller = _owner }) actor class Token(
    init_args : ICRC2.TokenInitArgs
) : async ICRC2.FullInterface {

    let icrc2_args : ICRC2.InitArgs = {
        init_args with minting_account = Option.get(
            init_args.minting_account,
            {
                owner = _owner;
                subaccount = null;
            },
        );
    };

    stable let token = ICRC2.init(icrc2_args);

    /// Functions for the ICRC2 token standard
    public shared query func icrc1_name() : async Text {
        ICRC2.name(token);
    };

    public shared query func icrc1_symbol() : async Text {
        ICRC2.symbol(token);
    };

    public shared query func icrc1_decimals() : async Nat8 {
        ICRC2.decimals(token);
    };

    public shared query func icrc1_fee() : async ICRC2.Balance {
        ICRC2.fee(token);
    };

    public shared query func icrc1_metadata() : async [ICRC2.MetaDatum] {
        ICRC2.metadata(token);
    };

    public shared query func icrc1_total_supply() : async ICRC2.Balance {
        ICRC2.total_supply(token);
    };

    public shared query func icrc1_minting_account() : async ?ICRC2.Account {
        ?ICRC2.minting_account(token);
    };

    public shared query func icrc1_balance_of(args : ICRC2.Account) : async ICRC2.Balance {
        ICRC2.balance_of(token, args);
    };

    public shared query func icrc1_supported_standards() : async [ICRC2.SupportedStandard] {
        ICRC2.supported_standards(token);
    };

    public shared ({ caller }) func icrc1_transfer(args : ICRC2.TransferArgs) : async ICRC2.TransferResult {
        await* ICRC2.transfer(token, args, caller);
    };

    public shared ({ caller }) func mint(args : ICRC2.Mint) : async ICRC2.TransferResult {
        await* ICRC2.mint(token, args, caller);
    };

    public shared ({ caller }) func burn(args : ICRC2.BurnArgs) : async ICRC2.TransferResult {
        await* ICRC2.burn(token, args, caller);
    };

    public shared ({ caller }) func icrc2_approve(args : ICRC2.ApproveArgs) : async ICRC2.ApproveResult {
        await* ICRC2.approve(token, args, caller);
    };

    public shared ({ caller }) func icrc2_transfer_from(args : ICRC2.TransferFromArgs) : async ICRC2.TransferFromResult {
        await* ICRC2.transfer_from(token, args, caller);
    };

    public shared query func icrc2_allowance(args : ICRC2.AllowanceArgs) : async ICRC2.Allowance {
        ICRC2.allowance(token, args);
    };

    // Additional functions not included in the ICRC2 standard
    public shared func get_transaction(i : ICRC2.TxIndex) : async ?ICRC2.Transaction {
        await* ICRC2.get_transaction(token, i);
    };

    // Deposit cycles into this canister.
    public shared func deposit_cycles() : async () {
        let amount = ExperimentalCycles.available();
        let accepted = ExperimentalCycles.accept(amount);
        assert (accepted == amount);
    };
};
