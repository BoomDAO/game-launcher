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
import { useAuthContext } from "@/context/authContext";
import { useGameClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import {
  CreateGameData,
  CreateGameFiles,
  CreateGameSubmit,
  Game,
  UpdateGameCover,
  UpdateGameData,
  UpdateGameSubmit,
} from "@/types";
import { getAgent, uploadGameFiles, uploadZip } from "@/utils";
// @ts-ignore
import { idlFactory as DeployerFactory } from "../dids/deployer.did.js";

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
  const { session } = useAuthContext();

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
  const { session } = useAuthContext();

  return useQuery({
    queryKey: [queryKeys.user_games, page],
    queryFn: async () => {
      const { actor, methods } = await useGameClient();
      return await actor[methods.get_user_games](session?.address, page - 1);
    },
  });
};

export const useCreateGameData = () =>
  useMutation({
    mutationFn: async (payload: CreateGameData) => {
      try {
        const { actor, methods } = await useGameClient();

        const canisterId = (await actor[methods.create_game](
          payload.name,
          payload.description,
          payload.cover,
          payload.platform,
        )) as string;

        return canisterId;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useCreateGameFiles = () =>
  useMutation({
    mutationFn: async (payload: CreateGameFiles) => {
      try {
        if (payload.platform === "Browser") {
          await uploadGameFiles(payload.canister_id, payload.files);
        } else {
          await uploadZip(payload);
        }

        return payload.canister_id;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useUpdateGameData = () =>
  useMutation({
    mutationFn: async (payload: UpdateGameData) => {
      try {
        const { actor, methods } = await useGameClient();

        await actor[methods.update_game_data](
          payload.canister_id,
          payload.name,
          payload.description,
          payload.platform,
        );

        return payload.canister_id;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useUpdateGameCover = () =>
  useMutation({
    mutationFn: async (payload: UpdateGameCover) => {
      try {
        const { actor, methods } = await useGameClient();

        await actor[methods.update_game_cover](
          payload.canister_id,
          payload.cover,
        );

        return payload.canister_id;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
  });

export const useGetCycleBalance = (
  canisterId?: string,
  showCycles?: boolean,
): UseQueryResult<string> =>
  useQuery({
    enabled: !!canisterId && !!showCycles,
    queryKey: [queryKeys.cycle_balance, canisterId],
    queryFn: async () => {
      const agent = await getAgent();
      const actor = Actor.createActor(DeployerFactory, {
        agent,
        canisterId: canisterId!,
      });

      const balance = Number(await actor.cycleBalance());
      return `${(balance * 0.0000000000001).toFixed(2)}T`;
    },
  });

// Submit functions
export const useCreateGameUpload = () => {
  const queryClient = useQueryClient();
  const { t } = useTranslation();
  const navigate = useNavigate();

  return useMutation({
    mutationFn: async (payload: CreateGameSubmit) => {
      const { cover, description, files, name, platform } = payload.values;

      let canister_id = payload.canisterId;

      if (!canister_id) {
        canister_id = await payload.mutateData(
          { description, name, cover, platform },
          {
            onError: (err) => {
              console.log("err", err);
            },
          },
        );
      }

      await payload.mutateFiles(
        { canister_id, description, name, platform, files },
        {
          onError: (err) => {
            console.log("err", err);
            throw { canister_id };
          },
        },
      );

      return canister_id;
    },
    onSuccess: () => {
      toast.success(t("upload_games.create.success_update"));
      navigate(navPaths.upload_games);
    },
    onSettled: () => {
      queryClient.refetchQueries({ queryKey: [queryKeys.games] });
      queryClient.refetchQueries({ queryKey: [queryKeys.user_games] });
      queryClient.refetchQueries({ queryKey: [queryKeys.games_total] });
      queryClient.refetchQueries({
        queryKey: [queryKeys.games_user_total],
      });
    },
  });
};

export const useUpdateGameSubmit = () => {
  const queryClient = useQueryClient();
  const { t } = useTranslation();
  const navigate = useNavigate();

  return useMutation({
    mutationFn: async (payload: UpdateGameSubmit) => {
      const { canister_id, cover, description, files, name, platform } =
        payload.values;

      await payload.mutateData(
        { description, canister_id, name, platform },
        {
          onError: (err) => {
            console.log("err", err);
          },
        },
      );

      if (cover) {
        await payload.mutateCover(
          { canister_id, cover },
          {
            onError: (err) => {
              console.log("err", err);
            },
          },
        );
      }

      if (files.length) {
        await payload.mutateFiles(
          { canister_id, description, name, platform, files },
          {
            onError: (err) => {
              console.log("err", err);
            },
          },
        );
      }

      return canister_id;
    },
    onSuccess: () => {
      toast.success(t("upload_games.update.success_update"));
      navigate(navPaths.upload_games);
    },
    onSettled: (canister_id) => {
      queryClient.refetchQueries({ queryKey: [queryKeys.games] });
      queryClient.refetchQueries({ queryKey: [queryKeys.user_games] });
      queryClient.invalidateQueries([queryKeys.game, canister_id]);
    },
  });
};
