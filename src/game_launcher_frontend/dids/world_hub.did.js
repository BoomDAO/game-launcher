export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const AccountIdentifier = IDL.Text;
  const userId = IDL.Text;
  const nodeId = IDL.Text;
  const entityId = IDL.Text;
  const worldId = IDL.Text;
  const Field = IDL.Record({ 'fieldName' : IDL.Text, 'fieldValue' : IDL.Text });
  const StableEntity = IDL.Record({
    'eid' : entityId,
    'wid' : worldId,
    'fields' : IDL.Vec(Field),
  });
  const EntityPermission = IDL.Record({ 'eid' : entityId, 'wid' : worldId });
  const TokenIndex = IDL.Nat32;
  const TokenIdentifier = IDL.Text;
  const GlobalPermission = IDL.Record({ 'wid' : worldId });
  return IDL.Service({
    'addAdmin' : IDL.Func([IDL.Text], [], []),
    'admin_create_user' : IDL.Func([IDL.Text], [Result], []),
    'admin_delete_user' : IDL.Func([IDL.Text], [], []),
    'checkUsernameAvailability' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'createNewUser' : IDL.Func([IDL.Principal], [Result], []),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'delete_cache' : IDL.Func([], [], []),
    'getAccountIdentifier' : IDL.Func(
        [IDL.Text],
        [AccountIdentifier],
        ['query'],
      ),
    'getAllAdmins' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllAssetNodeIds' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllNodeIds' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllUserIds' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getDeleteCacheResponse' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(userId, nodeId))],
        ['query'],
      ),
    'getEntity' : IDL.Func([userId, entityId], [StableEntity], []),
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
    'getTokenIdentifier' : IDL.Func(
        [IDL.Text, TokenIndex],
        [TokenIdentifier],
        ['query'],
      ),
    'getUserNodeCanisterId' : IDL.Func([IDL.Text], [Result], ['query']),
    'getUserNodeWasmVersion' : IDL.Func([], [IDL.Text], ['query']),
    'getUserProfile' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text })],
        [
          IDL.Record({
            'uid' : IDL.Text,
            'username' : IDL.Text,
            'image' : IDL.Text,
          }),
        ],
        ['query'],
      ),
    'grantEntityPermission' : IDL.Func([EntityPermission], [], []),
    'grantGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'importAllPermissionsOfWorld' : IDL.Func([IDL.Text], [Result], []),
    'importAllUsersDataOfWorld' : IDL.Func([IDL.Text], [Result], []),
    'removeAdmin' : IDL.Func([IDL.Text], [], []),
    'removeEntityPermission' : IDL.Func([EntityPermission], [], []),
    'removeGlobalPermission' : IDL.Func([GlobalPermission], [], []),
    'setUsername' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'totalUsers' : IDL.Func([], [IDL.Nat], ['query']),
    'updateEntity' : IDL.Func(
        [IDL.Record({ 'uid' : userId, 'entity' : StableEntity })],
        [Result],
        [],
      ),
    'updateUserNodeWasmModule' : IDL.Func(
        [IDL.Record({ 'wasm' : IDL.Vec(IDL.Nat8), 'version' : IDL.Text })],
        [IDL.Int],
        [],
      ),
    'upgrade_usernodes' : IDL.Func([IDL.Int], [], []),
    'uploadProfilePicture' : IDL.Func(
        [IDL.Record({ 'uid' : IDL.Text, 'image' : IDL.Text })],
        [],
        [],
      ),
    'validate_delete_cache' : IDL.Func(
        [],
        [IDL.Variant({ 'Ok' : IDL.Text, 'Err' : IDL.Text })],
        [],
      ),
    'validate_upgrade_usernodes' : IDL.Func(
        [IDL.Int],
        [IDL.Variant({ 'Ok' : IDL.Text, 'Err' : IDL.Text })],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
