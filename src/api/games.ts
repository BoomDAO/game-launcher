import { useMutation, useQuery } from "@tanstack/react-query";
import { useGameClient } from "@/hooks";
import { CreateGame, Game } from "@/types";

export const queryKeys = {
  games: "games",
};

export const useGetGames = (page: number = 1) =>
  useQuery([queryKeys.games], async () => {
    const { actor, methods } = await useGameClient();
    return (await actor[methods.get_all_games](page)) as Game[];
  });

export const useCreateGame = () =>
  useMutation(async (payload: CreateGame) => {
    const { actor, methods } = await useGameClient();

    return await actor[methods.create_game](
      payload.name,
      payload.description,
      payload.image,
      payload.platform,
    );
  });
