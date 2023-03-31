import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";
import {
  UseQueryResult,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { useAuth } from "@/context/authContext";
import { useGameClient } from "@/hooks";
import { navPaths } from "@/shared";
import { CreateGame, Game, UpdateGameData } from "@/types";
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
  useQuery({
    queryKey: [queryKeys.games_total],
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      return Number(await actor[methods.get_total_games]());
    },
  });

export const useGetTotalUserGames = () => {
  const { session } = useAuth();

  return useQuery({
    queryKey: [queryKeys.games_user_total],
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      return Number(
        await actor[methods.get_users_total_games](session?.address),
      );
    },
  });
};

export const useGetGames = (page: number = 1): UseQueryResult<Game[]> =>
  useQuery({
    queryKey: [queryKeys.games, page],
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      return await actor[methods.get_all_games](page - 1);
    },
  });

export const useGetGame = (canisterId?: string): UseQueryResult<Game> =>
  useQuery({
    queryKey: [queryKeys.game, canisterId],
    enabled: !!canisterId && canisterId !== "new",
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      const getGame = (await actor[methods.get_game](canisterId)) as Game[];
      return getGame[0];
    },
  });

export const useGetGameCover = (canisterId?: string): UseQueryResult<string> =>
  useQuery({
    queryKey: [queryKeys.game_cover, canisterId],
    enabled: !!canisterId,
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      return await actor[methods.get_game_cover](canisterId);
    },
  });

export const useGetUserGames = (page: number = 1): UseQueryResult<Game[]> => {
  const { session } = useAuth();

  return useQuery({
    queryKey: [queryKeys.user_games, page],
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      return await actor[methods.get_user_games](session?.address, page - 1);
    },
  });
};

export const useCreateGame = () => {
  const queryClient = useQueryClient();
  const { t } = useTranslation();
  const navigate = useNavigate();

  return useMutation({
    mutationFn: async (payload: CreateGame) => {
      const { actor, methods } = await useGameClient();

      return (await actor[methods.create_game](
        payload.name,
        payload.description,
        payload.cover,
        payload.platform,
      )) as string;
    },
    onError: (err) => {
      toast.error(t("upload_games.new.error_create"));
      console.log("err", err);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [queryKeys.user_games] });
      queryClient.invalidateQueries({ queryKey: [queryKeys.games_total] });
      queryClient.invalidateQueries({
        queryKey: [queryKeys.games_user_total],
      });
      toast.success(t("upload_games.new.success_create"));
      navigate(navPaths.upload_games);
    },
  });
};

export const useUpdateGameData = () => {
  const queryClient = useQueryClient();
  const { t } = useTranslation();
  const navigate = useNavigate();

  return useMutation({
    mutationFn: async (payload: UpdateGameData) => {
      const { actor, methods } = await useGameClient();

      await actor[methods.update_game_data](
        payload.canister_id,
        payload.name,
        payload.description,
      );

      if (payload.cover) {
        await actor[methods.update_game_cover](
          payload.canister_id,
          payload.cover,
        );
      }

      return payload.canister_id;
    },
    onError: (err) => {
      toast.error(t("upload_games.update.error_update"));
      console.log("err", err);
    },
    onSuccess: async (id) => {
      queryClient.invalidateQueries([queryKeys.user_games]);
      queryClient.invalidateQueries([queryKeys.game, id]);
      toast.success(t("upload_games.update.success_update"));
      navigate(navPaths.upload_games);
    },
  });
};

export const useGetCycleBalance = (
  canisterId?: string,
  showCycles?: boolean,
): UseQueryResult<string> =>
  useQuery({
    enabled: !!canisterId && !!showCycles,
    queryKey: [queryKeys.cycle_balance, canisterId],
    queryFn: async () => {
      const agent = await getAgent();
      const actor = Actor.createActor(GameFactory, {
        agent,
        canisterId: canisterId!,
      });

      const balance = Number(await actor.cycleBalance());
      return `${(balance * 0.0000000000001).toFixed(2)}T`;
    },
  });
