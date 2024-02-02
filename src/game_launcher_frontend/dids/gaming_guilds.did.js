export const idlFactory = ({ IDL }) => {
  const IcrcTx = IDL.Record({
    'toPrincipal' : IDL.Text,
    'canister' : IDL.Text,
    'amount' : IDL.Float64,
  });
  const entityId = IDL.Text;
  const worldId = IDL.Text;
  const GreaterThanNumber = IDL.Record({
    'value' : IDL.Float64,
    'fieldName' : IDL.Text,
  });
  const EqualToText = IDL.Record({
    'value' : IDL.Text,
    'equal' : IDL.Bool,
    'fieldName' : IDL.Text,
  });
  const LowerThanOrEqualToNumber = IDL.Record({
    'value' : IDL.Float64,
    'fieldName' : IDL.Text,
  });
  const LessThanNumber = IDL.Record({
    'value' : IDL.Float64,
    'fieldName' : IDL.Text,
  });
  const GreaterThanNowTimestamp = IDL.Record({ 'fieldName' : IDL.Text });
  const Exist = IDL.Record({ 'value' : IDL.Bool });
  const LessThanNowTimestamp = IDL.Record({ 'fieldName' : IDL.Text });
  const ContainsText = IDL.Record({
    'contains' : IDL.Bool,
    'value' : IDL.Text,
    'fieldName' : IDL.Text,
  });
  const ExistField = IDL.Record({ 'value' : IDL.Bool, 'fieldName' : IDL.Text });
  const EqualToNumber = IDL.Record({
    'value' : IDL.Float64,
    'equal' : IDL.Bool,
    'fieldName' : IDL.Text,
  });
  const GreaterThanOrEqualToNumber = IDL.Record({
    'value' : IDL.Float64,
    'fieldName' : IDL.Text,
  });
  const EntityConstraintType = IDL.Variant({
    'greaterThanNumber' : GreaterThanNumber,
    'equalToText' : EqualToText,
    'lessThanEqualToNumber' : LowerThanOrEqualToNumber,
    'lessThanNumber' : LessThanNumber,
    'greaterThanNowTimestamp' : GreaterThanNowTimestamp,
    'exist' : Exist,
    'lessThanNowTimestamp' : LessThanNowTimestamp,
    'containsText' : ContainsText,
    'existField' : ExistField,
    'equalToNumber' : EqualToNumber,
    'greaterThanEqualToNumber' : GreaterThanOrEqualToNumber,
  });
  const EntityConstraint = IDL.Record({
    'eid' : entityId,
    'wid' : IDL.Opt(worldId),
    'entityConstraintType' : EntityConstraintType,
  });
  const NftTransfer = IDL.Record({ 'toPrincipal' : IDL.Text });
  const NftTx = IDL.Record({
    'metadata' : IDL.Opt(IDL.Text),
    'nftConstraintType' : IDL.Variant({
      'hold' : IDL.Variant({ 'originalEXT' : IDL.Null, 'boomEXT' : IDL.Null }),
      'transfer' : NftTransfer,
    }),
    'canister' : IDL.Text,
  });
  const ActionConstraint = IDL.Record({
    'icrcConstraint' : IDL.Vec(IcrcTx),
    'entityConstraint' : IDL.Vec(EntityConstraint),
    'nftConstraint' : IDL.Vec(NftTx),
    'timeConstraint' : IDL.Opt(
      IDL.Record({
        'actionExpirationTimestamp' : IDL.Opt(IDL.Nat),
        'actionTimeInterval' : IDL.Opt(
          IDL.Record({
            'intervalDuration' : IDL.Nat,
            'actionsPerInterval' : IDL.Nat,
          })
        ),
      })
    ),
  });
  const SetNumber = IDL.Record({
    'fieldName' : IDL.Text,
    'fieldValue' : IDL.Variant({
      'number' : IDL.Float64,
      'formula' : IDL.Text,
    }),
  });
  const SetText = IDL.Record({
    'fieldName' : IDL.Text,
    'fieldValue' : IDL.Text,
  });
  const IncrementNumber = IDL.Record({
    'fieldName' : IDL.Text,
    'fieldValue' : IDL.Variant({
      'number' : IDL.Float64,
      'formula' : IDL.Text,
    }),
  });
  const AddToList = IDL.Record({ 'value' : IDL.Text, 'fieldName' : IDL.Text });
  const DeleteEntity = IDL.Record({});
  const RemoveFromList = IDL.Record({
    'value' : IDL.Text,
    'fieldName' : IDL.Text,
  });
  const DecrementNumber = IDL.Record({
    'fieldName' : IDL.Text,
    'fieldValue' : IDL.Variant({
      'number' : IDL.Float64,
      'formula' : IDL.Text,
    }),
  });
  const DeleteField = IDL.Record({ 'fieldName' : IDL.Text });
  const RenewTimestamp = IDL.Record({
    'fieldName' : IDL.Text,
    'fieldValue' : IDL.Variant({
      'number' : IDL.Float64,
      'formula' : IDL.Text,
    }),
  });
  const UpdateEntityType = IDL.Variant({
    'setNumber' : SetNumber,
    'setText' : SetText,
    'incrementNumber' : IncrementNumber,
    'addToList' : AddToList,
    'deleteEntity' : DeleteEntity,
    'removeFromList' : RemoveFromList,
    'decrementNumber' : DecrementNumber,
    'deleteField' : DeleteField,
    'renewTimestamp' : RenewTimestamp,
  });
  const UpdateEntity = IDL.Record({
    'eid' : entityId,
    'wid' : IDL.Opt(worldId),
    'updates' : IDL.Vec(UpdateEntityType),
  });
  const TransferIcrc = IDL.Record({
    'canister' : IDL.Text,
    'quantity' : IDL.Float64,
  });
  const MintNft = IDL.Record({
    'assetId' : IDL.Text,
    'metadata' : IDL.Text,
    'canister' : IDL.Text,
  });
  const ActionOutcomeOption = IDL.Record({
    'weight' : IDL.Float64,
    'option' : IDL.Variant({
      'updateEntity' : UpdateEntity,
      'transferIcrc' : TransferIcrc,
      'mintNft' : MintNft,
    }),
  });
  const ActionOutcome = IDL.Record({
    'possibleOutcomes' : IDL.Vec(ActionOutcomeOption),
  });
  const ActionResult = IDL.Record({ 'outcomes' : IDL.Vec(ActionOutcome) });
  const SubAction = IDL.Record({
    'actionConstraint' : IDL.Opt(ActionConstraint),
    'actionResult' : ActionResult,
  });
  const Action = IDL.Record({
    'aid' : IDL.Text,
    'callerAction' : IDL.Opt(SubAction),
    'targetAction' : IDL.Opt(SubAction),
    'worldAction' : IDL.Opt(SubAction),
  });
  const Result_4 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const configId = IDL.Text;
  const Field = IDL.Record({ 'fieldName' : IDL.Text, 'fieldValue' : IDL.Text });
  const StableConfig = IDL.Record({
    'cid' : configId,
    'fields' : IDL.Vec(Field),
  });
  const EntitySchema = IDL.Record({
    'eid' : IDL.Text,
    'uid' : IDL.Text,
    'fields' : IDL.Vec(Field),
  });
  const ActionLockStateArgs = IDL.Record({
    'aid' : IDL.Text,
    'uid' : IDL.Text,
  });
  const Result_2 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
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
    'wid' : worldId,
    'fields' : IDL.Vec(Field),
  });
  const Result_5 = IDL.Variant({
    'ok' : IDL.Vec(StableEntity),
    'err' : IDL.Text,
  });
  const EntityPermission = IDL.Record({ 'eid' : entityId, 'wid' : worldId });
  const GlobalPermission = IDL.Record({ 'wid' : worldId });
  const ActionArg = IDL.Record({
    'fields' : IDL.Vec(Field),
    'actionId' : IDL.Text,
  });
  const ActionReturn = IDL.Record({
    'worldOutcomes' : IDL.Vec(ActionOutcomeOption),
    'targetOutcomes' : IDL.Vec(ActionOutcomeOption),
    'targetPrincipalId' : IDL.Text,
    'callerPrincipalId' : IDL.Text,
    'worldPrincipalId' : IDL.Text,
    'callerOutcomes' : IDL.Vec(ActionOutcomeOption),
  });
  const Result_3 = IDL.Variant({ 'ok' : ActionReturn, 'err' : IDL.Text });
  const actionId = IDL.Text;
  const BlockIndex__1 = IDL.Nat64;
  const Tokens__1 = IDL.Record({ 'e8s' : IDL.Nat64 });
  const TransferError__1 = IDL.Variant({
    'TxTooOld' : IDL.Record({ 'allowed_window_nanos' : IDL.Nat64 }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens__1 }),
    'TxDuplicate' : IDL.Record({ 'duplicate_of' : BlockIndex__1 }),
    'TxCreatedInFuture' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens__1 }),
  });
  const TransferResult__1 = IDL.Variant({
    'Ok' : BlockIndex__1,
    'Err' : TransferError__1,
  });
  const Result_1 = IDL.Variant({
    'ok' : TransferResult__1,
    'err' : IDL.Variant({ 'Err' : IDL.Text, 'TxErr' : TransferError__1 }),
  });
  const BlockIndex = IDL.Nat;
  const Tokens = IDL.Nat;
  const Timestamp = IDL.Nat64;
  const TransferError = IDL.Variant({
    'GenericError' : IDL.Record({
      'message' : IDL.Text,
      'error_code' : IDL.Nat,
    }),
    'TemporarilyUnavailable' : IDL.Null,
    'BadBurn' : IDL.Record({ 'min_burn_amount' : Tokens }),
    'Duplicate' : IDL.Record({ 'duplicate_of' : BlockIndex }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens }),
    'CreatedInFuture' : IDL.Record({ 'ledger_time' : Timestamp }),
    'TooOld' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens }),
  });
  const TransferResult = IDL.Variant({
    'Ok' : BlockIndex,
    'Err' : TransferError,
  });
  const Result = IDL.Variant({
    'ok' : TransferResult,
    'err' : IDL.Variant({ 'Err' : IDL.Text, 'TxErr' : TransferError }),
  });
  const WorldTemplate = IDL.Service({
    'addAdmin' : IDL.Func([IDL.Record({ 'principal' : IDL.Text })], [], []),
    'addTrustedOrigins' : IDL.Func(
        [IDL.Record({ 'originUrl' : IDL.Text })],
        [],
        [],
      ),
    'createAction' : IDL.Func([Action], [Result_4], []),
    'createConfig' : IDL.Func([StableConfig], [Result_4], []),
    'createEntity' : IDL.Func([EntitySchema], [Result_4], []),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'deleteAction' : IDL.Func(
        [IDL.Record({ 'aid' : IDL.Text })],
        [Result_4],
        [],
      ),
    'deleteActionLockState' : IDL.Func([ActionLockStateArgs], [], []),
    'deleteAllActionLockStates' : IDL.Func([], [], []),
    'deleteAllActions' : IDL.Func([], [Result_2], []),
    'deleteAllConfigs' : IDL.Func([], [Result_2], []),
    'deleteCache' : IDL.Func([], [], ['oneway']),
    'deleteConfig' : IDL.Func(
        [IDL.Record({ 'cid' : IDL.Text })],
        [Result_4],
        [],
      ),
    'deleteEntity' : IDL.Func(
        [IDL.Record({ 'eid' : IDL.Text, 'uid' : IDL.Text })],
        [Result_4],
        [],
      ),
    'editAction' : IDL.Func([IDL.Record({ 'aid' : IDL.Text })], [Action], []),
    'editConfig' : IDL.Func(
        [IDL.Record({ 'cid' : IDL.Text })],
        [StableConfig],
        [],
      ),
    'editEntity' : IDL.Func(
        [IDL.Record({ 'userId' : IDL.Text, 'entityId' : IDL.Text })],
        [EntitySchema],
        [],
      ),
    'exportActions' : IDL.Func([], [IDL.Vec(Action)], []),
    'exportConfigs' : IDL.Func([], [IDL.Vec(StableConfig)], []),
    'getActionLockState' : IDL.Func(
        [ActionLockStateArgs],
        [IDL.Bool],
        ['query'],
      ),
    'getAllActions' : IDL.Func([], [IDL.Vec(Action)], ['query']),
    'getAllConfigs' : IDL.Func([], [IDL.Vec(StableConfig)], ['query']),
    'getAllUserActionStates' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text })],
        [Result_6],
        [],
      ),
    'getAllUserEntities' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text, 'page' : IDL.Opt(IDL.Nat) })],
        [Result_5],
        [],
      ),
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
    'getProcessActionCount' : IDL.Func([], [IDL.Nat], ['query']),
    'get_trusted_origins' : IDL.Func([], [IDL.Vec(IDL.Text)], []),
    'grantEntityPermission' : IDL.Func([EntityPermission], [], []),
    'grantGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'importAllActionsOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_4],
        [],
      ),
    'importAllConfigsOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_4],
        [],
      ),
    'importAllPermissionsOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_4],
        [],
      ),
    'importAllUsersDataOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_4],
        [],
      ),
    'logsClear' : IDL.Func([], [], []),
    'logsGet' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'logsGetCount' : IDL.Func([], [IDL.Nat], ['query']),
    'processAction' : IDL.Func([ActionArg], [Result_3], []),
    'removeAdmin' : IDL.Func([IDL.Record({ 'principal' : IDL.Text })], [], []),
    'removeAllUserNodeRef' : IDL.Func([], [], []),
    'removeEntityPermission' : IDL.Func([EntityPermission], [], []),
    'removeGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'removeTrustedOrigins' : IDL.Func(
        [IDL.Record({ 'originUrl' : IDL.Text })],
        [],
        [],
      ),
    'resetActionsAndConfigsToHardcodedTemplate' : IDL.Func([], [Result_2], []),
    'validateConstraints' : IDL.Func(
        [IDL.Text, IDL.Vec(StableEntity), actionId, IDL.Opt(ActionConstraint)],
        [IDL.Record({ 'aid' : IDL.Text, 'status' : IDL.Bool })],
        [],
      ),
    'validateEntityConstraints' : IDL.Func(
        [IDL.Text, IDL.Vec(StableEntity), IDL.Vec(EntityConstraint)],
        [IDL.Bool],
        ['query'],
      ),
    'withdrawIcpFromWorld' : IDL.Func(
        [IDL.Record({ 'toPrincipal' : IDL.Text })],
        [Result_1],
        [],
      ),
    'withdrawIcrcFromWorld' : IDL.Func(
        [
          IDL.Record({
            'tokenCanisterId' : IDL.Text,
            'toPrincipal' : IDL.Text,
          }),
        ],
        [Result],
        [],
      ),
  });
  return WorldTemplate;
};
export const init = ({ IDL }) => { return []; };
