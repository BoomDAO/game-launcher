import Blob "mo:base/Blob";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";

import STMap "../../utils/StableTrieMap";
import StableBuffer "../../utils/StableBuffer";

import T "Types";
import U1 "../ICRC1/Utils";
import Account "../ICRC1/Account";

module {
    // Creates a Stable Buffer with the default metadata and returns it.
    public func init_metadata(args : T.InitArgs) : StableBuffer.StableBuffer<T.MetaDatum> {
        let metadata = SB.initPresized<T.MetaDatum>(4);
        SB.add(metadata, ("icrc2:fee", #Nat(args.fee)));
        SB.add(metadata, ("icrc2:name", #Text(args.name)));
        SB.add(metadata, ("icrc2:symbol", #Text(args.symbol)));
        SB.add(metadata, ("icrc2:decimals", #Nat(Nat8.toNat(args.decimals))));

        metadata;
    };

    public let default_standard : T.SupportedStandard = {
        name = "ICRC-2";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-2";
    };

    // Creates a Stable Buffer with the default supported standards and returns it.
    public func init_standards() : StableBuffer.StableBuffer<T.SupportedStandard> {
        let standards = SB.initPresized<T.SupportedStandard>(4);
        SB.add(standards, U1.default_standard);
        SB.add(standards, default_standard);

        standards;
    };

    // Returns the default subaccount for cases where a user does
    // not specify it.
    public func default_subaccount() : T.Subaccount {
        U1.default_subaccount();
    };

    // Computes a hash from the least significant 32-bits of `n`, ignoring other bits.
    public func hash(n : Nat) : Hash.Hash {
        U1.hash(n);
    };

    // Formats the different operation arguements into
    // a `TransactionRequest`, an internal type to access fields easier.
    public func create_transfer_req(
        args : T.TransferArgs,
        owner : Principal,
        tx_kind : T.TxKind,
    ) : T.TransactionRequest {
        U1.create_transfer_req(args, owner, tx_kind);
    };

    // Formats the different operation arguements into
    // a `TransactionFromRequest`, an internal type to access fields easier.
    public func create_transfer_from_req(
        args : T.TransferFromArgs,
        owner : Principal,
        tx_kind : T.TxKind,
    ) : T.TransactionFromRequest {
        let spender = { owner; subaccount = args.spender_subaccount };
        var transfer_args = { args with from_subaccount = null };

        var transfer_from_args = U1.create_transfer_req(transfer_args, owner, tx_kind);
        {
            transfer_from_args with encoded = {
                from = Account.encode(args.from);
                to = Account.encode(args.to);
                spender = Account.encode(spender);
            };
            from = args.from;
            spender;
        };
    };

    // Formats the different operation arguments into
    // an `ApproveRequest`, an internal type to access fields easier.
    public func create_approve_req(
        args : T.ApproveArgs,
        owner : Principal,
    ) : T.ApproveRequest {

        let from = {
            owner;
            subaccount = args.from_subaccount;
        };

        let encoded = {
            from = Account.encode(from);
            spender = Account.encode(args.spender);
        };

        {
            args with from = from;
            encoded;
        };
    };

    // Transforms the transaction kind from `variant` to `Text`
    public func kind_to_text(kind : T.TxKind) : Text {
        U1.kind_to_text(kind);
    };

    // Formats the tx request into a finalised transaction
    public func req_to_tx(tx_req : T.TransactionRequest, index : Nat) : T.Transaction {
        U1.req_to_tx(tx_req, index);
    };

    public func div_ceil(n : Nat, d : Nat) : Nat {
        U1.div_ceil(n, d);
    };

    /// Retrieves the balance of an account
    public func get_balance(accounts : T.AccountBalances, encoded_account : T.EncodedAccount) : T.Balance {
        U1.get_balance(accounts, encoded_account);
    };

    public func get_account_approvals(
        approval_allowances : T.ApprovalAllowances,
        encoded_account : T.EncodedAccount,
    ) : ?T.Approvals {
        return STMap.get(approval_allowances, Blob.equal, Blob.hash, encoded_account);
    };

    /// Retrieves an approval's allowance
    public func get_allowance(
        approval_allowances : T.ApprovalAllowances,
        encoded : {from : T.EncodedAccount; spender : T.EncodedAccount},
    ) : T.Allowance {
        let default_allowance = { allowance = 0; expires_at = null };
        let account_approvals = get_account_approvals(approval_allowances, encoded.from);

        switch (account_approvals) {
            case (?approvals) {
                let spender_allowance = STMap.get(
                    approvals,
                    Blob.equal,
                    Blob.hash,
                    encoded.spender,
                );
                switch (spender_allowance) {
                    case (?allowance) { allowance };
                    case (_) {
                        default_allowance;
                    };
                };
            };
            case (_) { default_allowance };
        };
    };

    /// Updates the balance of an account
    public func update_balance(
        accounts : T.AccountBalances,
        encoded_account : T.EncodedAccount,
        update : (T.Balance) -> T.Balance,
    ) {
        U1.update_balance(accounts, encoded_account, update);
    };

    // Transfers tokens from the sender to the
    // recipient in the tx request
    public func transfer_balance(
        token : T.TokenData,
        tx_req : T.TransactionRequest,
    ) {
        U1.transfer_balance(token, tx_req);
    };

    public func mint_balance(
        token : T.TokenData,
        encoded_account : T.EncodedAccount,
        amount : T.Balance,
    ) {
        U1.mint_balance(token, encoded_account, amount);
    };

    public func burn_balance(
        token : T.TokenData,
        encoded_account : T.EncodedAccount,
        amount : T.Balance,
    ) {
        U1.burn_balance(token, encoded_account, amount);
    };

    // Stable Buffer Module with some additional functions
    public let SB = U1.SB;
};
