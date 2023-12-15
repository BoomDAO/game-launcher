export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const HttpHeader = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
  const CanisterHttpResponsePayload = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HttpHeader),
  });
  const TransformArgs = IDL.Record({
    'context' : IDL.Vec(IDL.Nat8),
    'response' : CanisterHttpResponsePayload,
  });
  return IDL.Service({
    'addEmail' : IDL.Func([IDL.Text], [], []),
    'cleanUp' : IDL.Func([], [], []),
    'generateOTP' : IDL.Func([IDL.Text], [Result], []),
    'getAllEmails' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getTotalEmails' : IDL.Func([], [IDL.Nat], ['query']),
    'isAccountVerified' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'sendVerificationEmail' : IDL.Func([IDL.Text], [Result], []),
    'transform' : IDL.Func(
        [TransformArgs],
        [CanisterHttpResponsePayload],
        ['query'],
      ),
    'verifyOTP' : IDL.Func(
        [IDL.Record({ 'otp' : IDL.Text, 'email' : IDL.Text })],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
