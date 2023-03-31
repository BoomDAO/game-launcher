import { Actor } from "@dfinity/agent";
import { UseQueryResult, useMutation, useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/authContext";
import { useGameClient } from "@/hooks";
import { CreateGame, Game } from "@/types";
import { getAgent } from "@/utils";
// @ts-ignore
import { idlFactory as GameFactory } from "../dids/ic_games.did.js";

export const queryKeys = {
  games: "games",
  game: "game",
  games_total: "games_total",
  games_user_total: "games_user_total",
  user_games: "user_games",
  game_cover: "game_cover",
  cycle_balance: "cycle_balance",
};

export const useGetTotalGames = () =>
  useQuery([queryKeys.games_total], async () => {
    const { actor, methods } = await useGameClient();
    return Number(await actor[methods.get_total_games]());
  });

export const useGetTotalUserGames = () => {
  const { session } = useAuth();

  return useQuery([queryKeys.games_user_total], async () => {
    const { actor, methods } = await useGameClient();
    return Number(await actor[methods.get_users_total_games](session?.address));
  });
};

export const useGetGames = (page: number): UseQueryResult<Game[]> =>
  useQuery([queryKeys.games, page], async () => {
    const { actor, methods } = await useGameClient();
    return await actor[methods.get_all_games](page - 1);
  });

export const useGetGame = (canisterId?: string): UseQueryResult<Game> =>
  useQuery(
    [queryKeys.game, canisterId],
    async () => {
      const { actor, methods } = await useGameClient();
      const getGame = (await actor[methods.get_game](canisterId)) as Game[];
      return getGame[0];
    },
    {
      enabled: !!canisterId && canisterId !== "new",
    },
  );

export const useGetGameCover = (canisterId?: string): UseQueryResult<string> =>
  useQuery(
    [queryKeys.game_cover, canisterId],
    async () => {
      const { actor, methods } = await useGameClient();
      return await actor[methods.get_game_cover](canisterId);
    },
    {
      enabled: !!canisterId,
    },
  );

export const useGetUserGames = (page: number): UseQueryResult<Game[]> => {
  const { session } = useAuth();

  return useQuery([queryKeys.user_games, page], async () => {
    const { actor, methods } = await useGameClient();
    return await actor[methods.get_user_games](session?.address, page - 1);
  });
};

export const useCreateGame = () =>
  useMutation(async (payload: CreateGame) => {
    const { actor, methods } = await useGameClient();

    return await actor[methods.create_game](
      payload.name,
      payload.description,
      payload.cover,
      payload.platform,
    );
  });

export const useGetCycleBalance = (
  canisterId?: string,
  showCycles?: boolean,
): UseQueryResult<string> =>
  useQuery(
    [queryKeys.cycle_balance, canisterId],
    async () => {
      const agent = await getAgent();
      const actor = Actor.createActor(GameFactory, {
        agent,
        canisterId: canisterId!,
      });

      const balance = Number(await actor.cycleBalance());
      return `${(balance * 0.0000000000001).toFixed(2)}T`;
    },
    {
      enabled: !!canisterId && !!showCycles,
    },
  );
