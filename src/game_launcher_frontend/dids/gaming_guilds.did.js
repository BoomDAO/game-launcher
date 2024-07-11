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
  const actionId = IDL.Text;
  const DecrementActionCount = IDL.Record({
    'value' : IDL.Variant({ 'number' : IDL.Float64, 'formula' : IDL.Text }),
  });
  const UpdateActionType = IDL.Variant({
    'decrementActionCount' : DecrementActionCount,
  });
  const UpdateAction = IDL.Record({
    'aid' : actionId,
    'updates' : IDL.Vec(UpdateActionType),
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
  const ActionConstraint = IDL.Record({
    'icrcConstraint' : IDL.Vec(IcrcTx),
    'entityConstraint' : IDL.Vec(EntityConstraint),
    'nftConstraint' : IDL.Vec(NftTx),
    'timeConstraint' : IDL.Opt(
      IDL.Record({
        'actionExpirationTimestamp' : IDL.Opt(IDL.Nat),
        'actionHistory' : IDL.Vec(
          IDL.Variant({
            'updateEntity' : UpdateEntity,
            'updateAction' : UpdateAction,
            'transferIcrc' : TransferIcrc,
            'mintNft' : MintNft,
          })
        ),
        'actionStartTimestamp' : IDL.Opt(IDL.Nat),
        'actionTimeInterval' : IDL.Opt(
          IDL.Record({
            'intervalDuration' : IDL.Nat,
            'actionsPerInterval' : IDL.Nat,
          })
        ),
      })
    ),
  });
  const ActionOutcomeOption = IDL.Record({
    'weight' : IDL.Float64,
    'option' : IDL.Variant({
      'updateEntity' : UpdateEntity,
      'updateAction' : UpdateAction,
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
  const Result_2 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
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
  const userId = IDL.Text;
  const ActionLockStateArgs = IDL.Record({
    'aid' : IDL.Text,
    'uid' : IDL.Text,
  });
  const Result_3 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
  const Result_10 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const ActionOutcomeHistory = IDL.Record({
    'wid' : worldId,
    'appliedAt' : IDL.Nat,
    'option' : IDL.Variant({
      'updateEntity' : UpdateEntity,
      'updateAction' : UpdateAction,
      'transferIcrc' : TransferIcrc,
      'mintNft' : MintNft,
    }),
  });
  const Result_9 = IDL.Variant({
    'ok' : IDL.Vec(ActionOutcomeHistory),
    'err' : IDL.Text,
  });
  const ConstraintStatus = IDL.Record({
    'eid' : IDL.Text,
    'expectedValue' : IDL.Text,
    'currentValue' : IDL.Text,
    'fieldName' : IDL.Text,
  });
  const ActionStatusReturn = IDL.Record({
    'entitiesStatus' : IDL.Vec(ConstraintStatus),
    'timeStatus' : IDL.Record({
      'nextAvailableTimestamp' : IDL.Opt(IDL.Nat),
      'actionsLeft' : IDL.Opt(IDL.Nat),
    }),
    'actionHistoryStatus' : IDL.Vec(ConstraintStatus),
    'isValid' : IDL.Bool,
  });
  const Result_8 = IDL.Variant({ 'ok' : ActionStatusReturn, 'err' : IDL.Text });
  const ActionState = IDL.Record({
    'actionCount' : IDL.Nat,
    'intervalStartTs' : IDL.Nat,
    'actionId' : IDL.Text,
  });
  const Result_7 = IDL.Variant({
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
  const ICRCStakeKind = IDL.Variant({ 'pro' : IDL.Null, 'elite' : IDL.Null });
  const ICRCStake = IDL.Record({
    'staker' : IDL.Text,
    'dissolvedAt' : IDL.Int,
    'stakedAt' : IDL.Int,
    'kind' : ICRCStakeKind,
    'tokenCanisterId' : IDL.Text,
    'amount' : IDL.Nat,
  });
  const Result_6 = IDL.Variant({ 'ok' : ICRCStake, 'err' : IDL.Text });
  const EXTStake = IDL.Record({
    'staker' : IDL.Text,
    'dissolvedAt' : IDL.Int,
    'stakedAt' : IDL.Int,
    'tokenIndex' : IDL.Nat32,
  });
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
  const Result_4 = IDL.Variant({ 'ok' : ActionReturn, 'err' : IDL.Text });
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
    'createAction' : IDL.Func([Action], [Result_2], []),
    'createConfig' : IDL.Func([StableConfig], [Result_2], []),
    'createEntity' : IDL.Func([EntitySchema], [Result_2], []),
    'createEntityForAllUsers' : IDL.Func(
        [IDL.Record({ 'eid' : entityId, 'fields' : IDL.Vec(Field) })],
        [Result_2],
        [],
      ),
    'createTestQuestActions' : IDL.Func(
        [
          IDL.Record({
            'actionId_1' : IDL.Text,
            'actionId_2' : IDL.Text,
            'game_world_canister_id' : IDL.Text,
          }),
        ],
        [Result_2],
        [],
      ),
    'createTestQuestConfigs' : IDL.Func(
        [
          IDL.Vec(
            IDL.Record({
              'cid' : IDL.Text,
              'image_url' : IDL.Text,
              'name' : IDL.Text,
              'description' : IDL.Text,
              'quest_url' : IDL.Text,
            })
          ),
        ],
        [Result_2],
        [],
      ),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'deleteAction' : IDL.Func(
        [IDL.Record({ 'aid' : IDL.Text })],
        [Result_2],
        [],
      ),
    'deleteActionHistoryForUser' : IDL.Func(
        [IDL.Record({ 'uid' : userId })],
        [],
        [],
      ),
    'deleteActionLockState' : IDL.Func([ActionLockStateArgs], [], []),
    'deleteActionStateForAllUsers' : IDL.Func(
        [IDL.Record({ 'aid' : IDL.Text })],
        [Result_3],
        [],
      ),
    'deleteActionStateForUser' : IDL.Func(
        [IDL.Record({ 'aid' : IDL.Text, 'uid' : IDL.Text })],
        [Result_10],
        [],
      ),
    'deleteAllActionLockStates' : IDL.Func([], [], []),
    'deleteAllActions' : IDL.Func([], [Result_3], []),
    'deleteAllConfigs' : IDL.Func([], [Result_3], []),
    'deleteCache' : IDL.Func([], [], ['oneway']),
    'deleteConfig' : IDL.Func(
        [IDL.Record({ 'cid' : IDL.Text })],
        [Result_2],
        [],
      ),
    'deleteEntity' : IDL.Func(
        [IDL.Record({ 'eid' : IDL.Text, 'uid' : IDL.Text })],
        [Result_2],
        [],
      ),
    'deleteTestQuestActionStateForUser' : IDL.Func(
        [IDL.Record({ 'aid' : IDL.Text })],
        [Result_10],
        [],
      ),
    'deleteUser' : IDL.Func([IDL.Record({ 'uid' : userId })], [], []),
    'disburseBOOMStake' : IDL.Func([], [Result_2], []),
    'disburseExtNft' : IDL.Func([IDL.Text, IDL.Nat32], [Result_2], []),
    'dissolveBoomStake' : IDL.Func([], [Result_2], []),
    'dissolveExtNft' : IDL.Func([IDL.Text, IDL.Nat32], [Result_2], []),
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
    'getActionHistory' : IDL.Func(
        [IDL.Record({ 'uid' : userId })],
        [Result_9],
        [],
      ),
    'getActionHistoryComposite' : IDL.Func(
        [IDL.Record({ 'uid' : userId })],
        [Result_9],
        ['composite_query'],
      ),
    'getActionLockState' : IDL.Func(
        [ActionLockStateArgs],
        [IDL.Bool],
        ['query'],
      ),
    'getActionStatusComposite' : IDL.Func(
        [IDL.Record({ 'aid' : actionId, 'uid' : IDL.Text })],
        [Result_8],
        ['composite_query'],
      ),
    'getAllActions' : IDL.Func([], [IDL.Vec(Action)], ['query']),
    'getAllConfigs' : IDL.Func([], [IDL.Vec(StableConfig)], ['query']),
    'getAllUserActionStates' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text })],
        [Result_7],
        [],
      ),
    'getAllUserActionStatesComposite' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text })],
        [Result_7],
        ['composite_query'],
      ),
    'getAllUserEntities' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text, 'page' : IDL.Opt(IDL.Nat) })],
        [Result_5],
        [],
      ),
    'getAllUserEntitiesComposite' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text, 'page' : IDL.Opt(IDL.Nat) })],
        [Result_5],
        ['composite_query'],
      ),
    'getCurrentDauCount' : IDL.Func([], [IDL.Nat], ['query']),
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
    'getTokenIndex' : IDL.Func([IDL.Text], [IDL.Nat32], ['query']),
    'getUserBoomStakeInfo' : IDL.Func([IDL.Text], [Result_6], ['query']),
    'getUserBoomStakeTier' : IDL.Func([IDL.Text], [Result_2], ['query']),
    'getUserEntitiesFromWorldNodeComposite' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text, 'page' : IDL.Opt(IDL.Nat) })],
        [Result_5],
        ['composite_query'],
      ),
    'getUserEntitiesFromWorldNodeFilteredSortingComposite' : IDL.Func(
        [
          IDL.Record({
            'uid' : IDL.Text,
            'order' : IDL.Variant({
              'Descending' : IDL.Null,
              'Ascending' : IDL.Null,
            }),
            'page' : IDL.Opt(IDL.Nat),
            'fieldName' : IDL.Text,
          }),
        ],
        [Result_5],
        ['composite_query'],
      ),
    'getUserExtStakes' : IDL.Func(
        [IDL.Text],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))],
        ['query'],
      ),
    'getUserExtStakesInfo' : IDL.Func(
        [IDL.Text],
        [IDL.Vec(IDL.Tuple(IDL.Text, EXTStake))],
        ['query'],
      ),
    'getUserSpecificExtStakes' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text, 'collectionCanisterId' : IDL.Text })],
        [IDL.Vec(IDL.Text)],
        ['query'],
      ),
    'get_trusted_origins' : IDL.Func([], [IDL.Vec(IDL.Text)], []),
    'grantEntityPermission' : IDL.Func([EntityPermission], [], []),
    'grantGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'importAllActionsOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_2],
        [],
      ),
    'importAllConfigsOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_2],
        [],
      ),
    'importAllPermissionsOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_2],
        [],
      ),
    'importAllUsersDataOfWorld' : IDL.Func(
        [IDL.Record({ 'ofWorldId' : IDL.Text })],
        [Result_2],
        [],
      ),
    'logsClear' : IDL.Func([], [], []),
    'logsGet' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'logsGetCount' : IDL.Func([], [IDL.Nat], ['query']),
    'processAction' : IDL.Func([ActionArg], [Result_4], []),
    'processActionAwait' : IDL.Func([ActionArg], [Result_4], []),
    'processActionForAllUsers' : IDL.Func([ActionArg], [], []),
    'removeAdmin' : IDL.Func([IDL.Record({ 'principal' : IDL.Text })], [], []),
    'removeAllUserNodeRef' : IDL.Func([], [], []),
    'removeEntityPermission' : IDL.Func([EntityPermission], [], []),
    'removeGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'removeTrustedOrigins' : IDL.Func(
        [IDL.Record({ 'originUrl' : IDL.Text })],
        [],
        [],
      ),
    'resetActionsAndConfigsToHardcodedTemplate' : IDL.Func([], [Result_3], []),
    'setDevWorldCanisterId' : IDL.Func([IDL.Text], [], []),
    'stakeBoomTokens' : IDL.Func(
        [IDL.Nat, IDL.Text, IDL.Text, IDL.Nat, ICRCStakeKind],
        [Result_2],
        [],
      ),
    'stakeExtNft' : IDL.Func(
        [IDL.Nat32, IDL.Text, IDL.Text, IDL.Text],
        [Result_2],
        [],
      ),
    'storeDauCount' : IDL.Func([], [IDL.Nat], []),
    'validateConstraints' : IDL.Func(
        [IDL.Text, actionId, IDL.Opt(ActionConstraint)],
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
export const init = ({ IDL }) => { return [IDL.Principal]; };
