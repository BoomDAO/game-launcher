export const idlFactory = ({ IDL }) => {
  const TokenIndex = IDL.Nat32;
  const AccountIdentifier = IDL.Text;
  const TokenIdentifier__1 = IDL.Text;
  const CommonError = IDL.Variant({
    'InvalidToken' : TokenIdentifier__1,
    'Other' : IDL.Text,
  });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Text, 'err' : CommonError });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : CommonError });
  const Info = IDL.Record({
    'status' : IDL.Text,
    'collection' : IDL.Text,
    'createdAt' : IDL.Int,
    'lowerBound' : IDL.Nat,
    'upperBound' : IDL.Nat,
    'burnAt' : IDL.Int,
  });
  const Collection = IDL.Record({
    'name' : IDL.Text,
    'canister_id' : IDL.Text,
  });
  const TokenIdentifier = IDL.Text;
  const TimerId = IDL.Nat;
  const AssetHandle = IDL.Text;
  return IDL.Service({
    'add_controller' : IDL.Func([IDL.Text, IDL.Text], [], []),
    'airdrop_to_addresses' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Bool, IDL.Int, IDL.Text],
        [IDL.Vec(TokenIndex)],
        [],
      ),
    'batch_mint_to_addresses' : IDL.Func(
        [IDL.Text, IDL.Vec(IDL.Text), IDL.Text, IDL.Nat32, IDL.Int, IDL.Text],
        [IDL.Vec(TokenIndex)],
        [],
      ),
    'bulk_burn_nfts' : IDL.Func([IDL.Text], [], []),
    'burnNft' : IDL.Func(
        [IDL.Text, TokenIndex, AccountIdentifier],
        [Result_1],
        [],
      ),
    'create_collection' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Nat64],
        [IDL.Text],
        [],
      ),
    'cycleBalance' : IDL.Func([], [IDL.Nat], ['query']),
    'external_burn' : IDL.Func([IDL.Text, TokenIndex], [Result], []),
    'getBurnInfo' : IDL.Func([IDL.Text], [IDL.Vec(Info)], ['query']),
    'getCollectionMetadata' : IDL.Func([IDL.Text], [IDL.Text, IDL.Text], []),
    'getCollections' : IDL.Func([IDL.Nat32], [IDL.Vec(Collection)], ['query']),
    'getOwner' : IDL.Func([IDL.Text], [IDL.Text], ['query']),
    'getRegistry' : IDL.Func([IDL.Text, IDL.Nat32], [IDL.Vec(IDL.Text)], []),
    'getSize' : IDL.Func([IDL.Text], [IDL.Nat], []),
    'getTokenIdentifier' : IDL.Func(
        [IDL.Text, TokenIndex],
        [TokenIdentifier],
        ['query'],
      ),
    'getTokenMetadata' : IDL.Func([IDL.Text, TokenIndex], [IDL.Text], []),
    'getTokenUrl' : IDL.Func([IDL.Text, TokenIndex], [IDL.Text], ['query']),
    'getTotalCollections' : IDL.Func([], [IDL.Nat], ['query']),
    'getUserCollections' : IDL.Func(
        [IDL.Text],
        [IDL.Vec(Collection)],
        ['query'],
      ),
    'getUserNfts' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Vec(IDL.Tuple(TokenIndex, IDL.Text))],
        [],
      ),
    'get_cron_id' : IDL.Func([], [TimerId], ['query']),
    'get_last_cron_timestamp' : IDL.Func([], [IDL.Int], ['query']),
    'remove_controller' : IDL.Func([IDL.Text, IDL.Text], [], []),
    'upload_asset_to_collection_for_dynamic_mint' : IDL.Func(
        [IDL.Text, AssetHandle, IDL.Vec(IDL.Nat8)],
        [],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
