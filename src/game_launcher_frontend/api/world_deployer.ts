import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { getAuthClient } from "@/utils";
import { IDL } from "@dfinity/candid";

import {
  World,
  CreateWorldData,
  CreateWorldSubmit,
  UpgradeWorldData,
  WorldWasm
} from "@/types";
import {
  UseQueryResult,
  useMutation,
  useQuery,
  useQueryClient
} from "@tanstack/react-query";
import { useAuthContext } from "@/context/authContext";
import { useManagementClient, useWorldClient, useWorldDeployerClient, useWorldHubClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import {
  b64toArrays,
  formatCycleBalance,
  getAgent,
} from "@/utils";

//@ts-ignore
import { idlFactory as WorldDeployerFactory } from "../dids/world_deployer.did.js";
import { Float64 } from "@dfinity/candid/lib/cjs/idl.js";

export const queryKeys = {
  worlds: "worlds",
  world: "world",
  worlds_total: "worlds_total",
  worlds_user_total: "worlds_user_total",
  user_worlds: "user_worlds",
  world_cover: "world_cover",
  cycle_balance: "cycle_balance",
  current_world: "currentWorld",
  available_world: "availableWorld"
};

export const useGetWorldCycleBalance = (
  canisterId?: string,
  showCycles?: boolean,
): UseQueryResult<string> =>
  useQuery({
    enabled: !!canisterId && !!showCycles,
    queryKey: [queryKeys.cycle_balance, canisterId],
    queryFn: async () => {
      const agent = await getAgent();
      const actor = Actor.createActor(WorldDeployerFactory, {
        agent,
        canisterId: canisterId!,
      });

      const balance = Number(await actor.cycleBalance());
      return `${formatCycleBalance(balance)}T`;
    },
  });


export const useGetTotalWorlds = () =>
  useQuery({
    queryKey: [queryKeys.worlds_total],
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      return Number(await actor[methods.get_total_worlds]());
    },
  });

export const useGetWorldCover = (canisterId?: string): UseQueryResult<string> =>
  useQuery({
    queryKey: [queryKeys.world_cover, canisterId],
    enabled: !!canisterId,
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      const cover = await actor[methods.get_world_cover](canisterId);
      return cover;
    },
  });

export const useGetTotalUserWorlds = () => {
  const { session } = useAuthContext();

  return useQuery({
    queryKey: [queryKeys.worlds_user_total],
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      return Number(
        await actor[methods.get_users_total_worlds](session?.address),
      );
    },
  });
};

export const useGetUserWorlds = (page: number = 1): UseQueryResult<World[]> => {
  const { session } = useAuthContext();

  return useQuery({
    queryKey: [queryKeys.user_worlds, page],
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      return await actor[methods.get_user_worlds](session?.address, page - 1);
    },
  });
};

export const useGetCurrentWorldVersion = (world_canister_id: string = ""): UseQueryResult<string> => {
  return useQuery({
    queryKey: [queryKeys.current_world],
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      const res = await actor[methods.get_current_world_version](world_canister_id);
      return res;
    },
  });
};

export const useGetAvailableWorldVersion = (): UseQueryResult<string> => {
  return useQuery({
    queryKey: [queryKeys.available_world],
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      const res = await actor[methods.get_available_world_version]();
      return res;
    },
  });
};

export const useGetWorlds = (page: number = 1): UseQueryResult<World[]> => {
  const { session } = useAuthContext();

  return useQuery({
    queryKey: [queryKeys.worlds, page],
    queryFn: async () => {
      const { actor, methods } = await useWorldDeployerClient();
      return await actor[methods.get_worlds](page - 1);
    },
  });
};

export const useGetTokenCycleBalance = (
  canisterId?: string,
  showCycles?: boolean,
): UseQueryResult<string> =>
  useQuery({
    enabled: !!canisterId && !!showCycles,
    queryKey: [queryKeys.cycle_balance, canisterId],
    queryFn: async () => {
      const agent = await getAgent();
      const actor = Actor.createActor(WorldDeployerFactory, {
        agent,
        canisterId: canisterId!,
      });

      const balance = Number(await actor.cycleBalance());
      return `${formatCycleBalance(balance)}T`;
    },
  });

