export const idlFactory = ({ IDL }) => {
  const entityId = IDL.Text;
  const groupId = IDL.Text;
  const worldId = IDL.Text;
  const ActionConstraint = IDL.Record({
    'entityConstraint' : IDL.Opt(
      IDL.Vec(
        IDL.Record({
          'eid' : entityId,
          'gid' : groupId,
          'wid' : IDL.Opt(worldId),
          'fieldName' : IDL.Text,
          'validation' : IDL.Variant({
            'greaterThanNumber' : IDL.Float64,
            'lessThanEqualToNumber' : IDL.Float64,
            'lessThanNumber' : IDL.Float64,
            'equalToString' : IDL.Text,
            'greaterThanNowTimestamp' : IDL.Null,
            'lessThanNowTimestamp' : IDL.Null,
            'equalToNumber' : IDL.Float64,
            'greaterThanEqualToNumber' : IDL.Float64,
          }),
        })
      )
    ),
    'timeConstraint' : IDL.Opt(
      IDL.Record({
        'intervalDuration' : IDL.Nat,
        'actionsPerInterval' : IDL.Nat,
      })
    ),
  });
  const SetNumber = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : IDL.Opt(worldId),
    'field' : IDL.Text,
    'value' : IDL.Float64,
  });
  const MintToken = IDL.Record({
    'canister' : IDL.Text,
    'quantity' : IDL.Float64,
  });
  const IncrementNumber = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : IDL.Opt(worldId),
    'field' : IDL.Text,
    'value' : IDL.Float64,
  });
  const MintNft = IDL.Record({
    'assetId' : IDL.Text,
    'metadata' : IDL.Text,
    'canister' : IDL.Text,
    'index' : IDL.Opt(IDL.Nat32),
  });
  const DeleteEntity = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : IDL.Opt(worldId),
  });
  const SetString = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : IDL.Opt(worldId),
    'field' : IDL.Text,
    'value' : IDL.Text,
  });
  const DecrementNumber = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : IDL.Opt(worldId),
    'field' : IDL.Text,
    'value' : IDL.Float64,
  });
  const RenewTimestamp = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : IDL.Opt(worldId),
    'field' : IDL.Text,
    'value' : IDL.Nat,
  });
  const ActionOutcomeOption = IDL.Record({
    'weight' : IDL.Float64,
    'option' : IDL.Variant({
      'setNumber' : SetNumber,
      'mintToken' : MintToken,
      'incrementNumber' : IncrementNumber,
      'mintNft' : MintNft,
      'deleteEntity' : DeleteEntity,
      'setString' : SetString,
      'decrementNumber' : DecrementNumber,
      'renewTimestamp' : RenewTimestamp,
    }),
  });
  const ActionOutcome = IDL.Record({
    'possibleOutcomes' : IDL.Vec(ActionOutcomeOption),
  });
  const ActionResult = IDL.Record({ 'outcomes' : IDL.Vec(ActionOutcome) });
  const ActionPlugin = IDL.Variant({
    'verifyTransferIcp' : IDL.Record({
      'amt' : IDL.Float64,
      'toPrincipal' : IDL.Text,
    }),
    'verifyTransferIcrc' : IDL.Record({
      'amt' : IDL.Float64,
      'toPrincipal' : IDL.Text,
      'canister' : IDL.Text,
    }),
    'claimStakingRewardIcp' : IDL.Record({ 'requiredAmount' : IDL.Float64 }),
    'claimStakingRewardNft' : IDL.Record({
      'canister' : IDL.Text,
      'requiredAmount' : IDL.Nat,
    }),
    'verifyBurnNfts' : IDL.Record({
      'canister' : IDL.Text,
      'requiredNftMetadata' : IDL.Opt(IDL.Vec(IDL.Text)),
    }),
    'claimStakingRewardIcrc' : IDL.Record({
      'canister' : IDL.Text,
      'requiredAmount' : IDL.Float64,
    }),
  });
  const Action = IDL.Record({
    'aid' : IDL.Text,
    'tag' : IDL.Opt(IDL.Text),
    'actionConstraint' : IDL.Opt(ActionConstraint),
    'name' : IDL.Opt(IDL.Text),
    'actionResult' : ActionResult,
    'description' : IDL.Opt(IDL.Text),
    'imageUrl' : IDL.Opt(IDL.Text),
    'actionPlugin' : IDL.Opt(ActionPlugin),
  });
  const Result_2 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const configId = IDL.Text;
  const StableConfig = IDL.Record({
    'cid' : configId,
    'fields' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
  });
  const ActionState = IDL.Record({
    'actionCount' : IDL.Nat,
    'intervalStartTs' : IDL.Nat,
    'actionId' : IDL.Text,
  });
  const Result_6 = IDL.Variant({
    'ok' : IDL.Vec(ActionState),
    'err' : IDL.Text,
  });
  const StableEntity = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : worldId,
    'fields' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
  });
  const Result_5 = IDL.Variant({
    'ok' : IDL.Vec(StableEntity),
    'err' : IDL.Text,
  });
  const EntityPermission = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : worldId,
  });
  const GlobalPermission = IDL.Record({ 'wid' : worldId });
  const ActionArg = IDL.Variant({
    'verifyTransferIcp' : IDL.Record({
      'blockIndex' : IDL.Nat64,
      'actionId' : IDL.Text,
    }),
    'verifyTransferIcrc' : IDL.Record({
      'blockIndex' : IDL.Nat,
      'actionId' : IDL.Text,
    }),
    'claimStakingRewardIcp' : IDL.Record({ 'actionId' : IDL.Text }),
    'claimStakingRewardNft' : IDL.Record({ 'actionId' : IDL.Text }),
    'verifyBurnNfts' : IDL.Record({
      'indexes' : IDL.Vec(IDL.Nat32),
      'actionId' : IDL.Text,
    }),
    'default' : IDL.Record({ 'actionId' : IDL.Text }),
    'claimStakingRewardIcrc' : IDL.Record({ 'actionId' : IDL.Text }),
  });
  const Result_4 = IDL.Variant({
    'ok' : IDL.Vec(ActionOutcomeOption),
    'err' : IDL.Text,
  });
  const Result_3 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
  const BlockIndex = IDL.Nat64;
  const Tokens = IDL.Record({ 'e8s' : IDL.Nat64 });
  const TransferError__1 = IDL.Variant({
    'TxTooOld' : IDL.Record({ 'allowed_window_nanos' : IDL.Nat64 }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens }),
    'TxDuplicate' : IDL.Record({ 'duplicate_of' : BlockIndex }),
    'TxCreatedInFuture' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens }),
  });
  const TransferResult = IDL.Variant({
    'Ok' : BlockIndex,
    'Err' : TransferError__1,
  });
  const Result_1 = IDL.Variant({
    'ok' : TransferResult,
    'err' : IDL.Variant({ 'Err' : IDL.Text, 'TxErr' : TransferError__1 }),
  });
  const TransferError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TemporarilyUnavailable' : IDL.Null,
    'BadBurn' : IDL.Record({ 'min_burn_amount' : IDL.Nat }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : IDL.Nat }),
    'BadFee' : IDL.Record({ 'expected_fee' : IDL.Nat }),
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : IDL.Nat64 }),
    'TooOld' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : IDL.Nat }),
  });
  const Result__1 = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : TransferError });
  const Result = IDL.Variant({
    'ok' : Result__1,
    'err' : IDL.Variant({ 'Err' : IDL.Text, 'TxErr' : TransferError }),
  });
  const WorldTemplate = IDL.Service({
    'addAdmin' : IDL.Func([IDL.Text], [], []),
    'createAction' : IDL.Func([Action], [Result_2], []),
    'createConfig' : IDL.Func([StableConfig], [Result_2], []),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'deleteAction' : IDL.Func([IDL.Text], [Result_2], []),
    'deleteConfig' : IDL.Func([IDL.Text], [Result_2], []),
    'exportActions' : IDL.Func([], [IDL.Vec(Action)], []),
    'exportConfigs' : IDL.Func([], [IDL.Vec(StableConfig)], []),
    'getAllActions' : IDL.Func([], [IDL.Vec(Action)], ['query']),
    'getAllConfigs' : IDL.Func([], [IDL.Vec(StableConfig)], ['query']),
    'getAllUserActionStates' : IDL.Func([IDL.Principal], [Result_6], []),
    'getAllUserEntities' : IDL.Func([IDL.Principal], [Result_5], []),
    'getEntityPermissionsOfWorld' : IDL.Func(
        [],
        [
          IDL.Vec(
            IDL.Tuple(IDL.Text, IDL.Vec(IDL.Tuple(IDL.Text, EntityPermission)))
          ),
        ],
        [],
      ),
    'getGlobalPermissionsOfWorld' : IDL.Func([], [IDL.Vec(worldId)], []),
    'getOwner' : IDL.Func([], [IDL.Text], ['query']),
    'grantEntityPermission' : IDL.Func([EntityPermission], [], []),
    'grantGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'importAllActionsOfWorld' : IDL.Func([IDL.Text], [Result_2], []),
    'importAllConfigsOfWorld' : IDL.Func([IDL.Text], [Result_2], []),
    'importAllPermissionsOfWorld' : IDL.Func([IDL.Text], [Result_2], []),
    'importAllUsersDataOfWorld' : IDL.Func([IDL.Text], [Result_2], []),
    'processAction' : IDL.Func([ActionArg], [Result_4], []),
    'removeAdmin' : IDL.Func([IDL.Text], [], []),
    'removeAllUserNodeRef' : IDL.Func([], [], []),
    'removeEntityPermission' : IDL.Func([EntityPermission], [], []),
    'removeGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'resetActions' : IDL.Func([], [Result_3], []),
    'resetConfig' : IDL.Func([], [Result_3], []),
    'updateAction' : IDL.Func([Action], [Result_2], []),
    'updateConfig' : IDL.Func([StableConfig], [Result_2], []),
    'withdrawIcpFromPaymentHub' : IDL.Func([], [Result_1], []),
    'withdrawIcrcFromPaymentHub' : IDL.Func([IDL.Text], [Result], []),
  });
  return WorldTemplate;
};
  export const init = ({ IDL }) => { return []; };
  