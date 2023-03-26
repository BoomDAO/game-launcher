import { useQuery } from "@tanstack/react-query";
import { CreateGame, Game } from "@/types";
import { getActor } from "@/utils";
// @ts-ignore
import { idlFactory } from "../dids/ic_games.did.js";

const canisterId = "6rvbl-uqaaa-aaaal-ab24a-cai";

const actor = await getActor(idlFactory, canisterId);

export const queryKeys = {
  games: "games",
};

export const useGetGames = (page: number = 1) =>
  useQuery(
    [queryKeys.games],
    async () => (await actor.get_all_asset_canisters(page)) as Game[],
  );

export const useCreateGame = (payload: CreateGame) =>
  useQuery(
    [queryKeys.games],
    async () => (await actor.create_game_canister()) as Game,
  );
