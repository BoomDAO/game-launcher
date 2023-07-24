export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const AccountIdentifier = IDL.Text;
  const TokenIndex = IDL.Nat32;
  const TokenIdentifier = IDL.Text;
  const EntityPermission = IDL.Record({});
  return IDL.Service({
    'addAdmin' : IDL.Func([IDL.Text], [], []),
    'admin_create_user' : IDL.Func([IDL.Text], [Result], []),
    'admin_delete_user' : IDL.Func([IDL.Text], [], []),
    'checkUsernameAvailability' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'createNewUser' : IDL.Func([IDL.Principal], [Result], []),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getAccountIdentifier' : IDL.Func(
        [IDL.Text],
        [AccountIdentifier],
        ['query'],
      ),
    'getAllAdmins' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllNodeIds' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getTokenIdentifier' : IDL.Func(
        [IDL.Text, TokenIndex],
        [TokenIdentifier],
        ['query'],
      ),
    'getUserNodeCanisterId' : IDL.Func([IDL.Text], [Result], ['query']),
    'grantEntityPermission' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, EntityPermission],
        [],
        [],
      ),
    'grantGlobalPermission' : IDL.Func([IDL.Text], [], []),
    'importAllPermissionsOfWorld' : IDL.Func(
        [IDL.Text, IDL.Text],
        [Result],
        [],
      ),
    'importAllUsersDataOfWorld' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'removeAdmin' : IDL.Func([IDL.Text], [], []),
    'removeEntityPermission' : IDL.Func([IDL.Text, IDL.Text, IDL.Text], [], []),
    'removeGlobalPermission' : IDL.Func([IDL.Text], [], []),
    'setUsername' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'totalUsers' : IDL.Func([], [IDL.Nat], ['query']),
    'whoami' : IDL.Func([], [IDL.Text], []),
  });
};
export const init = ({ IDL }) => { return []; };
