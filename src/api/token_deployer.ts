import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";

import {
    CreateTokenData,
    CreateTokenSubmit,
    Token,
} from "@/types";
import {
    UseQueryResult,
    useMutation,
    useQuery,
    useQueryClient,
} from "@tanstack/react-query";
import { useAuthContext } from "@/context/authContext";
import { useTokenClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import {
    formatCycleBalance,
    getAgent,
    uploadGameFiles,
    uploadZip,
} from "@/utils";

//@ts-ignore
import { idlFactory as TokenDeployerFactory } from "../dids/token_deployer.did.js";

export const queryKeys = {
    tokens: "tokens",
    token: "token",
    tokens_total: "tokens_total",
    tokens_user_total: "tokens_user_total",
    user_tokens: "user_tokens",
    token_cover: "token_cover",
    cycle_balance: "cycle_balance",
};


export const useGetTotalTokens = () =>
    useQuery({
        queryKey: [queryKeys.tokens_total],
        queryFn: async () => {
            const { actor, methods } = await useTokenClient();
            return Number(await actor[methods.get_total_tokens]());
        },
    });

export const useGetTotalUserTokens = () => {
    const { session } = useAuthContext();

    return useQuery({
        queryKey: [queryKeys.tokens_user_total],
        queryFn: async () => {
            const { actor, methods } = await useTokenClient();
            return Number(
                await actor[methods.get_users_total_tokens](session?.address),
            );
        },
    });
};

export const useGetUserTokens = (page: number = 1): UseQueryResult<Token[]> => {
    const { session } = useAuthContext();

    return useQuery({
        queryKey: [queryKeys.user_tokens, page],
        queryFn: async () => {
            const { actor, methods } = await useTokenClient();
            return await actor[methods.get_user_tokens](session?.address, page - 1);
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
            const actor = Actor.createActor(TokenDeployerFactory, {
                agent,
                canisterId: canisterId!,
            });

            const balance = Number(await actor.cycleBalance());
            return `${formatCycleBalance(balance)}T`;
        },
    });


export const useCreateTokenData = () =>
    useMutation({
        mutationFn: async (payload: CreateTokenData) => {
            try {
                const { actor, methods } = await useTokenClient();

                const canisterId = (await actor[methods.create_token](
                    payload.name,
                    payload.symbol,
                    payload.description,
                    payload.amount,
                    payload.logo,
                    payload.decimals,
                    payload.fee
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


export const useCreateTokenUpload = () => {
    const queryClient = useQueryClient();
    const { t } = useTranslation();
    const navigate = useNavigate();

    return useMutation({
        mutationFn: async (payload: CreateTokenSubmit) => {
            const { name, symbol, description, logo, decimals, fee, amount } = payload.values;

            let canister_id = payload.canisterId;

            if (!canister_id) {
                canister_id = await payload.mutateData(
                    { description, name, logo, symbol, fee, amount, decimals },
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
            toast.success(t("token_deployer.deploy_token.success_update"));
            navigate(navPaths.token_deployer);
        },
        onSettled: () => {
            queryClient.refetchQueries({ queryKey: [queryKeys.tokens] });
            queryClient.refetchQueries({ queryKey: [queryKeys.user_tokens] });
            queryClient.refetchQueries({ queryKey: [queryKeys.tokens_total] });
            queryClient.refetchQueries({
                queryKey: [queryKeys.tokens_user_total],
            });
        },
    });
};