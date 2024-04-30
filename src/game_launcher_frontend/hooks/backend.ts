import { Actor } from "@dfinity/agent";
import { getAgent, getAuthClient, getNfid } from "@/utils";
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
import { idlFactory as ManagementFactory } from "../dids/management.did.js";
//@ts-ignore
import { idlFactory as TokenDeployerFactory } from "../dids/token_deployer.did.js";
//@ts-ignore
import { idlFactory as TokenFactory } from "../dids/icrc.did.js";
//@ts-ignore
import { idlFactory as WorldDeployerFactory } from "../dids/world_deployer.did.js";
//@ts-ignore
import { idlFactory as WorldHubFactory } from "../dids/world_hub.did.js";
//@ts-ignore
import { idlFactory as WorldFactory } from "../dids/world.did.js";
//@ts-ignore
import { idlFactory as GuildsVerifierFactory } from "../dids/guilds_verifier.did.js"
// @ts-ignore 
import { idlFactory as GamingGuildsFactory } from "../dids/gaming_guilds.did.js"
// @ts-ignore
import { idlFactory as BOOMLedgerFactory } from "../dids/boom_ledger.did.js"
// @ts-ignore
import { idlFactory as GamingGuildsWorldNodeFactory } from "../dids/gaming_guilds_worldnode.did.js";

const ledger_canisterId = "ryjl3-tyaaa-aaaaa-aaaba-cai";
const managenemt_canisterId = "aaaaa-aa";
const ext_canisterId = "4qmvs-qyaaa-aaaal-ab2rq-cai";
const boom_ledger_canisterId = "vtrom-gqaaa-aaaaq-aabia-cai";

//Staging

// const games_canisterId = "ltwhn-5iaaa-aaaao-askdq-cai"; 
// const minting_canisterId = "fbkar-zaaaa-aaaal-qbzca-cai"; 
// const token_deployerId = "pffwa-eiaaa-aaaam-abn5a-cai"; 
// const world_deployerId = "na2jz-uqaaa-aaaal-qbtfq-cai"; 
// const worldHubCanisterId = "c5moj-piaaa-aaaal-qdhoq-cai";
// const guildsVerifierCanisterId = "yv22q-myaaa-aaaal-adeuq-cai"
// export const gamingGuildsCanisterId = "6ehny-oaaaa-aaaal-qclyq-cai";
// const gamingGuildsWorldNodeCanisterId = "hiu7q-siaaa-aaaal-qdhqq-cai";

//Production

const games_canisterId = "6rvbl-uqaaa-aaaal-ab24a-cai"; 
const minting_canisterId = "j474s-uqaaa-aaaap-abf6q-cai"; 
const token_deployerId = "jv4xo-cyaaa-aaaap-abf7a-cai"; 
const world_deployerId = "js5r2-paaaa-aaaap-abf7q-cai"; 
const worldHubCanisterId = "j362g-ziaaa-aaaap-abf6a-cai";
const guildsVerifierCanisterId = "jvcsg-6aaaa-aaaan-qeqvq-cai"
export const gamingGuildsCanisterId = "erej6-riaaa-aaaap-ab4ma-cai";
const gamingGuildsWorldNodeCanisterId = "ewfpk-4qaaa-aaaap-ab4mq-cai";

//Development

// const games_canisterId = "6rvbl-uqaaa-aaaal-ab24a-cai"; 
// const minting_canisterId = "j474s-uqaaa-aaaap-abf6q-cai"; 
// const token_deployerId = "jv4xo-cyaaa-aaaap-abf7a-cai"; 
// const world_deployerId = "js5r2-paaaa-aaaap-abf7q-cai"; 
// const worldHubCanisterId = "j362g-ziaaa-aaaap-abf6a-cai";
// const guildsVerifierCanisterId = "jvcsg-6aaaa-aaaan-qeqvq-cai"
// export const gamingGuildsCanisterId = "7d6va-pyaaa-aaaap-ahdxa-cai";
// const gamingGuildsWorldNodeCanisterId = "7e7tu-caaaa-aaaap-ahdxq-cai";


export const useWorldDeployerClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();
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
      get_current_world_version: "getWorldVersion",
      get_available_world_version: "getLatestWorldWasmVersion",
      
      create_world: "createWorldCanister",
      update_world_cover: "updateWorldCover",
      cycleBalance: "cycleBalance",
      add_controller: "addController",
      remove_controller: "removeController",
      upgrade_world: "upgradeWorldToNewWasm",
      update_name: "updateWorldName",
      update_cover: "updateWorldCover"
    }
  }
};

