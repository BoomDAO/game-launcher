import { Actor } from "@dfinity/agent";
import { getAgent, getAuthClient } from "@/utils";
// @ts-ignore
import { idlFactory as AssetFactory } from "../dids/asset.did.js";
// @ts-ignore
import { idlFactory as GamesDeployerFactory } from "../dids/games_deployer.did.js";

const deploy_canisterId = "6rvbl-uqaaa-aaaal-ab24a-cai";

export const useGameClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(GamesDeployerFactory, {
      agent,
      canisterId: deploy_canisterId,
    }),
    methods: {
      get_all_games: "get_all_asset_canisters",
      get_user_games: "get_user_games",
      get_game: "get_game",
      get_game_cover: "get_game_cover",
      get_total_games: "get_total_games",
      get_users_total_games: "get_users_total_games",

      create_game: "create_game_canister",
      update_game_data: "update_game_data",
      update_game_cover: "update_game_cover",
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
