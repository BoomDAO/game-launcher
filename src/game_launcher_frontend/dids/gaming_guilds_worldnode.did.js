export const idlFactory = ({ IDL }) => {
  const List = IDL.Rec();
  const List_1 = IDL.Rec();
  const Trie = IDL.Rec();
  const Trie_1 = IDL.Rec();
  const userId = IDL.Text;
  const ActionState = IDL.Record({
    'actionCount' : IDL.Nat,
    'intervalStartTs' : IDL.Nat,
    'actionId' : IDL.Text,
  });
  const entityId = IDL.Text;
  const worldId = IDL.Text;
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
  const ActionOutcomeOption = IDL.Record({
    'weight' : IDL.Float64,
    'option' : IDL.Variant({
      'updateEntity' : UpdateEntity,
      'updateAction' : UpdateAction,
      'transferIcrc' : TransferIcrc,
      'mintNft' : MintNft,
    }),
  });
  const Result_3 = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Field = IDL.Record({ 'fieldName' : IDL.Text, 'fieldValue' : IDL.Text });
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
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
  const Result_2 = IDL.Variant({
    'ok' : IDL.Vec(ActionState),
    'err' : IDL.Text,
  });
  const StableEntity = IDL.Record({
    'eid' : entityId,
    'wid' : worldId,
    'fields' : IDL.Vec(Field),
  });
  const Result_1 = IDL.Variant({
    'ok' : IDL.Vec(StableEntity),
    'err' : IDL.Text,
  });
  const EntityPermission = IDL.Record({ 'eid' : entityId, 'wid' : worldId });
  const GlobalPermission = IDL.Record({ 'wid' : worldId });
  const Branch_1 = IDL.Record({
    'left' : Trie_1,
    'size' : IDL.Nat,
    'right' : Trie_1,
  });
  const Hash = IDL.Nat32;
  const Key_1 = IDL.Record({ 'key' : IDL.Text, 'hash' : Hash });
  List_1.fill(IDL.Opt(IDL.Tuple(IDL.Tuple(Key_1, EntityPermission), List_1)));
  const AssocList_1 = IDL.Opt(
    IDL.Tuple(IDL.Tuple(Key_1, EntityPermission), List_1)
  );
  const Leaf_1 = IDL.Record({ 'size' : IDL.Nat, 'keyvals' : AssocList_1 });
  Trie_1.fill(
    IDL.Variant({ 'branch' : Branch_1, 'leaf' : Leaf_1, 'empty' : IDL.Null })
  );
  const Branch = IDL.Record({
    'left' : Trie,
    'size' : IDL.Nat,
    'right' : Trie,
  });
  const Key = IDL.Record({ 'key' : worldId, 'hash' : Hash });
  List.fill(IDL.Opt(IDL.Tuple(IDL.Tuple(Key, IDL.Vec(worldId)), List)));
  const AssocList = IDL.Opt(IDL.Tuple(IDL.Tuple(Key, IDL.Vec(worldId)), List));
  const Leaf = IDL.Record({ 'size' : IDL.Nat, 'keyvals' : AssocList });
  Trie.fill(
    IDL.Variant({ 'branch' : Branch, 'leaf' : Leaf, 'empty' : IDL.Null })
  );
  const UserNode = IDL.Service({
    'adminCreateUser' : IDL.Func([IDL.Text], [], []),
    'applyOutcomes' : IDL.Func(
        [userId, ActionState, IDL.Vec(ActionOutcomeOption)],
        [Result_3],
        [],
      ),
    'containsUserId' : IDL.Func([userId], [IDL.Bool], ['query']),
    'createEntity' : IDL.Func(
        [userId, worldId, entityId, IDL.Vec(Field)],
        [Result],
        [],
      ),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'deleteActionHistoryForUser' : IDL.Func(
        [IDL.Record({ 'uid' : userId })],
        [],
        [],
      ),
    'deleteActionState' : IDL.Func([userId, worldId, actionId], [Result], []),
    'deleteEntity' : IDL.Func([userId, worldId, entityId], [Result], []),
    'deleteUser' : IDL.Func([IDL.Record({ 'uid' : userId })], [], []),
    'deleteUserEntityFromWorldNode' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text })],
        [],
        [],
      ),
    'editEntity' : IDL.Func(
        [userId, worldId, entityId, IDL.Vec(Field)],
        [Result],
        [],
      ),
    'getActionState' : IDL.Func(
        [userId, worldId, actionId],
        [IDL.Opt(ActionState)],
        ['query'],
      ),
    'getAllUserActionHistoryOfSpecificWorlds' : IDL.Func(
        [userId, IDL.Vec(worldId), IDL.Opt(IDL.Nat)],
        [IDL.Vec(ActionOutcomeHistory)],
        ['query'],
      ),
    'getAllUserActionHistoryOfSpecificWorldsComposite' : IDL.Func(
        [userId, IDL.Vec(worldId), IDL.Opt(IDL.Nat)],
        [IDL.Vec(ActionOutcomeHistory)],
        ['composite_query'],
      ),
    'getAllUserActionStates' : IDL.Func(
        [userId, worldId],
        [Result_2],
        ['query'],
      ),
    'getAllUserActionStatesComposite' : IDL.Func(
        [userId, worldId],
        [Result_2],
        ['composite_query'],
      ),
    'getAllUserEntities' : IDL.Func(
        [userId, worldId, IDL.Opt(IDL.Nat)],
        [Result_1],
        ['query'],
      ),
    'getAllUserEntitiesComposite' : IDL.Func(
        [userId, worldId, IDL.Opt(IDL.Nat)],
        [Result_1],
        ['composite_query'],
      ),
    'getAllUserEntitiesOfAllWorlds' : IDL.Func(
        [userId, IDL.Opt(IDL.Nat)],
        [Result_1],
        ['query'],
      ),
    'getAllUserEntitiesOfSpecificWorlds' : IDL.Func(
        [userId, IDL.Vec(worldId), IDL.Opt(IDL.Nat)],
        [Result_1],
        ['query'],
      ),
    'getAllUserEntitiesOfSpecificWorldsComposite' : IDL.Func(
        [userId, IDL.Vec(worldId), IDL.Opt(IDL.Nat)],
        [Result_1],
        ['composite_query'],
      ),
    'getAllUserIds' : IDL.Func([], [IDL.Vec(userId)], ['query']),
    'getAllWorldUserIds' : IDL.Func([worldId], [IDL.Vec(userId)], ['query']),
    'getEntity' : IDL.Func([userId, worldId, entityId], [StableEntity], []),
    'getSpecificUserEntities' : IDL.Func(
        [userId, worldId, IDL.Vec(entityId)],
        [Result_1],
        ['query'],
      ),
    'getUserActionHistory' : IDL.Func(
        [userId, worldId],
        [IDL.Vec(ActionOutcomeHistory)],
        ['query'],
      ),
    'getUserActionHistoryComposite' : IDL.Func(
        [userId, worldId],
        [IDL.Vec(ActionOutcomeHistory)],
        ['composite_query'],
      ),
    'getUserEntitiesFromWorldNode' : IDL.Func(
        [userId, worldId, IDL.Opt(IDL.Nat)],
        [Result_1],
        ['query'],
      ),
    'getUserEntitiesFromWorldNodeComposite' : IDL.Func(
        [userId, worldId, IDL.Opt(IDL.Nat)],
        [Result_1],
        ['composite_query'],
      ),
    'grantEntityPermission' : IDL.Func([IDL.Text, EntityPermission], [], []),
    'grantGlobalPermission' : IDL.Func([IDL.Text, GlobalPermission], [], []),
    'importAllPermissionsOfWorld' : IDL.Func(
        [IDL.Text, IDL.Text],
        [Result],
        [],
      ),
    'importAllUsersDataOfWorld' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'manuallyOverwriteEntities' : IDL.Func(
        [userId, IDL.Vec(StableEntity)],
        [Result_1],
        [],
      ),
    'removeEntityPermission' : IDL.Func([IDL.Text, EntityPermission], [], []),
    'removeGlobalPermission' : IDL.Func([IDL.Text, GlobalPermission], [], []),
    'synchronizeEntityPermissions' : IDL.Func([IDL.Text, Trie_1], [], []),
    'synchronizeGlobalPermissions' : IDL.Func([Trie], [], []),
    'updateEntity' : IDL.Func(
        [IDL.Record({ 'uid' : userId, 'entity' : StableEntity })],
        [Result],
        [],
      ),
  });
  return UserNode;
};
export const init = ({ IDL }) => { return []; };
