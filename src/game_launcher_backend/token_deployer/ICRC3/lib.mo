import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";

import Itertools "mo:itertools/Iter";
import StableTrieMap "mo:StableTrieMap";

import T "Types";
import Utils "Utils";
import ICRC1 "../ICRC1";
import ICRC2 "../ICRC2";
import Account "../ICRC1/Account";
import Archive "../ICRC1/Canisters/Archive";

/// The ICRC3 class with all the functions for creating an
/// ICRC3 token on the Internet Computer
module {
    let { SB } = Utils;

    public type Account = T.Account;
    public type Subaccount = T.Subaccount;
    public type AccountBalances = T.AccountBalances;

    public type Transaction = T.Transaction;
    public type Balance = T.Balance;
    public type Allowance = T.Allowance;
    public type TransferArgs = T.TransferArgs;
    public type AllowanceArgs = T.AllowanceArgs;
    public type ApproveArgs = T.ApproveArgs;
    public type TransferFromArgs = T.TransferFromArgs;
    public type Mint = T.Mint;
    public type BurnArgs = T.BurnArgs;
    public type TransactionRequest = T.TransactionRequest;
    public type TransferError = T.TransferError;
    public type ApproveError = T.ApproveError;
    public type TransferFromError = T.TransferFromError;

    public type SupportedStandard = T.SupportedStandard;

    public type InitArgs = T.InitArgs;
    public type TokenInitArgs = T.TokenInitArgs;
    public type TokenData = T.TokenData;
    public type MetaDatum = T.MetaDatum;
    public type TxLog = T.TxLog;
    public type TxIndex = T.TxIndex;

    public type ICRC1Interface = T.ICRC1Interface;
    public type FullInterface = T.FullInterface;

    public type ArchiveInterface = T.ArchiveInterface;

    public type GetTransactionsRequest = T.GetTransactionsRequest;
    public type GetTransactionsResponse = T.GetTransactionsResponse;
    public type QueryArchiveFn = T.QueryArchiveFn;
    public type TransactionRange = T.TransactionRange;
    public type ArchivedTransaction = T.ArchivedTransaction;

    public type TransferResult = T.TransferResult;
    public type ApproveResult = T.ApproveResult;
    public type TransferFromResult = T.TransferFromResult;

    public let MAX_TRANSACTIONS_IN_LEDGER = ICRC1.MAX_TRANSACTIONS_IN_LEDGER;
    public let MAX_TRANSACTION_BYTES : Nat64 = ICRC1.MAX_TRANSACTION_BYTES;
    public let MAX_TRANSACTIONS_PER_REQUEST = ICRC1.MAX_TRANSACTIONS_PER_REQUEST;

    /// Initialize a new ICRC-3 token
    public func init(args : T.InitArgs) : T.TokenData {
        let {
            name;
            symbol;
            decimals;
            fee;
            minting_account;
            max_supply;
            initial_balances;
            min_burn_amount;
            advanced_settings;
        } = args;

        var _burned_tokens = 0;
        var permitted_drift = 60_000_000_000;
        var transaction_window = 86_400_000_000_000;

        switch (advanced_settings) {
            case (?options) {
                _burned_tokens := options.burned_tokens;
                permitted_drift := Nat64.toNat(options.permitted_drift);
                transaction_window := Nat64.toNat(options.transaction_window);
            };
            case (null) {};
        };

        if (not Account.validate(minting_account)) {
            Debug.trap("minting_account is invalid");
        };

        let accounts : T.AccountBalances = StableTrieMap.new();
        let approvals : T.ApprovalAllowances = StableTrieMap.new();

        var _minted_tokens = _burned_tokens;

        for ((i, (account, balance)) in Itertools.enumerate(initial_balances.vals())) {

            if (not Account.validate(account)) {
                Debug.trap(
                    "Invalid Account: Account at index " # debug_show i # " is invalid in 'initial_balances'"
                );
            };

            let encoded_account = Account.encode(account);

            StableTrieMap.put(
                accounts,
                Blob.equal,
                Blob.hash,
                encoded_account,
                balance,
            );

            _minted_tokens += balance;
        };

        {
            name = name;
            symbol = symbol;
            decimals;
            var _fee = fee;
            max_supply;
            var _minted_tokens = _minted_tokens;
            var _burned_tokens = _burned_tokens;
            min_burn_amount;
            minting_account;
            accounts;
            approvals;
            metadata = Utils.init_metadata(args);
            supported_standards = Utils.init_standards();
            transactions = SB.initPresized(MAX_TRANSACTIONS_IN_LEDGER);
            permitted_drift;
            transaction_window;
            archive = {
                var canister = actor ("aaaaa-aa");
                var stored_txs = 0;
            };
        };
    };

    /// Retrieve the name of the token
    public func name(token : T.TokenData) : Text {
        token.name;
    };

    /// Retrieve the symbol of the token
    public func symbol(token : T.TokenData) : Text {
        token.symbol;
    };

    /// Retrieve the number of decimals specified for the token
    public func decimals({ decimals } : T.TokenData) : Nat8 {
        decimals;
    };

    /// Retrieve the fee for each transfer
    public func fee(token : T.TokenData) : T.Balance {
        token._fee;
    };

    /// Set the fee for each transfer
    public func set_fee(token : T.TokenData, fee : Nat) {
        token._fee := fee;
    };

    /// Retrieve all the metadata of the token
    public func metadata(token : T.TokenData) : [T.MetaDatum] {
        SB.toArray(token.metadata);
    };

    /// Returns the total supply of circulating tokens
    public func total_supply(token : T.TokenData) : T.Balance {
        token._minted_tokens - token._burned_tokens;
    };

    /// Returns the total supply of minted tokens
    public func minted_supply(token : T.TokenData) : T.Balance {
        token._minted_tokens;
    };

    /// Returns the total supply of burned tokens
    public func burned_supply(token : T.TokenData) : T.Balance {
        token._burned_tokens;
    };

    /// Returns the maximum supply of tokens
    public func max_supply(token : T.TokenData) : T.Balance {
        token.max_supply;
    };

    /// Returns the account with the permission to mint tokens
    ///
    /// Note: **The minting account can only participate in minting
    /// and burning transactions, so any tokens sent to it will be
    /// considered burned.**

    public func minting_account(token : T.TokenData) : T.Account {
        token.minting_account;
    };

    /// Retrieve the balance of a given account
    public func balance_of({ accounts } : T.TokenData, account : T.Account) : T.Balance {
        let encoded_account = Account.encode(account);
        Utils.get_balance(accounts, encoded_account);
    };

    /// Returns an array of standards supported by this token
    public func supported_standards(token : T.TokenData) : [T.SupportedStandard] {
        SB.toArray(token.supported_standards);
    };

    /// Formats a float to a nat balance and applies the correct number of decimal places
    public func balance_from_float(token : T.TokenData, float : Float) : T.Balance {
        ICRC1.balance_from_float(token, float);
    };

    /// Transfers tokens from one account to another account (minting and burning included)
    public func transfer(
        token : T.TokenData,
        args : T.TransferArgs,
        caller : Principal,
    ) : async* T.TransferResult {
        await* ICRC1.transfer(token, args, caller);
    };

    /// Helper function to mint tokens with minimum args
    public func mint(token : T.TokenData, args : T.Mint, caller : Principal) : async* T.TransferResult {
        await* ICRC1.mint(token, args, caller);
    };

    /// Helper function to burn tokens with minimum args
    public func burn(token : T.TokenData, args : T.BurnArgs, caller : Principal) : async* T.TransferResult {
        await* ICRC1.burn(token, args, caller);
    };

    /// Creates or updates an approval allowance
    public func approve(token : T.TokenData, args : T.ApproveArgs, caller : Principal) : async* T.ApproveResult {
        await* ICRC2.approve(token, args, caller);
    };

    /// Retrieve the allowance of a given approval
    public func allowance({ approvals } : T.TokenData, args : T.AllowanceArgs) : T.Allowance {
        let encoded_args = {
            from = Account.encode(args.account);
            spender = Account.encode(args.spender);
        };
        Utils.get_allowance(approvals, encoded_args);
    };

    /// Transfers tokens by spender from one account to another account (minting and burning included)
    public func transfer_from(
        token : T.TokenData,
        args : T.TransferFromArgs,
        caller : Principal,
    ) : async* T.TransferFromResult {
        await* ICRC2.transfer_from(token, args, caller);
    };

    /// Returns the total number of transactions that have been processed by the given token.
    public func total_transactions(token : T.TokenData) : Nat {
        ICRC1.total_transactions(token);
    };

    /// Retrieves the transaction specified by the given `tx_index`
    public func get_transaction(token : T.TokenData, tx_index : T.TxIndex) : async* ?T.Transaction {
        await* ICRC1.get_transaction(token, tx_index);
    };

    /// Retrieves the transactions specified by the given range
    public func icrc3_get_transactions(token : T.TokenData, req : T.GetTransactionsRequest) : T.GetTransactionsResponse {
        let { archive; transactions } = token;

        var first_index = 0xFFFF_FFFF_FFFF_FFFF; // returned if no transactions are found

        let req_end = req.start + req.length;
        let tx_end = archive.stored_txs + SB.size(transactions);

        var txs_in_canister : [T.Transaction] = [];

        if (req.start < tx_end and req_end >= archive.stored_txs) {
            first_index := Nat.max(req.start, archive.stored_txs);
            let tx_start_index = (first_index - archive.stored_txs) : Nat;

            txs_in_canister := SB.slice(transactions, tx_start_index, req.length);
        };

        let archived_range = if (req.start < archive.stored_txs) {
            {
                start = req.start;
                end = Nat.min(
                    archive.stored_txs,
                    (req.start + req.length) : Nat,
                );
            };
        } else {
            { start = 0; end = 0 };
        };

        let txs_in_archive = (archived_range.end - archived_range.start) : Nat;

        let size = Utils.div_ceil(txs_in_archive, MAX_TRANSACTIONS_PER_REQUEST);

        let archived_transactions = Array.tabulate(
            size,
            func(i : Nat) : T.ArchivedTransaction {
                let offset = i * MAX_TRANSACTIONS_PER_REQUEST;
                let start = offset + archived_range.start;
                let length = Nat.min(
                    MAX_TRANSACTIONS_PER_REQUEST,
                    archived_range.end - start,
                );

                let callback = token.archive.canister.get_transactions;

                { start; length; callback };
            },
        );

        {
            log_length = txs_in_archive + txs_in_canister.size();
            first_index;
            transactions = txs_in_canister;
            archived_transactions;
        };
    };

};
