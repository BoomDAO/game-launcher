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
import { boom_ledger_canisterId, gamingGuildsCanisterId, ledger_canisterId, swapCanisterId, useBoomLedgerClient, useGamingGuildsClient, useICRCLedgerClient, useLedgerClient, useSwapCanisterClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import { useAuthContext } from "@/context/authContext";
import { LaunchCardProps, ParticipantDetails, TokenSwapType, TokensInfo, WhitelistDetails } from "@/types";
import DialogProvider from "@/components/DialogProvider";
import Button from "@/components/ui/Button";
import { string } from "zod";
import { AccountIdentifier } from "@dfinity/ledger-icp";
import Tokens from "../locale/en/Tokens.json";

export const queryKeys = {
    tokens_info: "tokens_info",
    participant_details: "participant_details",
    swap_type: "swap_type",
    whitelist_details: "whitelist_details",
    participation_eligibility: "participation_eligibility"
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
        days: (days != "") ? days : "00",
        hrs: (hours != 0) ? String(hours) : "00",
        mins: (minutes != 0) ? String(minutes) : "00"
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
            let token_contributed_promises = [];
            let token_canister_ids_and_swap_type = [];
            if (tokensInfoRes.ok) {
                let tokensInfo = tokensInfoRes.ok;
                for (let i = 0; i < tokensInfo.active.length; i += 1) {
                    let current_token_info = tokensInfo.active[i];
                    if (current_token_info.token_canister_id == canisterId) {
                        token_canister_ids_and_swap_type.push([current_token_info.token_canister_id, isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP"]);
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
                                swapType: isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP",
                                raisedToken: "0",
                                maxToken: String(Number(current_token_info.token_swap_configs.max_token_e8s) / 100000000),
                                minToken: String(Number(current_token_info.token_swap_configs.min_token_e8s) / 100000000),
                                minParticipantToken: String(Number(current_token_info.token_swap_configs.min_participant_token_e8s) / 100000000),
                                maxParticipantToken: String(Number(current_token_info.token_swap_configs.max_participant_token_e8s) / 100000000),
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
                        token_canister_ids_and_swap_type.push([current_token_info.token_canister_id, isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP"]);
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
                                swapType: isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP",
                                raisedToken: "0",
                                maxToken: String(Number(current_token_info.token_swap_configs.max_token_e8s) / 100000000),
                                minToken: String(Number(current_token_info.token_swap_configs.min_token_e8s) / 100000000),
                                minParticipantToken: String(Number(current_token_info.token_swap_configs.min_participant_token_e8s) / 100000000),
                                maxParticipantToken: String(Number(current_token_info.token_swap_configs.max_participant_token_e8s) / 100000000),
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

            for (let i = 0; i < token_canister_ids_and_swap_type.length; i += 1) {
                let tokenType: TokenSwapType = { 'icp': null };
                if (token_canister_ids_and_swap_type[i][1] == "BOOM") {
                    tokenType = { 'boom': null };
                }
                token_contributed_promises.push(actor[methods.total_token_contributed_e8s_and_total_participants]({ canister_id: token_canister_ids_and_swap_type[i][0], token: tokenType }) as Promise<[BigInt, BigInt]>)
            }
            await Promise.all(token_contributed_promises).then((results => {
                for (let i = 0; i < res.length; i += 1) {
                    res[i].swap.raisedToken = String(Number(results[i][0]) / 100000000);
                    res[i].swap.participants = String(results[i][1])
                    if (Number(res[i].swap.minToken) <= Number(res[i].swap.raisedToken)) {
                        res[i].swap.result = true;
                    }
                }
            }));
            return res;
        },
    });
};

function isTokenSwapTypeBOOM(data: { 'icp': null } | { 'boom': null }): data is { 'boom': null } {
    return ((data as { 'boom': null }) !== undefined);
}
function isTokenSwapTypeICP(data: { 'icp': null } | { 'boom': null }): data is { 'icp': null } {
    return ((data as { 'icp': null }) !== undefined);
}

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
            let token_contributed_promises = [];
            let token_canister_ids_and_swap_type = [];
            if (tokensInfoRes.ok) {
                let tokensInfo = tokensInfoRes.ok;
                for (let i = 0; i < tokensInfo.active.length; i += 1) {
                    let current_token_info = tokensInfo.active[i];
                    token_canister_ids_and_swap_type.push([current_token_info.token_canister_id, isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP"]);
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
                            swapType: isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP",
                            raisedToken: "0",
                            maxToken: String(Number(current_token_info.token_swap_configs.max_token_e8s) / 100000000),
                            minToken: String(Number(current_token_info.token_swap_configs.min_token_e8s) / 100000000),
                            minParticipantToken: String(Number(current_token_info.token_swap_configs.min_participant_token_e8s) / 100000000),
                            maxParticipantToken: String(Number(current_token_info.token_swap_configs.max_participant_token_e8s) / 100000000),
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
                    token_canister_ids_and_swap_type.push([current_token_info.token_canister_id, isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP"]);
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
                            swapType: isTokenSwapTypeBOOM(current_token_info.token_swap_configs.swap_type) ? "BOOM" : "ICP",
                            raisedToken: "0",
                            maxToken: String(Number(current_token_info.token_swap_configs.max_token_e8s) / 100000000),
                            minToken: String(Number(current_token_info.token_swap_configs.min_token_e8s) / 100000000),
                            minParticipantToken: String(Number(current_token_info.token_swap_configs.min_participant_token_e8s) / 100000000),
                            maxParticipantToken: String(Number(current_token_info.token_swap_configs.max_participant_token_e8s) / 100000000),
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
            for (let i = 0; i < token_canister_ids_and_swap_type.length; i += 1) {
                let tokenType: TokenSwapType = { 'icp': null };
                if (token_canister_ids_and_swap_type[i][1] == "BOOM") {
                    tokenType = { 'boom': null };
                }
                token_contributed_promises.push(actor[methods.total_token_contributed_e8s_and_total_participants]({ canister_id: token_canister_ids_and_swap_type[i][0], token: tokenType }) as Promise<[BigInt, BigInt]>)
            }
            await Promise.all(token_contributed_promises).then((results => {
                for (let i = 0; i < res.length; i += 1) {
                    res[i].swap.raisedToken = String(Number(results[i][0]) / 100000000);
                    res[i].swap.participants = String(results[i][1]);
                    if (Number(res[i].swap.minToken) <= Number(res[i].swap.raisedToken)) {
                        res[i].swap.result = true;
                    }
                }
            }));
            return res;
        },
    });
};

export const useGetParticipationDetails = (canisterId: string): UseQueryResult<[String, String]> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.participant_details, canisterId],
        queryFn: async () => {
            const { actor, methods } = await useSwapCanisterClient();
            let finalRes = ["", ""];
            await Promise.all([actor[methods.getParticipationDetails]({ tokenCanisterId: canisterId, participantId: (session) ? session.address : "2vxsx-fae" }) as Promise<{ ok: ParticipantDetails }>,
            actor[methods.getTokenSwapType](canisterId) as Promise<string>]).then((res) => {
                let details = res[0] as { ok: ParticipantDetails | undefined, err: undefined | string };
                let swapType = res[1];
                finalRes[1] = (swapType == "BOOM") ? "boom" : "icp";
                if (details.ok == undefined) {
                    finalRes[0] = "0";
                } else {
                    if (swapType == "ICP") {
                        let amt = Number(details.ok.icp_e8s * 100000000n / 100000000n) / 100000000;
                        finalRes[0] = String(amt);
                    } else {
                        let amt = Number(details.ok.boom_e8s * 100000000n / 100000000n) / 100000000;
                        finalRes[0] = String(amt);
                    }
                }
            })
            return finalRes;
        },
    });
};

export const useParticipateTokenTransfer = (swapType: string) => {
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
                let token_ledger_canister_id = (swapType == "boom") ? boom_ledger_canisterId : ledger_canisterId;
                const { actor, methods } = await useICRCLedgerClient(token_ledger_canister_id);
                const swapCanister = await useSwapCanisterClient();
                let tokensInfoRes = await swapCanister.actor[swapCanister.methods.getAllTokensInfo]() as {
                    ok: TokensInfo
                };
                let fee = 0;
                for (let i = 0; i < Tokens.tokens.length; i += 1) {
                    if (Tokens.tokens[i].ledger == token_ledger_canister_id) {
                        fee = Tokens.tokens[i].fee
                    }
                };
                let amount_e8s: number = parseFloat(amount);
                amount_e8s = amount_e8s * 100000000.0;

                // Check amount constraint before transfer
                if (tokensInfoRes.ok) {
                    let tokensInfo = tokensInfoRes.ok;
                    for (let i = 0; i < tokensInfo.active.length; i += 1) {
                        let current_token_info = tokensInfo.active[i];
                        if(amount_e8s < current_token_info.token_swap_configs.min_participant_token_e8s || amount_e8s > current_token_info.token_swap_configs.max_participant_token_e8s) {
                            toast.error("Please check minimum and maximum participation limits per user before participating.");
                            closeToast();
                            throw ("");
                        }
                    }
                }

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
                        amount: amount_e8s,
                        blockIndex: res.Ok
                    }) as {
                        ok: undefined | string,
                        err: undefined | string
                    };
                    if (res2.ok == undefined) {
                        toast.error(res2.err || "Participation failed, contact dev team in discord.");
                        closeToast();
                        throw res2.err;
                    };
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
            toast.success("Participated successfully, your tokens will be allocated once the sale ends.");
            queryClient.refetchQueries({ queryKey: [queryKeys.participant_details] });
            queryClient.refetchQueries({ queryKey: [queryKeys.tokens_info] });
            closeToast();
        },
    });
};

