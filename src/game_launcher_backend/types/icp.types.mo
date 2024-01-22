module {
  public type Account = { owner : Principal; subaccount : ?Blob };
  public type AccountBalanceArgs = { account : Text };
  public type Allowance = { allowance : Nat; expires_at : ?Nat64 };
  public type AllowanceArgs = { account : Account; spender : Account };
  public type ApproveArgs = {
    fee : ?Nat;
    memo : ?Blob;
    from_subaccount : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    spender : Account;
  };
  public type ApproveError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #AllowanceChanged : { current_allowance : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #Expired : { ledger_time : Nat64 };
    #InsufficientFunds : { balance : Nat };
  };
  public type ArchiveInfo = { canister_id : Principal };
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
    callback : shared query GetBlocksArgs -> async Result_3;
    start : Nat64;
    length : Nat64;
  };
  public type ArchivedEncodedBlocksRange = {
    callback : shared query GetBlocksArgs -> async Result_4;
    start : Nat64;
    length : Nat64;
  };
  public type Archives = { archives : [ArchiveInfo] };
  public type BinaryAccountBalanceArgs = { account : Blob };
  public type BlockRange = { blocks : [CandidBlock] };
  public type CandidBlock = {
    transaction : CandidTransaction;
    timestamp : TimeStamp;
    parent_hash : ?Blob;
  };
  public type CandidOperation = {
    #Approve : {
      fee : Tokens;
      from : Blob;
      allowance_e8s : Int;
      allowance : Tokens;
      expected_allowance : ?Tokens;
      expires_at : ?TimeStamp;
      spender : Blob;
    };
    #Burn : { from : Blob; amount : Tokens; spender : ?Blob };
    #Mint : { to : Blob; amount : Tokens };
    #Transfer : {
      to : Blob;
      fee : Tokens;
      from : Blob;
      amount : Tokens;
      spender : ?Blob;
    };
  };
  public type CandidTransaction = {
    memo : Nat64;
    icrc1_memo : ?Blob;
    operation : ?CandidOperation;
    created_at_time : TimeStamp;
  };
  public type Decimals = { decimals : Nat32 };
  public type Duration = { secs : Nat64; nanos : Nat32 };
  public type FeatureFlags = { icrc2 : Bool };
  public type GetBlocksArgs = { start : Nat64; length : Nat64 };
  public type GetBlocksError = {
    #BadFirstBlockIndex : {
      requested_index : Nat64;
      first_valid_index : Nat64;
    };
    #Other : { error_message : Text; error_code : Nat64 };
  };
  public type InitArgs = {
    send_whitelist : [Principal];
    token_symbol : ?Text;
    transfer_fee : ?Tokens;
    minting_account : Text;
    maximum_number_of_accounts : ?Nat64;
    accounts_overflow_trim_quantity : ?Nat64;
    transaction_window : ?Duration;
    max_message_size_bytes : ?Nat64;
    icrc1_minting_account : ?Account;
    archive_options : ?ArchiveOptions;
    initial_values : [(Text, Tokens)];
    token_name : ?Text;
    feature_flags : ?FeatureFlags;
  };
  public type LedgerCanisterPayload = {
    #Upgrade : ?UpgradeArgs;
    #Init : InitArgs;
  };
  public type MetadataValue = {
    #Int : Int;
    #Nat : Nat;
    #Blob : Blob;
    #Text : Text;
  };
  public type Name = { name : Text };
  public type QueryBlocksResponse = {
    certificate : ?Blob;
    blocks : [CandidBlock];
    chain_length : Nat64;
    first_block_index : Nat64;
    archived_blocks : [ArchivedBlocksRange];
  };
  public type QueryEncodedBlocksResponse = {
    certificate : ?Blob;
    blocks : [Blob];
    chain_length : Nat64;
    first_block_index : Nat64;
    archived_blocks : [ArchivedEncodedBlocksRange];
  };
  public type Result = { #Ok : Nat; #Err : TransferError };
  public type Result_1 = { #Ok : Nat; #Err : ApproveError };
  public type Result_2 = { #Ok : Nat; #Err : TransferFromError };
  public type Result_3 = { #Ok : BlockRange; #Err : GetBlocksError };
  public type Result_4 = { #Ok : [Blob]; #Err : GetBlocksError };
  public type Result_5 = { #Ok : Nat64; #Err : TransferError_1 };
  public type SendArgs = {
    to : Text;
    fee : Tokens;
    memo : Nat64;
    from_subaccount : ?Blob;
    created_at_time : ?TimeStamp;
    amount : Tokens;
  };
  public type StandardRecord = { url : Text; name : Text };
  public type Symbol = { symbol : Text };
  public type TimeStamp = { timestamp_nanos : Nat64 };
  public type Tokens = { e8s : Nat64 };
  public type TransferArg = {
    to : Account;
    fee : ?Nat;
    memo : ?Blob;
    from_subaccount : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };
  public type TransferArgs = {
    to : Blob;
    fee : Tokens;
    memo : Nat64;
    from_subaccount : ?Blob;
    created_at_time : ?TimeStamp;
    amount : Tokens;
  };
  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
  public type TransferError_1 = {
    #TxTooOld : { allowed_window_nanos : Nat64 };
    #BadFee : { expected_fee : Tokens };
    #TxDuplicate : { duplicate_of : Nat64 };
    #TxCreatedInFuture;
    #InsufficientFunds : { balance : Tokens };
  };
  public type TransferFee = { transfer_fee : Tokens };
  public type TransferFromArgs = {
    to : Account;
    fee : ?Nat;
    spender_subaccount : ?Blob;
    from : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };
  public type TransferFromError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #InsufficientAllowance : { allowance : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
  public type UpgradeArgs = {
    maximum_number_of_accounts : ?Nat64;
    icrc1_minting_account : ?Account;
    feature_flags : ?FeatureFlags;
  };
  public type Self = actor {
    account_balance : shared query BinaryAccountBalanceArgs -> async Tokens;
    account_balance_dfx : shared query AccountBalanceArgs -> async Tokens;
    account_identifier : shared query Account -> async Blob;
    archives : shared query () -> async Archives;
    decimals : shared query () -> async Decimals;
    icrc1_balance_of : shared query Account -> async Nat;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_metadata : shared query () -> async [(Text, MetadataValue)];
    icrc1_minting_account : shared query () -> async ?Account;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [StandardRecord];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Nat;
    icrc1_transfer : shared TransferArg -> async Result;
    icrc2_allowance : shared query AllowanceArgs -> async Allowance;
    icrc2_approve : shared ApproveArgs -> async Result_1;
    icrc2_transfer_from : shared TransferFromArgs -> async Result_2;
    name : shared query () -> async Name;
    query_blocks : shared query GetBlocksArgs -> async QueryBlocksResponse;
    query_encoded_blocks : shared query GetBlocksArgs -> async QueryEncodedBlocksResponse;
    send_dfx : shared SendArgs -> async Nat64;
    symbol : shared query () -> async Symbol;
    transfer : shared TransferArgs -> async Result_5;
    transfer_fee : shared query {} -> async TransferFee;
  }
}