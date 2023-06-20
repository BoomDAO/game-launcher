import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Bool "mo:base/Bool";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Nat64 "mo:base/Nat64";

module {
    public type Tx = {
        height : Nat64;
        to : Text;
        from : Text;
        amt : Nat64;
    };

    public type Tx_ICRC = {
        index : Nat;
        to : Text;
        from : Text;
        amt : Nat;
    };

    public type HeaderField = (Text, Text);

    public type HttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
        upgrade : ?Bool;
    };

    public type HttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };

    public type HttpHeader = {
        name : Text;
        value : Text;
    };

    public type HttpMethod = {
        #get;
        #post;
        #head;
    };

    public type TransformType = {
        #function : shared CanisterHttpResponsePayload -> async CanisterHttpResponsePayload;
    };

    public type TransformArgs = {
        response : CanisterHttpResponsePayload;
        context : Blob;
    };

    public type TransformContext = {
        function : shared query TransformArgs -> async CanisterHttpResponsePayload;
        context : Blob;
    };

    public type CanisterHttpRequestArgs = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [HttpHeader];
        body : [Nat8];
        method : HttpMethod;
        transform : ?TransformContext;
    };

    public type CanisterHttpResponsePayload = {
        status : Nat;
        headers : [HttpHeader];
        body : [Nat8];
    };

    public type NftData = {
        index : Nat32;
        canister : Text;
        url : Text;
        metadata : Text;
        standard : Text;
        collection : Text;
    };

    public type Response = {
        #Success : Text;
        #Err : Text;
    };

    //For IC Ledger Canister

    public type AccountBalanceArgs = { account : AccountIdentifier };
    public type AccountIdentifier = [Nat8];
    public type Archive = { canister_id : Principal };
    public type Archives = { archives : [Archive] };
    public type Block = {
        transaction : Transaction;
        timestamp : TimeStamp;
        parent_hash : ?[Nat8];
    };
    public type BlockIndex = Nat64;
    public type BlockRange = { blocks : [Block] };
    public type GetBlocksArgs = { start : BlockIndex; length : Nat64 };
    public type Memo = Nat64;
    public type Operation = {
        #Burn : { from : AccountIdentifier; amount : Tokens };
        #Mint : { to : AccountIdentifier; amount : Tokens };
        #Transfer : {
            to : AccountIdentifier;
            fee : Tokens;
            from : AccountIdentifier;
            amount : Tokens;
        };
    };
    public type QueryArchiveError = {
        #BadFirstBlockIndex : {
            requested_index : BlockIndex;
            first_valid_index : BlockIndex;
        };
        #Other : { error_message : Text; error_code : Nat64 };
    };
    public type QueryArchiveFn = shared query GetBlocksArgs -> async QueryArchiveResult;
    public type QueryArchiveResult = {
        #Ok : BlockRange;
        #Err : QueryArchiveError;
    };
    public type QueryBlocksResponse = {
        certificate : ?[Nat8];
        blocks : [Block];
        chain_length : Nat64;
        first_block_index : BlockIndex;
        archived_blocks : [{
            callback : QueryArchiveFn;
            start : BlockIndex;
            length : Nat64;
        }];
    };
    public type SubAccount = [Nat8];
    public type TimeStamp = { timestamp_nanos : Nat64 };
    public type Tokens = { e8s : Nat64 };
    public type Transaction = {
        memo : Memo;
        operation : ?Operation;
        created_at_time : TimeStamp;
    };
    public type TransferArgs = {
        to : AccountIdentifier;
        fee : Tokens;
        memo : Memo;
        from_subaccount : ?SubAccount;
        created_at_time : ?TimeStamp;
        amount : Tokens;
    };
    public type TransferError = {
        #TxTooOld : { allowed_window_nanos : Nat64 };
        #BadFee : { expected_fee : Tokens };
        #TxDuplicate : { duplicate_of : BlockIndex };
        #TxCreatedInFuture;
        #InsufficientFunds : { balance : Tokens };
    };
    public type TransferFee = { transfer_fee : Tokens };
    public type TransferFeeArg = {};
    public type TransferResult = { #Ok : BlockIndex; #Err : TransferError };
    
};
