import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import {
    UseQueryResult,
    useMutation,
    useQuery,
    useQueryClient,
} from "@tanstack/react-query";
import { ledger_canisterId, swapCanisterId, useICRCLedgerClient, useLedgerClient, useSwapCanisterClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import { useAuthContext } from "@/context/authContext";
import { LaunchCardProps, ParticipantDetails, TokensInfo } from "@/types";
import DialogProvider from "@/components/DialogProvider";
import Button from "@/components/ui/Button";
import { string } from "zod";
import { AccountIdentifier } from "@dfinity/ledger-icp";
import Tokens from "../locale/en/Tokens.json";

export const queryKeys = {
    tokens_info: "tokens_info",
    participant_details: "participant_details"
};

function closeToast() {
    clearTimeout(setTimeout(() => {
        toast.remove();
    }, 3000));
};

function isDescriptionPlainText(data: { 'formattedText': string } | { 'plainText': string }): data is { 'plainText': string } {
    return ((data as { 'plainText': string }) !== undefined);
}

const msToTime = (ms: number) => {
    let seconds = Math.floor(ms / 1000);
    let minutes = Math.floor(seconds / 60);
    let hours = Math.floor(minutes / 60);
    seconds = seconds % 60;
    minutes = minutes % 60;
    let days = (hours / 24).toString().split(".")[0];
    hours = hours % 24;
    let res = {
        days: (days != "") ? days : "",
        hrs: (hours != 0) ? String(hours) : "",
        mins: (minutes != 0) ? String(minutes) : ""
    };
    return res;
}

export const useGetTokenInfo = (): UseQueryResult<Array<LaunchCardProps>> => {
    const { session } = useAuthContext();
    const { canisterId } = useParams();
    return useQuery({
        queryKey: [queryKeys.tokens_info, canisterId],
        queryFn: async () => {
            const { actor, methods } = await useSwapCanisterClient();
            let tokensInfoRes = await actor[methods.getAllTokensInfo]() as {
                ok: TokensInfo
            };
            let res: LaunchCardProps[] = [];
            let icp_contributed_promises = [];
            let token_canister_ids = [];
            if (tokensInfoRes.ok) {
                let tokensInfo = tokensInfoRes.ok;
                for (let i = 0; i < tokensInfo.active.length; i += 1) {
                    let current_token_info = tokensInfo.active[i];
                    if (current_token_info.token_canister_id == canisterId) {
                        token_canister_ids.push(current_token_info.token_canister_id);
                        let cardInfo: LaunchCardProps = {
                            id: current_token_info.token_canister_id,
                            project: {
                                name: current_token_info.token_project_configs.name,
                                bannerUrl: current_token_info.token_project_configs.bannerUrl,
                                description: isDescriptionPlainText(current_token_info.token_project_configs.description) ? current_token_info.token_project_configs.description.plainText : "",
                                website: current_token_info.token_project_configs.website,
                                creator: current_token_info.token_project_configs.creator,
                                creatorAbout: current_token_info.token_project_configs.creatorAbout,
                                creatorImageUrl: current_token_info.token_project_configs.creatorImageUrl
                            },
                            swap: {
                                raisedIcp: "0",
                                maxIcp: String(Number(current_token_info.token_swap_configs.max_icp_e8s) / 100000000),
                                minIcp: String(Number(current_token_info.token_swap_configs.min_icp_e8s) / 100000000),
                                minParticipantIcp: String(Number(current_token_info.token_swap_configs.min_participant_icp_e8s) / 100000000),
                                maxParticipantIcp: String(Number(current_token_info.token_swap_configs.max_participant_icp_e8s) / 100000000),
                                participants: "0",
                                endTimestamp: msToTime(Number(current_token_info.token_swap_configs.swap_start_timestamp_seconds + current_token_info.token_swap_configs.swap_due_timestamp_seconds - BigInt(Math.floor(Date.now() / 1000))) * 1000),
                                status: true,
                                result: false
                            },
                            token: {
                                name: current_token_info.token_configs.name,
                                symbol: current_token_info.token_configs.symbol,
                                logoUrl: current_token_info.token_configs.logo,
                                description: current_token_info.token_configs.description,
                            },
                        };
                        res.push(cardInfo);
                    }
                }
                for (let i = 0; i < tokensInfo.inactive.length; i += 1) {
                    let current_token_info = tokensInfo.inactive[i];
                    if (current_token_info.token_canister_id == canisterId) {
                        token_canister_ids.push(current_token_info.token_canister_id);
                        let cardInfo: LaunchCardProps = {
                            id: current_token_info.token_canister_id,
                            project: {
                                name: current_token_info.token_project_configs.name,
                                bannerUrl: current_token_info.token_project_configs.bannerUrl,
                                description: isDescriptionPlainText(current_token_info.token_project_configs.description) ? current_token_info.token_project_configs.description.plainText : "",
                                website: current_token_info.token_project_configs.website,
                                creator: current_token_info.token_project_configs.creator,
                                creatorAbout: current_token_info.token_project_configs.creatorAbout,
                                creatorImageUrl: current_token_info.token_project_configs.creatorImageUrl
                            },
                            swap: {
                                raisedIcp: "0",
                                maxIcp: String(Number(current_token_info.token_swap_configs.max_icp_e8s) / 100000000),
                                minIcp: String(Number(current_token_info.token_swap_configs.min_icp_e8s) / 100000000),
                                minParticipantIcp: String(Number(current_token_info.token_swap_configs.min_participant_icp_e8s) / 100000000),
                                maxParticipantIcp: String(Number(current_token_info.token_swap_configs.max_participant_icp_e8s) / 100000000),
                                participants: "0",
                                endTimestamp: msToTime(Number(current_token_info.token_swap_configs.swap_start_timestamp_seconds + current_token_info.token_swap_configs.swap_due_timestamp_seconds) * 1000),
                                status: false,
                                result: false
                            },
                            token: {
                                name: current_token_info.token_configs.name,
                                symbol: current_token_info.token_configs.symbol,
                                logoUrl: current_token_info.token_configs.logo,
                                description: current_token_info.token_configs.description,
                            },
                        };
                        res.push(cardInfo);
                    }
                }
            }

            for (let i = 0; i < token_canister_ids.length; i += 1) {
                icp_contributed_promises.push(actor[methods.total_icp_contributed_e8s_and_total_participants]({ canister_id: token_canister_ids[i] }) as Promise<[BigInt, BigInt]>)
            }
            await Promise.all(icp_contributed_promises).then((results => {
                for (let i = 0; i < res.length; i += 1) {
                    res[i].swap.raisedIcp = String(Number(results[i][0]) / 100000000);
                    res[i].swap.participants = String(results[i][1])
                }
            }));
            return res;
        },
    });
};

export const useGetAllTokensInfo = (): UseQueryResult<Array<LaunchCardProps>> => {
    const { session } = useAuthContext();
    const { canisterId } = useParams();
    return useQuery({
        queryKey: [queryKeys.tokens_info, canisterId],
        queryFn: async () => {
            const { actor, methods } = await useSwapCanisterClient();
            let tokensInfoRes = await actor[methods.getAllTokensInfo]() as {
                ok: TokensInfo
            };
            let res: LaunchCardProps[] = [];
            let icp_contributed_promises = [];
            let token_canister_ids = [];
            if (tokensInfoRes.ok) {
                let tokensInfo = tokensInfoRes.ok;
                for (let i = 0; i < tokensInfo.active.length; i += 1) {
                    let current_token_info = tokensInfo.active[i];
                    token_canister_ids.push(current_token_info.token_canister_id);
                    let cardInfo: LaunchCardProps = {
                        id: current_token_info.token_canister_id,
                        project: {
                            name: current_token_info.token_project_configs.name,
                            bannerUrl: current_token_info.token_project_configs.bannerUrl,
                            description: isDescriptionPlainText(current_token_info.token_project_configs.description) ? current_token_info.token_project_configs.description.plainText : "",
                            website: current_token_info.token_project_configs.website,
                            creator: current_token_info.token_project_configs.creator,
                            creatorAbout: current_token_info.token_project_configs.creatorAbout,
                            creatorImageUrl: current_token_info.token_project_configs.creatorImageUrl
                        },
                        swap: {
                            raisedIcp: "0",
                            maxIcp: String(Number(current_token_info.token_swap_configs.max_icp_e8s) / 100000000),
                            minIcp: String(Number(current_token_info.token_swap_configs.min_icp_e8s) / 100000000),
                            minParticipantIcp: String(Number(current_token_info.token_swap_configs.min_participant_icp_e8s) / 100000000),
                            maxParticipantIcp: String(Number(current_token_info.token_swap_configs.max_participant_icp_e8s) / 100000000),
                            participants: "0",
                            endTimestamp: msToTime(Number(current_token_info.token_swap_configs.swap_start_timestamp_seconds + current_token_info.token_swap_configs.swap_due_timestamp_seconds - BigInt(Math.floor(Date.now() / 1000))) * 1000),
                            status: true,
                            result: false
                        },
                        token: {
                            name: current_token_info.token_configs.name,
                            symbol: current_token_info.token_configs.symbol,
                            logoUrl: current_token_info.token_configs.logo,
                            description: current_token_info.token_configs.description,
                        },
                    };
                    res.push(cardInfo);
                }
                for (let i = 0; i < tokensInfo.inactive.length; i += 1) {
                    let current_token_info = tokensInfo.inactive[i];
                    token_canister_ids.push(current_token_info.token_canister_id);
                    let cardInfo: LaunchCardProps = {
                        id: current_token_info.token_canister_id,
                        project: {
                            name: current_token_info.token_project_configs.name,
                            bannerUrl: current_token_info.token_project_configs.bannerUrl,
                            description: isDescriptionPlainText(current_token_info.token_project_configs.description) ? current_token_info.token_project_configs.description.plainText : "",
                            website: current_token_info.token_project_configs.website,
                            creator: current_token_info.token_project_configs.creator,
                            creatorAbout: current_token_info.token_project_configs.creatorAbout,
                            creatorImageUrl: current_token_info.token_project_configs.creatorImageUrl
                        },
                        swap: {
                            raisedIcp: "0",
                            maxIcp: String(Number(current_token_info.token_swap_configs.max_icp_e8s) / 100000000),
                            minIcp: String(Number(current_token_info.token_swap_configs.min_icp_e8s) / 100000000),
                            minParticipantIcp: String(Number(current_token_info.token_swap_configs.min_participant_icp_e8s) / 100000000),
                            maxParticipantIcp: String(Number(current_token_info.token_swap_configs.max_participant_icp_e8s) / 100000000),
                            participants: "0",
                            endTimestamp: msToTime(Number(current_token_info.token_swap_configs.swap_start_timestamp_seconds + current_token_info.token_swap_configs.swap_due_timestamp_seconds) * 1000),
                            status: false,
                            result: false
                        },
                        token: {
                            name: current_token_info.token_configs.name,
                            symbol: current_token_info.token_configs.symbol,
                            logoUrl: current_token_info.token_configs.logo,
                            description: current_token_info.token_configs.description,
                        },
                    };
                    res.push(cardInfo);
                }
            }

            for (let i = 0; i < token_canister_ids.length; i += 1) {
                icp_contributed_promises.push(actor[methods.total_icp_contributed_e8s_and_total_participants]({ canister_id: token_canister_ids[i] }) as Promise<[BigInt, BigInt]>)
            }
            await Promise.all(icp_contributed_promises).then((results => {
                for (let i = 0; i < res.length; i += 1) {
                    res[i].swap.raisedIcp = String(Number(results[i][0]) / 100000000);
                    res[i].swap.participants = String(results[i][1]);
                    if(Number(res[i].swap.minIcp) <= Number(res[i].swap.raisedIcp)) {
                        res[i].swap.result = true;
                    }
                }
            }));
            return res;
        },
    });
};

export const useGetParticipationDetails = (canisterId?: string): UseQueryResult<String> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.participant_details, canisterId],
        queryFn: async () => {
            const { actor, methods } = await useSwapCanisterClient();
            let details = await actor[methods.getParticipationDetails]({
                tokenCanisterId: canisterId ? canisterId : "",
                participantId: (session) ? session.address : "2vxsx-fae"
            }) as {
                ok: ParticipantDetails
            };
            if (details.ok == undefined) {
                return "0";
            } else {
                let amt = Number(details.ok.icp_e8s * 100000000n / 100000000n) / 100000000;
                return String(amt);
            }
        },
    });
};

