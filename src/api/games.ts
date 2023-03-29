import { useMutation, useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/authContext";
import { useGameClient } from "@/hooks";
import { CreateGame, Game } from "@/types";

export const queryKeys = {
  games: "games",
  user_games: "user_games",
  game_cover: "game_cover",
};

export const useGetGamesCount = (page: number) =>
  useQuery([queryKeys.games, page], async () => {
    const { actor, methods } = await useGameClient();
    return (await actor[methods.get_all_games](page)) as Game[];
  });

export const useGetGames = (page: number) =>
  useQuery(
    [queryKeys.games, page],
    async () => {
      const { actor, methods } = await useGameClient();
      return (await actor[methods.get_all_games](page)) as Game[];
    },
    {
      keepPreviousData: true,
    },
  );

export const useGetGameCover = (canisterId?: string) =>
  useQuery(
    [queryKeys.game_cover, canisterId],
    async () => {
      const { actor, methods } = await useGameClient();
      return (await actor[methods.get_game_cover](canisterId)) as string;
    },
    {
      enabled: !!canisterId,
    },
  );

export const useGetUserGames = () => {
  const { session } = useAuth();

  return useQuery([queryKeys.user_games], async () => {
    const { actor, methods } = await useGameClient();
    return (await actor[methods.get_user_games](session?.address)) as Game[];
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
