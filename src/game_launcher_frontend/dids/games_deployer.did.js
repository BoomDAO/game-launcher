export const idlFactory = ({ IDL }) => {
  const Game = IDL.Record({
    'url' : IDL.Text,
    'verified' : IDL.Bool,
    'name' : IDL.Text,
    'cover' : IDL.Text,
    'canister_id' : IDL.Text,
    'lastUpdated' : IDL.Int,
    'description' : IDL.Text,
    'platform' : IDL.Text,
    'visibility' : IDL.Text,
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
    'add_admin' : IDL.Func([IDL.Text], [], []),
    'add_controller' : IDL.Func([IDL.Text, IDL.Text], [], []),
    'adminUpdateFeaturedGames' : IDL.Func([IDL.Text], [], []),
    'admin_create_game' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text],
        [IDL.Text],
        [],
      ),
    'admin_remove_game' : IDL.Func([IDL.Text], [], []),
    'create_game_canister' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text],
        [IDL.Text],
        [],
      ),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'getFeaturedGames' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'get_all_admins' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'get_all_asset_canisters' : IDL.Func(
        [IDL.Nat, IDL.Text],
        [IDL.Vec(Game)],
        ['query'],
      ),
    'get_all_games' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, Game))],
        ['query'],
      ),
    'get_game' : IDL.Func([IDL.Text], [IDL.Opt(Game)], ['query']),
    'get_game_cover' : IDL.Func([IDL.Text], [IDL.Text], ['query']),
    'get_owner' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Text)], ['query']),
    'get_total_games' : IDL.Func([], [IDL.Nat], ['query']),
    'get_total_visible_games' : IDL.Func([], [IDL.Nat], ['query']),
    'get_user_games' : IDL.Func(
        [IDL.Text, IDL.Nat],
        [IDL.Vec(Game)],
        ['query'],
      ),
    'get_users_total_games' : IDL.Func([IDL.Text], [IDL.Nat], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'remove_admin' : IDL.Func([IDL.Text], [], []),
    'remove_canister' : IDL.Func([IDL.Text], [], []),
    'remove_controller' : IDL.Func([IDL.Text, IDL.Text], [], []),
    'update_game_cover' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
    'update_game_data' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Text],
        [Result],
        [],
      ),
    'update_game_visibility' : IDL.Func([IDL.Text, IDL.Text], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