export const useGetWhitelistDetails = (): UseQueryResult<WhitelistDetails> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.whitelist_details],
        queryFn: async () => {
            const { actor, methods } = await useSwapCanisterClient();
            let tokensInfoRes = await actor[methods.getAllTokensInfo]() as {
                ok: TokensInfo
            };
            var res: WhitelistDetails = { elite: false, pro: false, public: false };
            if (tokensInfoRes.ok) {
                let tokensInfo = tokensInfoRes.ok;
                for (let i = 0; i < tokensInfo.active.length; i += 1) {
                    let current_token_info = tokensInfo.active[i];
                    let swap_time_seconds = current_token_info.token_swap_configs.swap_start_timestamp_seconds;
                    let current_time_seconds = BigInt(Math.floor(Date.now() / 1000));
                    console.log(current_time_seconds);
                    console.log(swap_time_seconds);
                    if (current_time_seconds >= swap_time_seconds) {
                        res = {
                            elite: true,
                            pro: true,
                            public: true
                        }
                    } else if (current_time_seconds + 10800n >= swap_time_seconds) {
                        res = {
                            elite: true,
                            pro: true,
                            public: false
                        }
                    } else if (current_time_seconds + 21600n >= swap_time_seconds) {
                        res = {
                            elite: true,
                            pro: false,
                            public: false
                        }
                    }
                }
            };
            console.log(res);
            return res;
        },
    });
};

