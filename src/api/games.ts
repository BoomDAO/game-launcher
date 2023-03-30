import { UseQueryResult, useMutation, useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/authContext";
import { useGameClient } from "@/hooks";
import { CreateGame, Game } from "@/types";

export const queryKeys = {
  games: "games",
  games_total: "games_total",
  user_games: "user_games",
  game_cover: "game_cover",
};

export const useGetGamesCount = () =>
  useQuery([queryKeys.games_total], async () => {
    const { actor, methods } = await useGameClient();
    return Number(await actor[methods.get_total_games]());
  });

export const useGetGames = (page: number): UseQueryResult<Game[]> =>
  useQuery([queryKeys.games, page], async () => {
    const { actor, methods } = await useGameClient();
    return await actor[methods.get_all_games](page - 1);
  });

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
