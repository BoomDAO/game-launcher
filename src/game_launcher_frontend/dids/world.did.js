export const idlFactory = ({ IDL }) => {
<<<<<<< HEAD
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
=======
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
  const IcpTx = IDL.Record({
    'toPrincipal' : IDL.Text,
    'amount' : IDL.Float64,
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
    'icpConstraint' : IDL.Opt(IcpTx),
    'nftConstraint' : IDL.Vec(NftTx),
    'timeConstraint' : IDL.Opt(
      IDL.Record({
        'actionExpirationTimestamp' : IDL.Opt(IDL.Nat),
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
        'intervalDuration' : IDL.Nat,
        'actionsPerInterval' : IDL.Nat,
      })
    ),
  });
  const SetNumber = IDL.Record({
<<<<<<< HEAD
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
=======
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
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
  });
  const MintNft = IDL.Record({
    'assetId' : IDL.Text,
    'metadata' : IDL.Text,
    'canister' : IDL.Text,
<<<<<<< HEAD
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
=======
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
  });
  const ActionOutcomeOption = IDL.Record({
    'weight' : IDL.Float64,
    'option' : IDL.Variant({
<<<<<<< HEAD
      'setNumber' : SetNumber,
      'mintToken' : MintToken,
      'incrementNumber' : IncrementNumber,
      'mintNft' : MintNft,
      'deleteEntity' : DeleteEntity,
      'setString' : SetString,
      'decrementNumber' : DecrementNumber,
      'renewTimestamp' : RenewTimestamp,
=======
      'updateEntity' : UpdateEntity,
      'transferIcrc' : TransferIcrc,
      'mintNft' : MintNft,
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
    }),
  });
  const ActionOutcome = IDL.Record({
    'possibleOutcomes' : IDL.Vec(ActionOutcomeOption),
  });
  const ActionResult = IDL.Record({ 'outcomes' : IDL.Vec(ActionOutcome) });
<<<<<<< HEAD
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
=======
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
  const userId = IDL.Text;
  const StableEntity = IDL.Record({
    'eid' : entityId,
    'wid' : worldId,
    'fields' : IDL.Vec(Field),
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
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
<<<<<<< HEAD
  const StableEntity = IDL.Record({
    'eid' : entityId,
    'gid' : groupId,
    'wid' : worldId,
    'fields' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
  });
=======
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
  const Result_5 = IDL.Variant({
    'ok' : IDL.Vec(StableEntity),
    'err' : IDL.Text,
  });
<<<<<<< HEAD
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
=======
  const EntityPermission = IDL.Record({ 'eid' : entityId, 'wid' : worldId });
  const GlobalPermission = IDL.Record({ 'wid' : worldId });
  const ActionArg = IDL.Record({
    'fields' : IDL.Vec(Field),
    'actionId' : IDL.Text,
  });
  const ActionReturn = IDL.Record({
    'worldOutcomes' : IDL.Opt(IDL.Vec(ActionOutcomeOption)),
    'targetOutcomes' : IDL.Opt(IDL.Vec(ActionOutcomeOption)),
    'targetPrincipalId' : IDL.Opt(IDL.Text),
    'callerPrincipalId' : IDL.Text,
    'worldPrincipalId' : IDL.Text,
    'callerOutcomes' : IDL.Opt(IDL.Vec(ActionOutcomeOption)),
  });
  const Result_3 = IDL.Variant({ 'ok' : ActionReturn, 'err' : IDL.Text });
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
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
  const ClientPrincipal = IDL.Principal;
  const ClientKey = IDL.Record({
    'client_principal' : ClientPrincipal,
    'client_nonce' : IDL.Nat64,
  });
  const CanisterWsCloseArguments = IDL.Record({ 'client_key' : ClientKey });
  const CanisterWsCloseResult = IDL.Variant({
    'Ok' : IDL.Null,
    'Err' : IDL.Text,
  });
  const CanisterWsGetMessagesArguments = IDL.Record({ 'nonce' : IDL.Nat64 });
  const CanisterOutputMessage = IDL.Record({
    'key' : IDL.Text,
    'content' : IDL.Vec(IDL.Nat8),
    'client_key' : ClientKey,
  });
  const CanisterOutputCertifiedMessages = IDL.Record({
    'messages' : IDL.Vec(CanisterOutputMessage),
    'cert' : IDL.Vec(IDL.Nat8),
    'tree' : IDL.Vec(IDL.Nat8),
  });
  const CanisterWsGetMessagesResult = IDL.Variant({
    'Ok' : CanisterOutputCertifiedMessages,
    'Err' : IDL.Text,
  });
  const WebsocketMessage = IDL.Record({
    'sequence_num' : IDL.Nat64,
    'content' : IDL.Vec(IDL.Nat8),
    'client_key' : ClientKey,
    'timestamp' : IDL.Nat64,
    'is_service_message' : IDL.Bool,
  });
  const CanisterWsMessageArguments = IDL.Record({ 'msg' : WebsocketMessage });
  const WSSentArg = IDL.Variant({
    'userIdsToFetchDataFrom' : IDL.Vec(IDL.Text),
    'actionOutcomes' : ActionReturn,
  });
  const CanisterWsMessageResult = IDL.Variant({
    'Ok' : IDL.Null,
    'Err' : IDL.Text,
  });
  const GatewayPrincipal = IDL.Principal;
  const CanisterWsOpenArguments = IDL.Record({
    'gateway_principal' : GatewayPrincipal,
    'client_nonce' : IDL.Nat64,
  });
  const CanisterWsOpenResult = IDL.Variant({
    'Ok' : IDL.Null,
    'Err' : IDL.Text,
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
        [IDL.Record({ 'uid' : userId, 'entity' : StableEntity })],
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
<<<<<<< HEAD
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
  
=======
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
    'updateOwnership' : IDL.Func([IDL.Principal], [], []),
    'validateEntityConstraints' : IDL.Func(
        [IDL.Vec(StableEntity), IDL.Vec(EntityConstraint)],
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
    'ws_close' : IDL.Func(
        [CanisterWsCloseArguments],
        [CanisterWsCloseResult],
        [],
      ),
    'ws_get_messages' : IDL.Func(
        [CanisterWsGetMessagesArguments],
        [CanisterWsGetMessagesResult],
        ['query'],
      ),
    'ws_message' : IDL.Func(
        [CanisterWsMessageArguments, IDL.Opt(WSSentArg)],
        [CanisterWsMessageResult],
        [],
      ),
    'ws_open' : IDL.Func([CanisterWsOpenArguments], [CanisterWsOpenResult], []),
  });
  return WorldTemplate;
};
export const init = ({ IDL }) => { return []; };
>>>>>>> 8a40884 (adding gaming guilds feat-under testing)
