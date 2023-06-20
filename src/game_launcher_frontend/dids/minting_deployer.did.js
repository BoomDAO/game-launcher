export const idlFactory = ({ IDL }) => {
  const TokenIndex = IDL.Nat32;
  const AccountIdentifier = IDL.Text;
  const TokenIdentifier__1 = IDL.Text;
  const CommonError = IDL.Variant({
    InvalidToken: TokenIdentifier__1,
    Other: IDL.Text,
  });
  const Result_1 = IDL.Variant({
    ok: IDL.Opt(IDL.Text),
    err: CommonError,
  });
  const AssetHandle = IDL.Text;
  const Result = IDL.Variant({ ok: IDL.Null, err: CommonError });
  const Info = IDL.Record({
    status: IDL.Text,
    collection: IDL.Text,
    createdAt: IDL.Int,
    lowerBound: IDL.Nat,
    upperBound: IDL.Nat,
    burnAt: IDL.Int,
  });
  const Collection = IDL.Record({
    name: IDL.Text,
    canister_id: IDL.Text,
  });
  const TokenIdentifier = IDL.Text;
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    url: IDL.Text,
    method: IDL.Text,
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(HeaderField),
  });
  const Token = IDL.Record({ arbitrary_data: IDL.Text });
  const StreamingCallbackHttpResponse = IDL.Record({
    token: IDL.Opt(Token),
    body: IDL.Vec(IDL.Nat8),
  });
  const CallbackStrategy = IDL.Record({
    token: Token,
    callback: IDL.Func([Token], [StreamingCallbackHttpResponse], ["query"]),
  });
  const StreamingStrategy = IDL.Variant({ Callback: CallbackStrategy });
  const HttpResponse = IDL.Record({
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(HeaderField),
    upgrade: IDL.Opt(IDL.Bool),
    streaming_strategy: IDL.Opt(StreamingStrategy),
    status_code: IDL.Nat16,
  });
  const ICHttpHeader = IDL.Record({ value: IDL.Text, name: IDL.Text });
  const ICCanisterHttpResponsePayload = IDL.Record({
    status: IDL.Nat,
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(ICHttpHeader),
  });
  const ICTransformArgs = IDL.Record({
    context: IDL.Vec(IDL.Nat8),
    response: ICCanisterHttpResponsePayload,
  });
  return IDL.Service({
    add_controller: IDL.Func([IDL.Text, IDL.Text], [], []),
    airdrop_to_addresses: IDL.Func(
      [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Bool, IDL.Int],
      [IDL.Vec(TokenIndex)],
      [],
    ),
    batch_mint_to_addresses: IDL.Func(
      [
        IDL.Text,
        IDL.Vec(IDL.Text),
        IDL.Text,
        IDL.Text,
        IDL.Text,
        IDL.Nat32,
        IDL.Int,
        IDL.Bool,
      ],
      [IDL.Vec(TokenIndex)],
      [],
    ),
    bulk_burn_nfts: IDL.Func([IDL.Text], [], []),
    burnNft: IDL.Func(
      [IDL.Text, TokenIndex, AccountIdentifier],
      [Result_1],
      [],
    ),
    burnNfts: IDL.Func([IDL.Text, TokenIndex, TokenIndex, AssetHandle], [], []),
    clear_collection_registry: IDL.Func([], [], []),
    create_collection: IDL.Func(
      [IDL.Text, IDL.Text, IDL.Text, IDL.Nat64],
      [IDL.Text],
      [],
    ),
    cycleBalance: IDL.Func([], [IDL.Nat], ["query"]),
    external_burn: IDL.Func([IDL.Text, TokenIndex], [Result], []),
    getAID: IDL.Func([], [AccountIdentifier], []),
    getBurnInfo: IDL.Func([IDL.Text], [IDL.Vec(Info)], ["query"]),
    getCollectionMetadata: IDL.Func([IDL.Text], [IDL.Text, IDL.Text], []),
    getCollections: IDL.Func([], [IDL.Vec(Collection)], ["query"]),
    getController: IDL.Func([IDL.Text], [IDL.Vec(IDL.Principal)], []),
    getNow: IDL.Func([], [IDL.Int], []),
    getOwner: IDL.Func([IDL.Text], [IDL.Text], ["query"]),
    getRegistry: IDL.Func([IDL.Text, IDL.Nat32], [IDL.Vec(IDL.Text)], []),
    getSize: IDL.Func([IDL.Text], [IDL.Nat], []),
    getTokenIdentifier: IDL.Func([IDL.Text, TokenIndex], [TokenIdentifier], []),
    getTokenMetadata: IDL.Func([IDL.Text, TokenIndex], [IDL.Text], []),
    getTokenUrl: IDL.Func([IDL.Text, TokenIndex], [IDL.Text], []),
    getUserCollections: IDL.Func([IDL.Text], [IDL.Vec(Collection)], ["query"]),
    getUserNfts: IDL.Func(
      [IDL.Text, IDL.Text],
      [IDL.Vec(IDL.Tuple(TokenIndex, IDL.Text))],
      [],
    ),
    http_request: IDL.Func([HttpRequest], [HttpResponse], ["query"]),
    http_request_update: IDL.Func([HttpRequest], [HttpResponse], []),
    isController: IDL.Func([IDL.Text, IDL.Principal], [IDL.Bool], []),
    isMinter: IDL.Func([IDL.Text, IDL.Principal], [IDL.Bool], []),
    remove_controller: IDL.Func([IDL.Text, IDL.Text], [], []),
    transform: IDL.Func(
      [ICTransformArgs],
      [ICCanisterHttpResponsePayload],
      ["query"],
    ),
    uploadAsset: IDL.Func([IDL.Text, AssetHandle, IDL.Text, IDL.Text], [], []),
    wallet_receive: IDL.Func([], [IDL.Nat], []),
  });
};
export const init = ({ IDL }) => {
  return [];
};
