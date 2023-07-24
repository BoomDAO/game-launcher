import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import EC "mo:base/ExperimentalCycles";

import Itertools "../../utils/Iter";
import StableTrieMap "../../utils/StableTrieMap";
import StableBuffer "../../utils/StableBuffer";

import T "Types";
import Utils "Utils";
import Approve "Approve";
import TransferFrom "TransferFrom";
import ICRC1 "../ICRC1";
import Account "../ICRC1/Account";
import Archive "../ICRC1/Canisters/Archive";

/// The ICRC2 class with all the functions for creating an
/// ICRC2 token on the Internet Computer
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

    /// Initialize a new ICRC-2 token
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
        let app_req = Utils.create_approve_req(args, caller);

        switch (Approve.validate_request(token, app_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        let { encoded; amount } = app_req;

        // burn fee
        Utils.burn_balance(token, encoded.from, Option.get(args.fee, token._fee));

        await* Approve.write_approval(token, app_req);
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

        let spender = {
            owner = caller;
            subaccount = args.spender_subaccount;
        };

        let txf_kind = if (args.from == token.minting_account) {
            #mint;
        } else if (args.to == token.minting_account) {
            #burn;
        } else {
            #transfer;
        };

        let txf_req = Utils.create_transfer_from_req(args, caller, txf_kind);

        switch (TransferFrom.validate_request(token, txf_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        let { encoded; amount; fee } = txf_req;
        let { allowance; expires_at } = Utils.get_allowance(token.approvals, encoded);
        ignore await* Approve.write_approval(
            token,
            {
                amount = allowance - amount - Option.get(fee, token._fee);
                expires_at;
                encoded;
            },
        );

        // process transaction
        switch (txf_req.kind) {
            case (#mint) {
                Utils.mint_balance(token, encoded.to, amount);
            };
            case (#burn) {
                Utils.burn_balance(token, encoded.from, amount);
            };
            case (#transfer) {
                Utils.transfer_balance(token, txf_req);

                // burn fee
                Utils.burn_balance(token, encoded.from, token._fee);
            };
        };

        // store transaction
        let index = SB.size(token.transactions) + token.archive.stored_txs;
        let tx = Utils.req_to_tx(txf_req, index);
        SB.add(token.transactions, tx);

        // transfer transaction to archive if necessary
        await* update_canister(token);

        #Ok(tx.index);
    };

    /// Returns the total number of transactions that have been processed by the given token.
    public func total_transactions(token : T.TokenData) : Nat {
        ICRC1.total_transactions(token);
    };

    /// Retrieves the transaction specified by the given `tx_index`
    public func get_transaction(token : T.TokenData, tx_index : T.TxIndex) : async* ?T.Transaction {
        await* ICRC1.get_transaction(token, tx_index);
    };

    // Updates the token's data and manages the transactions
    //
    // **added at the end of any function that creates a new transaction**
    func update_canister(token : T.TokenData) : async* () {
        let txs_size = SB.size(token.transactions);

        if (txs_size >= MAX_TRANSACTIONS_IN_LEDGER) {
            await* append_transactions(token);
        };
    };

    // Moves the transactions from the ICRC1 canister to the archive canister
    // and returns a boolean that indicates the success of the data transfer
    func append_transactions(token : T.TokenData) : async* () {
        let { archive; transactions } = token;

        if (archive.stored_txs == 0) {
            EC.add(200_000_000_000);
            archive.canister := await Archive.Archive();
        };

        let res = await archive.canister.append_transactions(
            SB.toArray(transactions)
        );

        switch (res) {
            case (#ok(_)) {
                archive.stored_txs += SB.size(transactions);
                SB.clear(transactions);
            };
            case (#err(_)) {};
        };
    };

};
