module {
  public type Account = { owner : Principal; subaccount : ?SubAccount };
  public type AccountBalanceArgs = { account : AccountIdentifier };
  public type AccountBalanceArgsDfx = { account : TextAccountIdentifier };
  public type AccountIdentifier = Blob;
  public type Allowance = {
    allowance : Icrc1Tokens;
    expires_at : ?Icrc1Timestamp;
  };
  public type AllowanceArgs = { account : Account; spender : Account };
  public type ApproveArgs = {
    fee : ?Icrc1Tokens;
    memo : ?Blob;
    from_subaccount : ?SubAccount;
    created_at_time : ?Icrc1Timestamp;
    amount : Icrc1Tokens;
    expected_allowance : ?Icrc1Tokens;
    expires_at : ?Icrc1Timestamp;
    spender : Account;
  };
  public type ApproveError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #Duplicate : { duplicate_of : Icrc1BlockIndex };
    #BadFee : { expected_fee : Icrc1Tokens };
    #AllowanceChanged : { current_allowance : Icrc1Tokens };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #Expired : { ledger_time : Nat64 };
    #InsufficientFunds : { balance : Icrc1Tokens };
  };
  public type ApproveResult = { #Ok : Icrc1BlockIndex; #Err : ApproveError };
  public type Archive = { canister_id : Principal };
  public type ArchiveOptions = {
    num_blocks_to_archive : Nat64;
    max_transactions_per_response : ?Nat64;
    trigger_threshold : Nat64;
    max_message_size_bytes : ?Nat64;
    cycles_for_archive_creation : ?Nat64;
    node_max_memory_size_bytes : ?Nat64;
    controller_id : Principal;
  };
  public type ArchivedBlocksRange = {
    callback : QueryArchiveFn;
    start : BlockIndex;
    length : Nat64;
  };
  public type ArchivedEncodedBlocksRange = {
    callback : shared query GetBlocksArgs -> async {
        #Ok : [Blob];
        #Err : QueryArchiveError;
      };
    start : Nat64;
    length : Nat64;
  };
  public type Archives = { archives : [Archive] };
  public type Block = {
    transaction : Transaction;
    timestamp : TimeStamp;
    parent_hash : ?Blob;
  };
  public type BlockIndex = Nat64;
  public type BlockRange = { blocks : [Block] };
  public type Duration = { secs : Nat64; nanos : Nat32 };
  public type FeatureFlags = { icrc2 : Bool };
  public type GetBlocksArgs = { start : BlockIndex; length : Nat64 };
  public type Icrc1BlockIndex = Nat;
  public type Icrc1Timestamp = Nat64;
  public type Icrc1Tokens = Nat;
  public type Icrc1TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Icrc1Tokens };
    #Duplicate : { duplicate_of : Icrc1BlockIndex };
    #BadFee : { expected_fee : Icrc1Tokens };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Icrc1Tokens };
  };
  public type Icrc1TransferResult = {
    #Ok : Icrc1BlockIndex;
    #Err : Icrc1TransferError;
  };
  public type InitArgs = {
    send_whitelist : [Principal];
    token_symbol : ?Text;
    transfer_fee : ?Tokens;
    minting_account : TextAccountIdentifier;
    maximum_number_of_accounts : ?Nat64;
    accounts_overflow_trim_quantity : ?Nat64;
    transaction_window : ?Duration;
    max_message_size_bytes : ?Nat64;
    icrc1_minting_account : ?Account;
    archive_options : ?ArchiveOptions;
    initial_values : [(TextAccountIdentifier, Tokens)];
    token_name : ?Text;
    feature_flags : ?FeatureFlags;
  };
  public type LedgerCanisterPayload = {
    #Upgrade : ?UpgradeArgs;
    #Init : InitArgs;
  };
  public type Memo = Nat64;
  public type Operation = {
    #Approve : {
      fee : Tokens;
      from : AccountIdentifier;
      allowance_e8s : Int;
      allowance : Tokens;
      expected_allowance : ?Tokens;
      expires_at : ?TimeStamp;
      spender : AccountIdentifier;
    };
    #Burn : {
      from : AccountIdentifier;
      amount : Tokens;
      spender : ?AccountIdentifier;
    };
    #Mint : { to : AccountIdentifier; amount : Tokens };
    #Transfer : {
      to : AccountIdentifier;
      fee : Tokens;
      from : AccountIdentifier;
      amount : Tokens;
      spender : ?Blob;
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
    certificate : ?Blob;
    blocks : [Block];
    chain_length : Nat64;
    first_block_index : BlockIndex;
    archived_blocks : [ArchivedBlocksRange];
  };
  public type QueryEncodedBlocksResponse = {
    certificate : ?Blob;
    blocks : [Blob];
    chain_length : Nat64;
    first_block_index : Nat64;
    archived_blocks : [ArchivedEncodedBlocksRange];
  };
  public type SendArgs = {
    to : TextAccountIdentifier;
    fee : Tokens;
    memo : Memo;
    from_subaccount : ?SubAccount;
    created_at_time : ?TimeStamp;
    amount : Tokens;
  };
  public type SubAccount = Blob;
  public type TextAccountIdentifier = Text;
  public type TimeStamp = { timestamp_nanos : Nat64 };
  public type Tokens = { e8s : Nat64 };
  public type Transaction = {
    memo : Memo;
    icrc1_memo : ?Blob;
    operation : ?Operation;
    created_at_time : TimeStamp;
  };
  public type TransferArg = {
    to : Account;
    fee : ?Icrc1Tokens;
    memo : ?Blob;
    from_subaccount : ?SubAccount;
    created_at_time : ?Icrc1Timestamp;
    amount : Icrc1Tokens;
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
  public type TransferFromArgs = {
    to : Account;
    fee : ?Icrc1Tokens;
    spender_subaccount : ?SubAccount;
    from : Account;
    memo : ?Blob;
    created_at_time : ?Icrc1Timestamp;
    amount : Icrc1Tokens;
  };
  public type TransferFromError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #InsufficientAllowance : { allowance : Icrc1Tokens };
    #BadBurn : { min_burn_amount : Icrc1Tokens };
    #Duplicate : { duplicate_of : Icrc1BlockIndex };
    #BadFee : { expected_fee : Icrc1Tokens };
    #CreatedInFuture : { ledger_time : Icrc1Timestamp };
    #TooOld;
    #InsufficientFunds : { balance : Icrc1Tokens };
  };
  public type TransferFromResult = {
    #Ok : Icrc1BlockIndex;
    #Err : TransferFromError;
  };
  public type TransferResult = { #Ok : BlockIndex; #Err : TransferError };
  public type UpgradeArgs = {
    maximum_number_of_accounts : ?Nat64;
    icrc1_minting_account : ?Account;
    feature_flags : ?FeatureFlags;
  };
  public type Value = { #Int : Int; #Nat : Nat; #Blob : Blob; #Text : Text };
  public type Self = actor {
    account_balance : shared query AccountBalanceArgs -> async Tokens;
    account_balance_dfx : shared query AccountBalanceArgsDfx -> async Tokens;
    account_identifier : shared query Account -> async AccountIdentifier;
    archives : shared query () -> async Archives;
    decimals : shared query () -> async { decimals : Nat32 };
    icrc1_balance_of : shared query Account -> async Icrc1Tokens;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Icrc1Tokens;
    icrc1_metadata : shared query () -> async [(Text, Value)];
    icrc1_minting_account : shared query () -> async ?Account;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [
        { url : Text; name : Text }
      ];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Icrc1Tokens;
    icrc1_transfer : shared TransferArg -> async Icrc1TransferResult;
    icrc2_allowance : shared query AllowanceArgs -> async Allowance;
    icrc2_approve : shared ApproveArgs -> async ApproveResult;
    icrc2_transfer_from : shared TransferFromArgs -> async TransferFromResult;
    name : shared query () -> async { name : Text };
    query_blocks : shared query GetBlocksArgs -> async QueryBlocksResponse;
    query_encoded_blocks : shared query GetBlocksArgs -> async QueryEncodedBlocksResponse;
    send_dfx : shared SendArgs -> async BlockIndex;
    symbol : shared query () -> async { symbol : Text };
    transfer : shared TransferArgs -> async TransferResult;
    transfer_fee : shared query TransferFeeArg -> async TransferFee;
  }
}