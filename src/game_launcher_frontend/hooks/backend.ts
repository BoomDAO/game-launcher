import { Actor } from "@dfinity/agent";
import { getAgent, getAuthClient } from "@/utils";
// @ts-ignore
import { idlFactory as AssetFactory } from "../dids/asset.did.js";
// @ts-ignore
import { idlFactory as ExtFactory } from "../dids/ext.did.js";
// @ts-ignore
import { idlFactory as GamesDeployerFactory } from "../dids/games_deployer.did.js";
// @ts-ignore
import { idlFactory as LedgerFactory } from "../dids/ledger.did.js";
// @ts-ignore
import { idlFactory as MintingDeployerFactory } from "../dids/minting_deployer.did.js";
// @ts-ignore
import { idlFactory as ManagementFactory } from "../dids/minting_deployer.did.js";
//@ts-ignore
import { idlFactory as TokenDeployerFactory } from "../dids/token_deployer.did.js";
//@ts-ignore
import { idlFactory as TokenFactory } from "../dids/icrc.did.js";
//@ts-ignore
import { idlFactory as WorldDeployerFactory } from "../dids/world_deployer.did.js";


const ledger_canisterId = "ryjl3-tyaaa-aaaaa-aaaba-cai";
const managenemt_canisterId = "aaaaa-aa";
const ext_canisterId = "4qmvs-qyaaa-aaaal-ab2rq-cai";

// Stag Backend Canisters
// const games_canisterId = "ltwhn-5iaaa-aaaao-askdq-cai";
// const minting_canisterId = "fbkar-zaaaa-aaaal-qbzca-cai";
// const token_deployerId = "pffwa-eiaaa-aaaam-abn5a-cai"; 
// const world_deployerId = "na2jz-uqaaa-aaaal-qbtfq-cai"; 

// Prod Backend Canisters
const games_canisterId = "6rvbl-uqaaa-aaaal-ab24a-cai"; 
const minting_canisterId = "zeroy-xaaaa-aaaag-qb7da-cai"; 
const token_deployerId = "qx76v-6qaaa-aaaal-acmla-cai"; 
const world_deployerId = "a6t6i-riaaa-aaaal-acphq-cai"; 

export const useWorldDeployerClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();
  const agent = await getAgent(identity);
  return {
    actor: Actor.createActor(WorldDeployerFactory, {
      agent,
      canisterId: world_deployerId,
    }),
    methods: {
      get_all_worlds: "getAllWorlds",
      get_user_worlds: "getUserWorlds",
      get_all_admins: "getAllAdmins",
      get_world: "getWorldDetails",
      get_worlds: "getWorlds",
      get_users_total_worlds: "getUserTotalWorlds",
      get_total_worlds: "getTotalWorlds",
      get_world_cover: "getWorldCover",
      
      create_world: "createWorldCanister",
      update_world_cover: "updateWorldCover",
      cycleBalance: "cycleBalance"
    }
  }
};

export const useTokenDeployerClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(TokenDeployerFactory, {
      agent,
      canisterId: token_deployerId,
    }),
    methods: {
      get_all_tokens: "getAllTokens",
      get_user_tokens: "getUserTokens",
      get_all_admins: "getAllAdmins",
      get_token: "getTokenDetails",
      get_tokens: "getTokens",
      get_users_total_tokens: "getUserTotalTokens",
      get_total_tokens: "getTotalTokens",

      create_token: "createTokenCanister",
      update_token_cover: "updateTokenCover"
    }
  }
}

export const useTokenClient = async (token_canister_id : string) => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(TokenFactory, {
      agent,
      canisterId: token_canister_id,
    }),
    methods: {
      icrc1_transfer: "icrc1_transfer",
      icrc2_allowance: "icrc2_allowance",
      icrc2_approve: "icrc2_approve",
      icrc1_decimals: "icrc1_decimals",
      icrc1_fee: "icrc1_fee",
      icrc2_transfer_from: "icrc2_transfer_from"
    }
  }
}

export const useGameClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(GamesDeployerFactory, {
      agent,
      canisterId: games_canisterId,
    }),
    methods: {
      get_all_games: "get_all_asset_canisters",
      get_user_games: "get_user_games",
      get_game: "get_game",
      get_game_cover: "get_game_cover",
      get_total_games: "get_total_games",
      get_total_visible_games: "get_total_visible_games",
      get_users_total_games: "get_users_total_games",

      create_game: "create_game_canister",
      update_game_data: "update_game_data",
      update_game_cover: "update_game_cover",
      update_game_visibility: "update_game_visibility",
      update_game_release: "update_game_release"
    },
  };
};

export const useAssetClient = async (canister_id: string) => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(AssetFactory, {
      agent,
      canisterId: canister_id,
    }),
    methods: {
      clear: "clear",
      commit_asset_upload: "commit_asset_upload",
      create_batch: "create_batch",
      create_chunk: "create_chunk",
    },
  };
};

export const useMintingDeployerClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(MintingDeployerFactory, {
      agent,
      canisterId: minting_canisterId,
    }),
    methods: {
      get_collections: "getUserCollections",
      get_all_collections: "getCollections",
      get_total_collections: "getTotalCollections",
      create_collection: "create_collection",
      getRegistry: "getRegistry",
      getTokenMetadata: "getTokenMetadata",
      getTokenUrl: "getTokenUrl",
      add_controller: "add_controller",
      remove_controller: "remove_controller",
      external_burn: "external_burn",
      airdrop_to_addresses: "airdrop_to_addresses",
      batch_mint_to_addresses: "batch_mint_to_addresses",
      upload_asset: "upload_asset_to_collection_for_dynamic_mint",
    },
  };
};

export const useLedgerClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(LedgerFactory, {
      agent,
      canisterId: ledger_canisterId,
    }),
    methods: {},
  };
};

export const useExtClient = async (canister_id?: string) => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(ExtFactory, {
      agent,
      canisterId: canister_id || ext_canisterId,
    }),
    methods: {
      add_admin: "ext_addAdmin",
      remove_admin: "ext_removeAdmin",
      get_asset_ids: "get_all_assetHandles",
      get_asset_encoding: "get_asset_encoding"
    },
  };
};

export const useManagementClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(ManagementFactory, {
      agent,
      canisterId: managenemt_canisterId,
    }),
    methods: {},
  };
};
