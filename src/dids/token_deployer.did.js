export const idlFactory = ({ IDL }) => {
  const Token = IDL.Record({
    'name' : IDL.Text,
    'cover' : IDL.Text,
    'description' : IDL.Text,
    'canister' : IDL.Text,
    'symbol' : IDL.Text,
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
    'createTokenCanister' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text],
        [IDL.Text],
        [],
      ),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getAllAdmins' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllTokens' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))],
        ['query'],
      ),
    'getOwner' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Text)], ['query']),
    'getTokenDetails' : IDL.Func([IDL.Text], [IDL.Opt(Token)], ['query']),
    'getTotalTokens' : IDL.Func([], [IDL.Nat], ['query']),
    'getUserTokens' : IDL.Func(
        [IDL.Text, IDL.Nat],
        [IDL.Vec(Token)],
        ['query'],
      ),
    'getUserTotalTokens' : IDL.Func([IDL.Text], [IDL.Nat], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'removeAdmin' : IDL.Func([IDL.Text], [], []),
    'update' : IDL.Func([IDL.Text], [], []),
    'updateTokenCover' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
