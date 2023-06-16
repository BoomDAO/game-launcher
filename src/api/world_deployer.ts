import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";

import {
    World,
    CreateWorldData,
    CreateWorldSubmit
} from "@/types";
import {
    UseQueryResult,
    useMutation,
    useQuery,
    useQueryClient
} from "@tanstack/react-query";
import { useAuthContext } from "@/context/authContext";
import { useWorldDeployerClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import {
    formatCycleBalance,
    getAgent,
} from "@/utils";

//@ts-ignore
import { idlFactory as WorldDeployerFactory } from "../dids/world_deployer.did.js";

export const queryKeys = {
    worlds: "worlds",
    world: "world",
    worlds_total: "worlds_total",
    worlds_user_total: "worlds_user_total",
    user_worlds: "user_worlds",
    world_cover: "world_cover",
    cycle_balance: "cycle_balance",
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
