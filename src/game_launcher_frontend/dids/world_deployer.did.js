export const idlFactory = ({ IDL }) => {
  const World = IDL.Record({
    'name' : IDL.Text,
    'cover' : IDL.Text,
    'canister' : IDL.Text,
  });
  const headerField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(headerField),
  });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(headerField),
    'status_code' : IDL.Nat16,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  return IDL.Service({
    'addAdmin' : IDL.Func([IDL.Text], [], []),
    'addController' : IDL.Func([IDL.Text, IDL.Text], [], []),
    'createWorldCanister' : IDL.Func([IDL.Text, IDL.Text], [IDL.Text], []),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getAllAdmins' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllWorlds' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))],
        ['query'],
      ),
    'getOwner' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Text)], ['query']),
    'getTotalWorlds' : IDL.Func([], [IDL.Nat], ['query']),
    'getUserTotalWorlds' : IDL.Func([IDL.Text], [IDL.Nat], ['query']),
    'getUserWorlds' : IDL.Func(
        [IDL.Text, IDL.Nat],
        [IDL.Vec(World)],
        ['query'],
      ),
    'getWorldCover' : IDL.Func([IDL.Text], [IDL.Text], ['query']),
    'getWorldDetails' : IDL.Func([IDL.Text], [IDL.Opt(World)], ['query']),
    'getWorldWasmVersion' : IDL.Func([], [IDL.Text], ['query']),
    'getWorlds' : IDL.Func([IDL.Nat], [IDL.Vec(World)], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'removeAdmin' : IDL.Func([IDL.Text], [], []),
    'removeController' : IDL.Func([IDL.Text, IDL.Text], [], []),
    'updateWorldCover' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'updateWorldName' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'updateWorldWasmModule' : IDL.Func(
        [IDL.Record({ 'wasm' : IDL.Vec(IDL.Nat8), 'version' : IDL.Text })],
        [IDL.Int],
        [],
      ),
    'upgrade_worlds' : IDL.Func([IDL.Int], [], []),
    'validate_upgrade_worlds' : IDL.Func(
        [IDL.Int],
        [IDL.Variant({ 'Ok' : IDL.Text, 'Err' : IDL.Text })],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
