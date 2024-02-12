import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";

import {
    CreateTokenData,
    CreateTokenSubmit,
    CreateTokenTransfer,
    Token,
    CreateTokenApprove,
    CreateTokenTransferFrom
} from "@/types";
import {
    UseQueryResult,
    useMutation,
    useQuery,
    useQueryClient,
} from "@tanstack/react-query";
import { useAuthContext } from "@/context/authContext";
import { useTokenDeployerClient, useTokenClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import {
    formatCycleBalance,
    getAgent,
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
            const { actor, methods } = await useTokenDeployerClient();
            return Number(await actor[methods.get_total_tokens]());
        },
    });

export const useGetTotalUserTokens = () => {
    const { session } = useAuthContext();

    return useQuery({
        queryKey: [queryKeys.tokens_user_total],
        queryFn: async () => {
            const { actor, methods } = await useTokenDeployerClient();
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
            const { actor, methods } = await useTokenDeployerClient();
            return await actor[methods.get_user_tokens](session?.address, page - 1);
        },
    });
};

export const useGetTokens = (page: number = 1): UseQueryResult<Token[]> => {
    const { session } = useAuthContext();

    return useQuery({
        queryKey: [queryKeys.tokens, page],
        queryFn: async () => {
            const { actor, methods } = await useTokenDeployerClient();
            return await actor[methods.get_tokens](page - 1);
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
                const { actor, methods } = await useTokenDeployerClient();
                const _decimals = 8;
                const _amount = payload.amount
                    ? BigInt(parseInt(payload.amount) * Math.pow(10, _decimals))
                    : BigInt(0);
                const _fee = parseInt(payload.fee)
                const canisterId = (await actor[methods.create_token](
                    payload.name,
                    payload.symbol,
                    payload.description,
                    _amount,
                    payload.logo,
                    _decimals,
                    _fee
                )) as string;
                console.log(canisterId);
                return canisterId;
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        }
    });


export const useCreateTokenUpload = () => {
    const queryClient = useQueryClient();
    const { t } = useTranslation();
    const navigate = useNavigate();

    return useMutation({
        mutationFn: async (payload: CreateTokenSubmit) => {
            const { name, symbol, description, logo, fee, amount } = payload.values;

            let canister_id = payload.canisterId;

            if (!canister_id) {
                canister_id = await payload.mutateData(
                    { description, name, logo, symbol, fee, amount },
                    {
                        onError: (err) => {
                            console.log("err", err);
                        },
                    },
                );
            }
            console.log(canister_id);
            return canister_id;
        },
        onSuccess: () => {
            toast.success(t("token_deployer.deploy_token.success"));
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


export const useTokenTransfer = (token_canister_id: string) =>
    useMutation({
        mutationFn: async (payload: CreateTokenTransfer) => {
            try {
                const { actor, methods } = await useTokenClient(token_canister_id);
                const _amount = payload.amount
                    ? BigInt(parseInt(payload.amount) * Math.pow(10, parseInt(String(await actor[methods.icrc1_decimals]()))))
                    : BigInt(0);
                const _p = Principal.fromText(payload.principal);
                const response = (await actor[methods.icrc1_transfer](
                    {
                        from_subaccount: [],
                        to: {
                            owner: _p,
                            subaccount: [],
                        },
                        amount: _amount,
                        fee: [],
                        memo: [],
                        created_at_time: [],
                    }
                )) as {
                    Ok: bigint,
                    Err: undefined
                };
                console.log(response);
                if (response.Ok == null) {
                    toast.error("Some error occured! Check Console!");
                } else {
                    toast.success("Transferred!");
                }
                return response;
            } catch (error) {
                if (error instanceof Error) {
                    toast.error(error.message);
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        }
    });

export const useTokenApprove = (token_canister_id: string) =>
    useMutation({
        mutationFn: async (payload: CreateTokenApprove) => {
            try {
                const { actor, methods } = await useTokenClient(token_canister_id);
                const _amount = payload.amount
                    ? BigInt(parseInt(payload.amount) * Math.pow(10, parseInt(String(await actor[methods.icrc1_decimals]()))))
                    : BigInt(0);
                const _fee = BigInt(parseInt(String(await actor[methods.icrc1_fee]())))
                const _spender = Principal.fromText(payload.spender);
                const response = (await actor[methods.icrc2_approve](
                    {
                        from_subaccount: [],
                        spender: {
                            owner: _spender,
                            subaccount: [],
                        },
                        amount: _amount,
                        expires_at: [],
                        expected_allowance: [],
                        memo: [],
                        fee: [_fee],
                        created_at_time: []
                    }
                )) as {
                    Ok: bigint,
                    Err: undefined
                };
                console.log(response);
                if (response.Ok == null) {
                    toast.error("Some error occured! Check Console!");
                } else {
                    toast.success("Transferred!");
                }
                return response;
            } catch (error) {
                if (error instanceof Error) {
                    toast.error(error.message);
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        }
    });

export const useTokenTransferFrom = (token_canister_id: string) =>
    useMutation({
        mutationFn: async (payload: CreateTokenTransferFrom) => {
            try {
                const { actor, methods } = await useTokenClient(token_canister_id);
                const _amount = payload.amount
                    ? BigInt(parseInt(payload.amount) * Math.pow(10, parseInt(String(await actor[methods.icrc1_decimals]()))))
                    : BigInt(0);
                const _fee = BigInt(parseInt(String(await actor[methods.icrc1_fee]())))
                const _from = Principal.fromText(payload.from);
                const _to = Principal.fromText(payload.to);
                const response = (await actor[methods.icrc2_transfer_from](
                    {
                        spender_subaccount: [],
                        from: {
                            owner: _from,
                            subaccount: [],
                        },
                        to: {
                            owner: _to,
                            subaccount: [],
                        },
                        amount: _amount,
                        fee: [_fee],
                        memo: [],
                        created_at_time: [],
                    }
                )) as {
                    Ok: bigint,
                    Err: undefined
                };
                console.log(response);
                if (response.Ok == null) {
                    toast.error("Some error occured! Check Console!");
                } else {
                    toast.success("Transferred!");
                }
                return response;
            } catch (error) {
                if (error instanceof Error) {
                    toast.error(error.message);
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        }
    });