export const useWorldHubClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();
  const agent = await getAgent(identity);
  return {
    actor: Actor.createActor(WorldHubFactory, {
      agent,
      canisterId: worldHubCanisterId,
    }),
    methods: {
      importAllUsersDataOfWorld: "importAllUsersDataOfWorld",
      importAllPermissionsOfWorld: "importAllPermissionsOfWorld",
      getUserProfile: "getUserProfile",
      setUsername: "setUsername",
      uploadProfilePicture: "uploadProfilePicture",
      getActionHistory: "getActionHistory",
      getActionHistoryComposite: "getActionHistoryComposite",
      createNewUser: "createNewUser"
    }
  }
};

export const useWorldClient = async (canisterId : string) => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();
  const agent = await getAgent(identity);
  return {
    actor: Actor.createActor(WorldFactory, {
      agent,
      canisterId: canisterId,
    }),
    methods: {
      importAllActionsOfWorld: "importAllActionsOfWorld",
      importAllConfigsOfWorld: "importAllConfigsOfWorld",
      importAllPermissionsOfWorld: "importAllPermissionsOfWorld",
      importAllUsersDataOfWorld: "importAllUsersDataOfWorld",
      add_admin: "addAdmin",
      remove_admin: "removeAdmin",
      addTrustedOrigin: "addTrustedOrigins",
      removeTrustedOrigin: "removeTrustedOrigins",
      getTrustedOrigins: "get_trusted_origins",
      getAllConfigs: "getAllConfigs",
    }
  }
};

export const useTokenDeployerClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
      
      add_controller: "add_controller",
      remove_controller: "remove_controller",

      create_game: "create_game_canister",
      update_game_data: "update_game_data",
      update_game_cover: "update_game_cover",
      update_game_visibility: "update_game_visibility",
      update_game_release: "update_game_release"
    },
  };
};

export const useAssetClient = async (canister_id: string) => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

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
      get_asset_encoding: "get_asset_encoding",
      getRegistry: "getRegistry",
      transfer: "transfer"
    },
  };
};

export const useManagementClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(ManagementFactory, {
      agent,
      canisterId: managenemt_canisterId,
    }),
    methods: {
      add_controller: "update_settings",
      remove_controller: "update_settings",
      canister_status: "canister_status"
    },
  };
};


export const useGuildsVerifierClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(GuildsVerifierFactory, {
      agent,
      canisterId: guildsVerifierCanisterId,
    }),
    methods: {
      sendVerificationEmail: "sendVerificationEmail",
      sendVerificationSMS: "sendVerificationSMS",
      verifyOTP: "verifyOTP",
      verifySmsOTP: "verifySmsOTP"
    },
  };
};

export const useGamingGuildsClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(GamingGuildsFactory, {
      agent,
      canisterId: gamingGuildsCanisterId,
    }),
    methods: {
      getAllConfigs: "getAllConfigs",
      getAllActions: "getAllActions",
      getAllUserEntities: "getAllUserEntities",
      getAllUserEntitiesComposite: "getAllUserEntitiesComposite",
      validateEntityConstraints: "validateEntityConstraints",
      processAction: "processAction",
      processActionAwait: "processActionAwait",
      validateConstraints: "validateConstraints",
      getAllUserActionStates: "getAllUserActionStates",
      getActionStatusComposite: "getActionStatusComposite",
      getAllUserActionStatesComposite: "getAllUserActionStatesComposite"
    },
  };
};

export const useGamingGuildsWorldNodeClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(GamingGuildsWorldNodeFactory, {
      agent,
      canisterId: gamingGuildsWorldNodeCanisterId,
    }),
    methods: {
      getAllUserEntities: "getAllUserEntities",
      getSpecificUserEntities: "getSpecificUserEntities",
      getAllUserEntitiesOfSpecificWorlds: "getAllUserEntitiesOfSpecificWorlds",
      getAllUserActionStates: "getAllUserActionStates",
      getActionHistory: "getActionHistory",
      getUserEntitiesFromWorldNodeComposite: "getUserEntitiesFromWorldNodeComposite",
      getUserEntitiesFromWorldNodeFilteredSortingComposite: "getUserEntitiesFromWorldNodeFilteredSortingComposite"
    },
  };
};

export const useBoomLedgerClient = async () => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(BOOMLedgerFactory, {
      agent,
      canisterId: boom_ledger_canisterId,
    }),
    methods: {
      icrc1_balance_of: "icrc1_balance_of"
    },
  };
};


export const useICRCLedgerClient = async (canister_id: string) => {
  // const authClient = await getAuthClient();
  // const identity = authClient?.getIdentity();
  const nfidClient = await getNfid();
  const identity = nfidClient.getIdentity();
  const agent = await getAgent(identity);
  return {
    actor: Actor.createActor(BOOMLedgerFactory, {
      agent,
      canisterId: canister_id,
    }),
    methods: {
      icrc1_balance_of: "icrc1_balance_of",
      icrc1_transfer: "icrc1_transfer",
      icrc1_fee: "icrc1_fee"
    },
  };
};