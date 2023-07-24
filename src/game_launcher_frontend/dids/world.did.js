export const idlFactory = ({ IDL }) => {
    const TokenIndex = IDL.Nat32;
    const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
    const ActionConstraint = IDL.Record({
      'entityConstraint' : IDL.Opt(
        IDL.Vec(
          IDL.Record({
            'groupId' : IDL.Text,
            'lessThanQuantity' : IDL.Opt(IDL.Float64),
            'entityId' : IDL.Text,
            'worldId' : IDL.Text,
            'equalToAttribute' : IDL.Opt(IDL.Text),
            'greaterThanOrEqualQuantity' : IDL.Opt(IDL.Float64),
            'notExpired' : IDL.Opt(IDL.Bool),
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
    const MintToken = IDL.Record({
      'canister' : IDL.Text,
      'quantity' : IDL.Float64,
    });
    const worldId = IDL.Text;
    const groupId = IDL.Text;
    const entityId = IDL.Text;
    const quantity = IDL.Float64;
    const MintNft = IDL.Record({
      'assetId' : IDL.Text,
      'metadata' : IDL.Text,
      'canister' : IDL.Text,
      'index' : IDL.Opt(IDL.Nat32),
    });
    const attribute = IDL.Text;
    const duration = IDL.Nat;
    const ActionOutcomeOption = IDL.Record({
      'weight' : IDL.Float64,
      'option' : IDL.Variant({
        'mintToken' : MintToken,
        'spendEntityQuantity' : IDL.Tuple(
          IDL.Opt(worldId),
          groupId,
          entityId,
          quantity,
        ),
        'mintNft' : MintNft,
        'deleteEntity' : IDL.Tuple(IDL.Opt(worldId), groupId, entityId),
        'setEntityAttribute' : IDL.Tuple(
          IDL.Opt(worldId),
          groupId,
          entityId,
          attribute,
        ),
        'receiveEntityQuantity' : IDL.Tuple(
          IDL.Opt(worldId),
          groupId,
          entityId,
          quantity,
        ),
        'renewEntityExpiration' : IDL.Tuple(
          IDL.Opt(worldId),
          groupId,
          entityId,
          duration,
        ),
        'reduceEntityExpiration' : IDL.Tuple(
          IDL.Opt(worldId),
          groupId,
          entityId,
          duration,
        ),
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
      'burnNft' : IDL.Record({ 'canister' : IDL.Text }),
      'claimStakingRewardIcrc' : IDL.Record({
        'canister' : IDL.Text,
        'requiredAmount' : IDL.Float64,
      }),
    });
    const ActionConfig = IDL.Record({
      'aid' : IDL.Text,
      'tag' : IDL.Opt(IDL.Text),
      'actionConstraint' : IDL.Opt(ActionConstraint),
      'name' : IDL.Opt(IDL.Text),
      'actionResult' : ActionResult,
      'description' : IDL.Opt(IDL.Text),
      'imageUrl' : IDL.Opt(IDL.Text),
      'actionPlugin' : IDL.Opt(ActionPlugin),
    });
    const Result_1 = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
    const EntityConfig = IDL.Record({
      'eid' : IDL.Text,
      'gid' : IDL.Text,
      'tag' : IDL.Text,
      'duration' : IDL.Opt(IDL.Nat),
      'metadata' : IDL.Text,
      'objectUrl' : IDL.Opt(IDL.Text),
      'name' : IDL.Opt(IDL.Text),
      'description' : IDL.Opt(IDL.Text),
      'imageUrl' : IDL.Opt(IDL.Text),
      'rarity' : IDL.Opt(IDL.Text),
    });
    const Action = IDL.Record({
      'actionCount' : IDL.Nat,
      'intervalStartTs' : IDL.Nat,
      'actionId' : IDL.Text,
    });
    const Result_5 = IDL.Variant({ 'ok' : IDL.Vec(Action), 'err' : IDL.Text });
    const Entity = IDL.Record({
      'eid' : IDL.Text,
      'gid' : IDL.Text,
      'wid' : IDL.Text,
      'expiration' : IDL.Opt(IDL.Nat),
      'quantity' : IDL.Opt(IDL.Float64),
      'attribute' : IDL.Opt(IDL.Text),
    });
    const Result_4 = IDL.Variant({ 'ok' : IDL.Vec(Entity), 'err' : IDL.Text });
    const EntityPermission = IDL.Record({});
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
      'default' : IDL.Record({ 'actionId' : IDL.Text }),
      'burnNft' : IDL.Record({ 'index' : IDL.Nat32, 'actionId' : IDL.Text }),
      'claimStakingRewardIcrc' : IDL.Record({ 'actionId' : IDL.Text }),
    });
    const ActionResponse = IDL.Tuple(
      Action,
      IDL.Vec(Entity),
      IDL.Vec(MintNft),
      IDL.Vec(MintToken),
    );
    const Result_3 = IDL.Variant({ 'ok' : ActionResponse, 'err' : IDL.Text });
    const Result_2 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Null });
    const WorldTemplate = IDL.Service({
      'addAdmin' : IDL.Func([IDL.Text], [], []),
      'burnNft' : IDL.Func([IDL.Text, TokenIndex, IDL.Principal], [Result], []),
      'createActionConfig' : IDL.Func([ActionConfig], [Result_1], []),
      'createEntityConfig' : IDL.Func([EntityConfig], [Result_1], []),
      'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
      'deleteActionConfig' : IDL.Func([IDL.Text], [Result_1], []),
      'deleteEntityConfig' : IDL.Func([IDL.Text, IDL.Text], [Result_1], []),
      'getActionConfigs' : IDL.Func([], [IDL.Vec(ActionConfig)], ['query']),
      'getAllUserWorldActions' : IDL.Func([], [Result_5], []),
      'getAllUserWorldEntities' : IDL.Func([], [Result_4], []),
      'getEntityConfigs' : IDL.Func([], [IDL.Vec(EntityConfig)], ['query']),
      'getOwner' : IDL.Func([], [IDL.Text], ['query']),
      'grantEntityPermission' : IDL.Func(
          [IDL.Text, IDL.Text, IDL.Text, EntityPermission],
          [],
          [],
        ),
      'grantGlobalPermission' : IDL.Func([IDL.Text], [], []),
      'importActionConfigs' : IDL.Func([], [IDL.Vec(ActionConfig)], []),
      'importAllConfigsOfWorld' : IDL.Func([IDL.Text], [Result_1], []),
      'importEntityConfigs' : IDL.Func([], [IDL.Vec(EntityConfig)], []),
      'processAction' : IDL.Func([ActionArg], [Result_3], []),
      'removeAdmin' : IDL.Func([IDL.Text], [], []),
      'removeEntityPermission' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [], []),
      'removeGlobalPermission' : IDL.Func([IDL.Text], [], []),
      'resetConfig' : IDL.Func([], [Result_2], []),
      'updateActionConfig' : IDL.Func([ActionConfig], [Result_1], []),
      'updateEntityConfig' : IDL.Func([EntityConfig], [Result_1], []),
      'verifyTxIcp' : IDL.Func(
          [IDL.Nat64, IDL.Text, IDL.Text, IDL.Nat64],
          [Result],
          [],
        ),
      'verifyTxIcrc' : IDL.Func(
          [IDL.Nat, IDL.Text, IDL.Text, IDL.Nat, IDL.Text],
          [Result],
          [],
        ),
      'whoAmI' : IDL.Func([], [IDL.Principal], ['query']),
    });
    return WorldTemplate;
  };
  export const init = ({ IDL }) => { return []; };
  