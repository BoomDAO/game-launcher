export const idlFactory = ({ IDL }) => {
  const Game = IDL.Record({
    url: IDL.Text,
    name: IDL.Text,
    cover: IDL.Text,
    canister_id: IDL.Text,
    description: IDL.Text,
    platform: IDL.Text,
  });
  const headerField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    url: IDL.Text,
    method: IDL.Text,
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(headerField),
  });
  const HttpResponse = IDL.Record({
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(headerField),
    status_code: IDL.Nat16,
  });
  const Result = IDL.Variant({ ok: IDL.Null, err: IDL.Text });
  return IDL.Service({
    create_game_canister: IDL.Func(
      [IDL.Text, IDL.Text, IDL.Text, IDL.Text],
      [IDL.Text],
      [],
    ),
    cycleBalance: IDL.Func([], [IDL.Nat], ["query"]),
    get_all_asset_canisters: IDL.Func([IDL.Nat], [IDL.Vec(Game)], ["query"]),
    get_epoch_in_nano: IDL.Func([], [IDL.Int], []),
    get_game_cover: IDL.Func([IDL.Text], [IDL.Text], ["query"]),
    get_owner: IDL.Func([IDL.Text], [IDL.Opt(IDL.Text)], ["query"]),
    get_total_games: IDL.Func([], [IDL.Nat], ["query"]),
    get_user_games: IDL.Func([IDL.Text, IDL.Nat], [IDL.Vec(Game)], ["query"]),
    http_request: IDL.Func([HttpRequest], [HttpResponse], ["query"]),
    remove_canister: IDL.Func([IDL.Text], [], []),
    update_game_cover: IDL.Func([IDL.Text, IDL.Text], [Result], []),
    update_game_data: IDL.Func([IDL.Text, IDL.Text, IDL.Text], [Result], []),
    wallet_receive: IDL.Func([], [IDL.Nat], []),
  });
};
export const init = ({ IDL }) => {
  return [];
};
