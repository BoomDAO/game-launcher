export const idlFactory = ({ IDL }) => {
  const Result = IDL.Variant({ 'ok' : IDL.Text, 'err' : IDL.Text });
  const HttpRequestId = IDL.Nat64;
  const HttpFailureReason = IDL.Variant({
    'ProxyError' : IDL.Text,
    'RequestTimeout' : IDL.Null,
  });
  const HttpOverWsError = IDL.Variant({
    'NotHttpOverWsType' : IDL.Text,
    'ProxyNotFound' : IDL.Null,
    'NotYetReceived' : IDL.Null,
    'ConnectionNotAssignedToProxy' : IDL.Null,
    'RequestIdNotFound' : IDL.Null,
    'NoProxiesConnected' : IDL.Null,
    'InvalidHttpMessage' : IDL.Null,
    'RequestFailed' : HttpFailureReason,
  });
  const InvalidRequest = IDL.Variant({
    'TooManyHeaders' : IDL.Null,
    'InvalidTimeout' : IDL.Null,
    'InvalidUrl' : IDL.Text,
  });
  const ProxyCanisterError = IDL.Variant({
    'HttpOverWs' : HttpOverWsError,
    'InvalidRequest' : InvalidRequest,
  });
  const HttpRequestEndpointResult = IDL.Variant({
    'Ok' : HttpRequestId,
    'Err' : ProxyCanisterError,
  });
  return IDL.Service({
    'cleanUp' : IDL.Func([], [], []),
    'generateOTP' : IDL.Func([IDL.Text], [Result], []),
    'generateSmsOTP' : IDL.Func([IDL.Text], [Result], []),
    'getAllEmails' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getTotalEmails' : IDL.Func([], [IDL.Nat], ['query']),
    'ping_server_to_email' : IDL.Func(
        [IDL.Record({ 'otp' : IDL.Text, 'email' : IDL.Text })],
        [HttpRequestEndpointResult],
        [],
      ),
    'ping_server_to_sms' : IDL.Func(
        [IDL.Record({ 'otp' : IDL.Text, 'phone' : IDL.Text })],
        [HttpRequestEndpointResult],
        [],
      ),
    'sendVerificationEmail' : IDL.Func([IDL.Text], [Result], []),
    'sendVerificationSMS' : IDL.Func([IDL.Text], [Result], []),
    'uploadEmails' : IDL.Func([IDL.Text], [], []),
    'verifyOTP' : IDL.Func(
        [IDL.Record({ 'otp' : IDL.Text, 'email' : IDL.Text })],
        [Result],
        [],
      ),
    'verifySmsOTP' : IDL.Func(
        [IDL.Record({ 'otp' : IDL.Text, 'phone' : IDL.Text })],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