export const useCreateWorldData = () =>
  useMutation({
    mutationFn: async (payload: CreateWorldData) => {
      try {
        const { actor, methods } = await useWorldDeployerClient();
        const canisterId = (await actor[methods.create_world](
          payload.name,
          payload.cover
        )) as string;
        return canisterId;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    }
  });

export const useCreateWorldUpload = () => {
  const queryClient = useQueryClient();
  const { t } = useTranslation();
  const navigate = useNavigate();

  return useMutation({
    mutationFn: async (payload: CreateWorldSubmit) => {
      const { name, cover } = payload.values;

      let canister_id = payload.canisterId;

      if (!canister_id) {
        canister_id = await payload.mutateData(
          { name, cover },
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
      toast.success(t("world_deployer.create_world.success"));
      navigate(navPaths.world_deployer);
    },
    onSettled: () => {
      queryClient.refetchQueries({ queryKey: [queryKeys.worlds] });
      queryClient.refetchQueries({ queryKey: [queryKeys.user_worlds] });
      queryClient.refetchQueries({ queryKey: [queryKeys.worlds_total] });
      queryClient.refetchQueries({
        queryKey: [queryKeys.worlds_user_total],
      });
    },
  });
};

// export const useUpgradeWorld = () => {
//   const { t } = useTranslation();

//   return useMutation({
//     mutationFn: async ({
//       canisterId
//     }: {
//       canisterId?: string;
//     }) => {
//       try {
//         const { actor, methods } = await useWorldDeployerClient();
//         const authClient = await getAuthClient();
//         const identity = authClient?.getIdentity();
//         const owner_principal = Principal.fromText(identity.getPrincipal().toString());
//         const owner = IDL.encode([IDL.Principal], [owner_principal]);
//         let res = (await actor[methods.upgrade_world](
//           canisterId,
//           owner
//         )) as {
//           ok: void;
//           err: string;
//         };

//         if (res.err != undefined) {
//           throw (res.err)
//         }
//       } catch (error) {
//         if (error instanceof Error) {
//           throw error.message;
//         }
//         throw serverErrorMsg;
//       }
//     },
//     onError: () => {
//       toast.error(t("world_deployer.manage_worlds.tabs.item_4.upgrade_error"));
//     },
//     onSuccess: () => {
//       toast.success(t("world_deployer.manage_worlds.tabs.item_4.upgrade_success"));
//     },
//   });
// };

export const useImportUsersData = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      ofCanisterId,
      canisterId
    }: {
      ofCanisterId: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");

        return await actor[methods.importAllUsersDataOfWorld](ofCanisterId);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_2.import_user.error"));
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_2.import_user.success"));
    },
  });
};

export const useImportConfigsData = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      ofCanisterId,
      canisterId
    }: {
      ofCanisterId: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");

        return await actor[methods.importAllConfigsOfWorld](ofCanisterId);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_2.import_config.error"));
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_2.import_config.success"));
    },
  });
};

export const useImportActionsData = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      ofCanisterId,
      canisterId
    }: {
      ofCanisterId: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");

        return await actor[methods.importAllActionsOfWorld](ofCanisterId);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_2.import_config.error"));
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_2.import_config.success"));
    },
  });
};

export const useImportPermissionsData = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      ofCanisterId,
      canisterId
    }: {
      ofCanisterId: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");
        return await actor[methods.importAllPermissionsOfWorld](ofCanisterId);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_2.import_permissions.error"));
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_2.import_permissions.success"));
    },
  });
};

export const useAddController = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldDeployerClient();
        return await actor[methods.add_controller](canisterId, principal);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.controller.add.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.controller.add.success"));
    },
  });
};

export const useRemoveController = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldDeployerClient();
        return await actor[methods.remove_controller](canisterId, principal);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.controller.remove.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.controller.remove.success"));
    },
  });
};

export const useAddAdmin = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");
        console.log(principal + " " + canisterId);
        return await actor[methods.add_admin]({principal : principal});
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.admin.add.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.admin.add.success"));
    },
  });
};

export const useRemoveAdmin = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      principal,
      canisterId,
    }: {
      principal: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");

        return await actor[methods.remove_admin]({principal : principal});
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("manage_nfts.update.admin.remove.error"));
    },
    onSuccess: () => {
      toast.success(t("manage_nfts.update.admin.remove.success"));
    },
  });
};

export const useAddTrustedOrigin = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      url,
      canisterId,
    }: {
      url: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");

        return await actor[methods.addTrustedOrigin](url);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_4.manage.add_error"));
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_4.manage.add_success"));
    },
  });
};

export const useRemoveTrustedOrigin = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      url,
      canisterId,
    }: {
      url: string;
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");

        return await actor[methods.removeTrustedOrigin](url);
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_4.manage.remove_error"));
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_4.manage.remove_success"));
    },
  });
};

export const useGetTrustedOrigins = () => {
  const { t } = useTranslation();

  return useMutation({
    mutationFn: async ({
      canisterId,
    }: {
      canisterId?: string;
    }) => {
      try {
        const { actor, methods } = await useWorldClient((canisterId != undefined) ? canisterId : "");
        const data = (await actor[methods.getTrustedOrigins]()) as string[];
        console.log(data);
        return data;
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_4.view.not_found"));
    }
  });
};

export const useUpdateWorldDetails = () => {
  const { t } = useTranslation();
  return useMutation({
    mutationFn: async ({
      canisterId,
      name,
      cover
    } : {
      canisterId?: string,
      name: string,
      cover: string
    }) => {
      try {
        const { actor, methods } = await useWorldDeployerClient();
        console.log(canisterId);
        if(name != "") {
          (await actor[methods.update_name](canisterId? canisterId : "", name));
        }
        if(cover != "") {
          (await actor[methods.update_cover](canisterId, cover));
        }
      } catch (error) {
        if (error instanceof Error) {
          throw error.message;
        }
        throw serverErrorMsg;
      }
    },
    onSuccess: () => {
      toast.success(t("world_deployer.manage_worlds.tabs.item_5.success_msg"));
    },
    onError: () => {
      toast.error(t("world_deployer.manage_worlds.tabs.item_5.error_msg"));
    }
  })};