export const useGetParticipationEligibility = (): UseQueryResult<boolean> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.participation_eligibility],
        queryFn: async () => {
            const { actor, methods } = await useSwapCanisterClient();
            const gamingGuild = await useGamingGuildsClient();
            let tokensInfoRes: { ok: TokensInfo } = {
                ok: {
                    active: [],
                    inactive: []
                }
            };
            let userStakeTier: string = "";
            await Promise.all([actor[methods.getAllTokensInfo]() as Promise<{ ok: TokensInfo }>, gamingGuild.actor[gamingGuild.methods.getUserBoomStakeTier](session?.address) as Promise<{ ok: string | undefined, err: string | undefined }>]).then((res) => {
                tokensInfoRes = res[0];
                if (res[1].ok != undefined) {
                    userStakeTier = res[1].ok;
                } else {
                    userStakeTier = "PUBLIC";
                }
            });
            var res: WhitelistDetails = { elite: false, pro: false, public: false };
            if (tokensInfoRes?.ok) {
                let tokensInfo = tokensInfoRes?.ok;
                for (let i = 0; i < tokensInfo.active.length; i += 1) {
                    let current_token_info = tokensInfo.active[i];
                    let swap_time_seconds = current_token_info.token_swap_configs.swap_start_timestamp_seconds;
                    let current_time_seconds = BigInt(Math.floor(Date.now() / 1000));
                    console.log(current_time_seconds);
                    console.log(swap_time_seconds);
                    if (current_time_seconds >= swap_time_seconds) {
                        res = {
                            elite: true,
                            pro: true,
                            public: true
                        }
                    } else if (current_time_seconds + 10800n >= swap_time_seconds) {
                        res = {
                            elite: true,
                            pro: true,
                            public: false
                        }
                    } else if (current_time_seconds + 21600n >= swap_time_seconds) {
                        res = {
                            elite: true,
                            pro: false,
                            public: false
                        }
                    }
                }
            };
            let finalRes = false;
            if (userStakeTier == "ELITE" && res.elite) {
                finalRes = true;
            } else if (userStakeTier == "PRO" && res.pro) {
                finalRes = true
            } else if (userStakeTier == "PUBLIC" && res.public) {
                finalRes = true;
            }
            console.log(userStakeTier);
            console.log(res);
            return finalRes;
        },
    });
};