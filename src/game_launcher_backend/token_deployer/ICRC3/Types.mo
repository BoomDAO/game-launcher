import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";

import Types1 "../ICRC1/Types";
import Types2 "../ICRC2/Types";

module {

    public type Value = Types1.Value;

    public type BlockIndex = Types1.BlockIndex;
    public type Subaccount = Types1.Subaccount;
    public type Balance = Types1.Balance;
    public type StableBuffer<T> = Types1.StableBuffer<T>;
    public type StableTrieMap<K, V> = Types1.StableTrieMap<K, V>;

    public type Account = Types1.Account;

    public type EncodedAccount = Types1.EncodedAccount;

    public type SupportedStandard = Types1.SupportedStandard;

    public type Memo = Types1.Memo;
    public type Timestamp = Types1.Timestamp;
    public type Duration = Types1.Duration;
    public type TxIndex = Types1.TxIndex;
    public type TxLog = Types1.TxLog;

    public type MetaDatum = Types1.MetaDatum;
    public type MetaData = [MetaDatum];

    public type TxKind = Types1.TxKind;

    public type Mint = Types1.Mint;

    public type BurnArgs = Types1.BurnArgs;

    public type Burn = Types1.Burn;

    public type TransferArgs = Types1.TransferArgs;

    public type Transfer = Types1.Transfer;

    /// Arguments for an allowance operation
    public type AllowanceArgs = Types2.AllowanceArgs;

    public type Allowance = Types2.Allowance;

    /// Arguments for an approve operation
    public type ApproveArgs = Types2.ApproveArgs;

    /// Arguments for a transfer from operation
    public type TransferFromArgs = Types2.TransferFromArgs;

    public type WriteApproveRequest = Types2.TransferFromArgs;

    /// Internal representation of an Approve request
    public type ApproveRequest = Types2.ApproveRequest;

    /// Internal representation of a Transaction From request
    public type TransactionFromRequest = Types2.TransactionFromRequest;

    /// Internal representation of a transaction request
    public type TransactionRequest = Types1.TransactionRequest;

    public type Transaction = Types1.Transaction;

    public type TimeError = Types1.TimeError;

    public type OperationError = Types1.OperationError;

    public type TransferError = Types1.TransferError;

    public type ApproveError = Types2.ApproveError;

    public type TransferFromError = Types2.TransferFromError;

    public type TransferResult = Types1.TransferResult;

    public type ApproveResult = Types2.ApproveResult;

    public type TransferFromResult = Types2.TransferFromResult;

    /// Interface for the ICRC token canister
    public type ICRC1Interface = Types1.ICRC1Interface;

    public type TxCandidBlob = Types1.TxCandidBlob;

    /// The Interface for the Archive canister
    public type ArchiveInterface = Types1.ArchiveInterface;

    /// Initial arguments for the setting up the icrc3 token canister
    public type InitArgs = Types1.InitArgs;

    /// [InitArgs](#type.InitArgs) with optional fields for initializing a token canister
    public type TokenInitArgs = Types1.TokenInitArgs;

    /// Additional settings for the [InitArgs](#type.InitArgs) type during initialization of an icrc3 token canister
    public type AdvancedSettings = Types1.AdvancedSettings;

    public type AccountBalances = Types1.AccountBalances;

    public type Approvals = Types2.Approvals;

    public type ApprovalAllowances = Types2.ApprovalAllowances;

    /// The details of the archive canister
    public type ArchiveData = Types1.ArchiveData;

    /// The state of the token canister
    public type TokenData = Types2.TokenData;

    /// The type to request a range of transactions from the ledger canister
    public type GetTransactionsRequest = Types1.GetTransactionsRequest;

    public type TransactionRange = Types1.TransactionRange;

    public type QueryArchiveFn = Types1.QueryArchiveFn;

    public type ArchivedTransaction = Types1.ArchivedTransaction;

    public type GetTransactionsResponse = Types1.GetTransactionsResponse;

    /// Functions supported by the ICRC-2 standard
    public type ICRC2Interface = Types2.ICRC2Interface;

    /// Functions supported by the ICRC-3 standard
    public type ICRC3Interface = actor {
        get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
    };

    /// Interface of the ICRC token
    public type FullInterface = ICRC1Interface and ICRC2Interface and ICRC3Interface;

};
