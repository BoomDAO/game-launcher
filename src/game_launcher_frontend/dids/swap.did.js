export const idlFactory = ({ IDL }) => {
  const MetadataValue = IDL.Variant({
    'Int' : IDL.Int,
    'Nat' : IDL.Nat,
    'Blob' : IDL.Vec(IDL.Nat8),
    'Text' : IDL.Text,
  });
  const Subaccount = IDL.Vec(IDL.Nat8);
  const Account__1 = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(Subaccount),
  });
  const FeatureFlags = IDL.Record({ 'icrc2' : IDL.Bool });
  const InitArgs = IDL.Record({
    'decimals' : IDL.Opt(IDL.Nat8),
    'token_symbol' : IDL.Text,
    'transfer_fee' : IDL.Nat,
    'metadata' : IDL.Vec(IDL.Tuple(IDL.Text, MetadataValue)),
    'minting_account' : Account__1,
    'initial_balances' : IDL.Vec(IDL.Tuple(Account__1, IDL.Nat)),
    'maximum_number_of_accounts' : IDL.Opt(IDL.Nat64),
    'accounts_overflow_trim_quantity' : IDL.Opt(IDL.Nat64),
    'fee_collector_account' : IDL.Opt(Account__1),
    'archive_options' : IDL.Record({
      'num_blocks_to_archive' : IDL.Nat64,
      'max_transactions_per_response' : IDL.Opt(IDL.Nat64),
      'trigger_threshold' : IDL.Nat64,
      'max_message_size_bytes' : IDL.Opt(IDL.Nat64),
      'cycles_for_archive_creation' : IDL.Opt(IDL.Nat64),
      'node_max_memory_size_bytes' : IDL.Opt(IDL.Nat64),
      'controller_id' : IDL.Principal,
    }),
    'max_memo_length' : IDL.Opt(IDL.Nat16),
    'token_name' : IDL.Text,
    'feature_flags' : IDL.Opt(FeatureFlags),
  });
  const TokenProject = IDL.Record({
    'creator' : IDL.Text,
    'metadata' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
    'name' : IDL.Text,
    'description' : IDL.Variant({
      'formattedText' : IDL.Text,
      'plainText' : IDL.Text,
    }),
    'website' : IDL.Text,
    'bannerUrl' : IDL.Text,
    'creatorImageUrl' : IDL.Text,
    'creatorAbout' : IDL.Text,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const Token = IDL.Record({
    'fee' : IDL.Nat,
    'decimals' : IDL.Opt(IDL.Nat8),
    'logo' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'token_canister_id' : IDL.Text,
    'symbol' : IDL.Text,
  });
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(IDL.Vec(IDL.Nat8)),
  });
  const BlockIndex__1 = IDL.Nat;
  const Tokens__1 = IDL.Nat;
  const Timestamp = IDL.Nat64;
  const TransferError__1 = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TemporarilyUnavailable' : IDL.Null,
    'BadBurn' : IDL.Record({ 'min_burn_amount' : Tokens__1 }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : BlockIndex__1 }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens__1 }),
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : Timestamp }),
    'TooOld' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens__1 }),
  });
  const TransferResult__1 = IDL.Variant({
    'Ok' : BlockIndex__1,
    'Err' : TransferError__1,
  });
  const Icrc1BlockIndex = IDL.Nat;
  const Icrc1Tokens = IDL.Nat;
  const Icrc1TransferError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TemporarilyUnavailable' : IDL.Null,
    'BadBurn' : IDL.Record({ 'min_burn_amount' : Icrc1Tokens }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : Icrc1BlockIndex }),
    'BadFee' : IDL.Record({ 'expected_fee' : Icrc1Tokens }),
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'TooOld' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Icrc1Tokens }),
  });
  const Icrc1TransferResult = IDL.Variant({
    'Ok' : Icrc1BlockIndex,
    'Err' : Icrc1TransferError,
  });
  const AccountIdentifier = IDL.Text;
  const BlockIndex = IDL.Nat64;
  const Tokens = IDL.Record({ 'e8s' : IDL.Nat64 });
  const TransferError = IDL.Variant({
    'TxTooOld' : IDL.Record({ 'allowed_window_nanos' : IDL.Nat64 }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens }),
    'TxDuplicate' : IDL.Record({ 'duplicate_of' : BlockIndex }),
    'TxCreatedInFuture' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens }),
  });
  const TransferResult = IDL.Variant({
    'Ok' : BlockIndex,
    'Err' : TransferError,
  });
  const SupplyConfigs = IDL.Record({
    'participants' : IDL.Record({ 'icrc' : IDL.Nat }),
    'team' : IDL.Record({
      'icp' : IDL.Nat64,
      'icrc' : IDL.Nat,
      'account' : Account,
      'icrc_result' : IDL.Opt(TransferResult__1),
      'icp_result' : IDL.Opt(Icrc1TransferResult),
    }),
    'boom_dao' : IDL.Record({
      'icp' : IDL.Nat64,
      'icrc' : IDL.Nat,
      'icp_account' : AccountIdentifier,
      'icrc_result' : IDL.Opt(TransferResult__1),
      'icrc_account' : Account,
      'icp_result' : IDL.Opt(TransferResult),
    }),
    'liquidity_pool' : IDL.Record({
      'icp' : IDL.Nat64,
      'icrc' : IDL.Nat,
      'account' : Account,
      'icrc_result' : IDL.Opt(TransferResult__1),
      'icp_result' : IDL.Opt(Icrc1TransferResult),
    }),
    'gaming_guilds' : IDL.Record({
      'icp' : IDL.Nat64,
      'icrc' : IDL.Nat,
      'account' : Account,
      'icrc_result' : IDL.Opt(TransferResult__1),
      'icp_result' : IDL.Opt(Icrc1TransferResult),
    }),
  });
  const TokenSwapConfigs = IDL.Record({
    'min_participant_icp_e8s' : IDL.Nat64,
    'max_icp_e8s' : IDL.Nat64,
    'swap_start_timestamp_seconds' : IDL.Int,
    'swap_due_timestamp_seconds' : IDL.Int,
    'token_supply_configs' : SupplyConfigs,
    'max_participant_icp_e8s' : IDL.Nat64,
    'min_icp_e8s' : IDL.Nat64,
  });
  const TokenInfo = IDL.Record({
    'token_canister_id' : IDL.Text,
    'token_swap_configs' : TokenSwapConfigs,
    'token_configs' : Token,
    'token_project_configs' : TokenProject,
  });
  const TokensInfo = IDL.Record({
    'active' : IDL.Vec(TokenInfo),
    'inactive' : IDL.Vec(TokenInfo),
  });
  const Result_2 = IDL.Variant({ 'ok' : TokensInfo, 'err' : IDL.Text });
  const Result_1 = IDL.Variant({ 'ok' : TokenSwapConfigs, 'err' : IDL.Text });
  return IDL.Service({
    'create_icrc_token' : IDL.Func(
        [IDL.Record({ 'token_init_arg' : InitArgs, 'project' : TokenProject })],
        [IDL.Record({ 'canister_id' : IDL.Text })],
        [],
      ),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'finalise_token_swap' : IDL.Func(
        [IDL.Record({ 'canister_id' : IDL.Text })],
        [Result],
        [],
      ),
    'getAllTokenDetails' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, Token))],
        ['query'],
      ),
    'getAllTokensInfo' : IDL.Func([], [Result_2], ['query']),
    'getLedgerWasmDetails' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Nat32, IDL.Vec(IDL.Nat8)))],
        ['query'],
      ),
    'getTotalLedgerWasms' : IDL.Func([], [IDL.Nat], ['query']),
    'list_icrc_token' : IDL.Func([Token], [], []),
    'participate_in_token_swap' : IDL.Func(
        [
          IDL.Record({
            'canister_id' : IDL.Text,
            'blockIndex' : IDL.Nat64,
            'amount' : Tokens,
          }),
        ],
        [Result],
        [],
      ),
    'removeLedgerWasmVersion' : IDL.Func(
        [IDL.Record({ 'version' : IDL.Nat32 })],
        [],
        [],
      ),
    'set_token_swap_configs' : IDL.Func(
        [
          IDL.Record({
            'configs' : TokenSwapConfigs,
            'canister_id' : IDL.Text,
          }),
        ],
        [Result_1],
        [],
      ),
    'settle_swap_status_and_allocate_tokens_if_swap_successfull' : IDL.Func(
        [IDL.Record({ 'canister_id' : IDL.Text })],
        [Result],
        [],
      ),
    'start_token_swap' : IDL.Func(
        [IDL.Record({ 'canister_id' : IDL.Text })],
        [Result],
        [],
      ),
    'total_icp_contributed_e8s' : IDL.Func(
        [IDL.Record({ 'canister_id' : IDL.Text })],
        [IDL.Nat64],
        ['query'],
      ),
    'total_icp_contributed_e8s_and_total_participants' : IDL.Func(
        [IDL.Record({ 'canister_id' : IDL.Text })],
        [IDL.Tuple(IDL.Nat64, IDL.Nat)],
        ['query'],
      ),
    'upload_ledger_wasm' : IDL.Func(
        [IDL.Record({ 'ledger_wasm' : IDL.Vec(IDL.Nat8) })],
        [],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