export const useParticipateICPTransfer = () => {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: async ({
            amount,
            canisterId,
        }: {
            amount: string;
            canisterId?: string;
        }) => {
            try {
                const { actor, methods } = await useICRCLedgerClient(ledger_canisterId);
                const swapCanister = await useSwapCanisterClient();
                let fee = 0;
                for (let i = 0; i < Tokens.tokens.length; i += 1) {
                    if (Tokens.tokens[i].ledger == ledger_canisterId) {
                        fee = Tokens.tokens[i].fee
                    }
                };
                let amount_e8s: number = parseFloat(amount);
                amount_e8s = amount_e8s * 100000000.0;
                let req = {
                    to: {
                        owner: Principal.fromText(swapCanisterId),
                        subaccount: [],
                    },
                    fee: [fee],
                    memo: [],
                    from_subaccount: [],
                    created_at_time: [],
                    amount: amount_e8s,
                };
                let res = await actor[methods.icrc1_transfer](req) as {
                    Ok: number | undefined, Err: {
                        InsufficientFunds: {} | undefined
                    } | undefined
                };
                if (res.Ok == undefined) {
                    if (res.Err?.InsufficientFunds == undefined) {
                        toast.error("ICRC1 Transfer error. Contact dev team in discord.");
                        closeToast();
                    } else {
                        toast.error("Insufficient funds. Use amount available to withdraw.");
                        closeToast();
                    }
                    throw (res.Err);
                } else {
                    let res2 = await swapCanister.actor[swapCanister.methods.participate_in_token_swap]({
                        canister_id: (canisterId != undefined) ? canisterId : "",
                        amount: {
                            e8s: amount_e8s
                        },
                        blockIndex: res.Ok
                    });
                }
                return res;
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
        },
        onSuccess: () => {
            toast.success("Participated successfully");
            closeToast();
        },
    });
};