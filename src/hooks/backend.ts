import { Actor } from "@dfinity/agent";
import { getAgent, getAuthClient } from "@/utils";
// @ts-ignore
import { idlFactory as GameFactory } from "../dids/ic_games.did.js";

const game_canisterId = "6rvbl-uqaaa-aaaal-ab24a-cai";

export const useGameClient = async () => {
  const authClient = await getAuthClient();
  const identity = authClient?.getIdentity();

  const agent = await getAgent(identity);

  return {
    actor: Actor.createActor(GameFactory, {
      agent,
      canisterId: game_canisterId,
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
