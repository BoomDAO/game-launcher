import { toast } from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import {
    UseQueryResult,
    useMutation,
    useQuery,
    useQueryClient,
} from "@tanstack/react-query";
import { gamingGuildsCanisterId, useBoomLedgerClient, useGamingGuildsClient, useGamingGuildsWorldNodeClient, useGuildsVerifierClient, useICRCLedgerClient, useWorldHubClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import { useAuthContext } from "@/context/authContext";
import { GuildConfig, GuildCard, StableEntity, Field, Action, Member, MembersInfo, ActionReturn, VerifiedStatus, Profile, UserTokenInfo, UserProfile } from "@/types";
import DialogProvider from "@/components/DialogProvider";
import Button from "@/components/ui/Button";
import Tokens from "../locale/en/Tokens.json";

export const queryKeys = {
    profile: "profile",
    wallet: "wallet"

};

export const useGetUserProfileDetail = (): UseQueryResult<UserProfile> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.profile],
        queryFn: async () => {
            let current_user_principal = ((session?.identity?.getPrincipal())?.toString() != undefined) ? (session?.identity?.getPrincipal())?.toString() : "" ;
            let response: UserProfile = {
                uid: current_user_principal ? current_user_principal : "",
                username: current_user_principal ? (current_user_principal).substring(0, 10) + "..." : "",
                xp: "0",
                image: "/usericon.jpeg"
            };
            const { actor, methods } = await useGamingGuildsWorldNodeClient();
            const worldHub = await useWorldHubClient();
            let XPEntity = await actor[methods.getSpecificUserEntities](current_user_principal, gamingGuildsCanisterId, ["xp"]) as { ok: [StableEntity]; err: string | undefined; };
            if (XPEntity.err == undefined) {
                let fields = XPEntity.ok[0].fields;
                for (let i = 0; i < fields.length; i += 1) {
                    if (fields[i].fieldName == "quantity") {
                        response.xp = (((fields[i].fieldValue).split("."))[0]).toString();
                    }
                };
                let profile = await worldHub.actor[worldHub.methods.getUserProfile]({ uid: current_user_principal }) as { uid: string; username: string; image: string; };
                response = {
                    uid: profile.uid,
                    username: (profile.username == profile.uid) ? (profile.uid).substring(0, 10) + "..." : (profile.username.length > 10) ? (profile.username).substring(0, 10) + "..." : profile.username,
                    xp: response.xp,
                    image: (profile.image != "") ? profile.image : "/usericon.jpeg"
                };
            } else {
                // TODO:
                // let entities = await actor[methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as { ok: [StableEntity] };
                // let userIsMember = false;
                // for (let i = 0; i < entities.ok.length; i += 1) {
                //     if (entities.ok[i].eid == current_user_principal) {
                //         userIsMember = true;
                //     }
                // };
                // if (!userIsMember) {
                //     let guildCanister = await useGamingGuildsClient();
                //     let res = await guildCanister.actor[guildCanister.methods.processAction]({
                //         fields: [],
                //         actionId: "create_profile"
                //     });
                //     console.log(res);
                // }
            }
            return response;
        },
    });
};

export const getTokenSymbol = (canisterId?: string) => {
    for (let i = 0; i < Tokens.tokens.length; i += 1) {
        if (Tokens.tokens[i].ledger == canisterId) {
            return Tokens.tokens[i].symbol;
        };
    };
    return "";
};


export const useGetWalletInfo = (): UseQueryResult<Profile> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.wallet],
        queryFn: async () => {
            const { actor, methods } = await useWorldHubClient();
            let res: Profile = {
                principal: (session!.address) ? (session!.address) : "",
                username: "",
                image: "",
                tokens: []
            };
            let user_token_balances = [];
            for (let i = 0; i < Tokens.tokens.length; i += 1) {
                const icrc_ledger = await useICRCLedgerClient(Tokens.tokens[i].ledger);
                user_token_balances.push(icrc_ledger.actor[icrc_ledger.methods.icrc1_balance_of]({
                    owner: Principal.fromText(res.principal),
                    subaccount: [],
                }));
            };
            await Promise.all(user_token_balances).then(
                (res2: any) => {
                    for (let k = 0; k < res2.length; k++) {
                        let b = ((Number(res2[k]) * 1.0) / Math.pow(10, Tokens.tokens[k].decimals)).toFixed(Tokens.tokens[k].decimals);
                        res.tokens.push({
                            name: Tokens.tokens[k].name,
                            logo: Tokens.tokens[k].logo,
                            balance: String(b),
                            symbol: Tokens.tokens[k].symbol,
                            fee: Tokens.tokens[k].fee,
                            decimals: Tokens.tokens[k].decimals,
                            ledger: Tokens.tokens[k].ledger
                        });
                    };
                    return res2;
                }
            ).then(
                response => {
                    user_token_balances = response;
                }
            );
            return res;
        },
    });
};

export const useIcrcTransfer = () => {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: async ({
            principal,
            amount,
            canisterId,
        }: {
            principal: string;
            amount: string;
            canisterId?: string;
        }) => {
            try {
                const { actor, methods } = await useICRCLedgerClient((canisterId != undefined) ? canisterId : "");
                let fee = 0;
                for (let i = 0; i < Tokens.tokens.length; i += 1) {
                    if (Tokens.tokens[i].ledger == canisterId) {
                        fee = Tokens.tokens[i].fee
                    }
                };
                let amount_e8s: number = parseFloat(amount);
                amount_e8s = amount_e8s * 100000000.0;
                let req = {
                    to: {
                        owner: Principal.fromText(principal),
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
                    } else {
                        toast.error("Insufficient funds. Use amount available to withdraw.");
                    }
                    throw (res.Err);
                };
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
            toast.success(t("wallet.transfer.success"));
            queryClient.refetchQueries({ queryKey: [queryKeys.wallet] });
        },
    });
};

export const useUpdateProfileImage = () => {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    const { session } = useAuthContext();
    return useMutation({
        mutationFn: async ({
            image
        }: {
            image: string
        }) => {
            try {
                const { actor, methods } = await useWorldHubClient();
                let current_user_principal = session?.address;
                let res = await actor[methods.uploadProfilePicture]({ uid: current_user_principal, image: image });
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            toast.error(t("profile.edit.tab_1.error"));
        },
        onSuccess: () => {
            toast.success(t("profile.edit.tab_1.success"));
            window.setTimeout(() => {
                console.log("jiweoikhfk");
                queryClient.refetchQueries({ queryKey: [queryKeys.profile] });
            }, 5000);
        },
    });
};

export const useUpdateProfileUsername = () => {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    const { session } = useAuthContext();
    let isErrorServed = false;
    return useMutation({
        mutationFn: async ({
            username
        }: {
            username: string
        }) => {
            try {
                const { actor, methods } = await useWorldHubClient();
                let current_user_principal = session?.address;
                let res = await actor[methods.setUsername](current_user_principal, username) as { ok: string | undefined, err: string | undefined };
                console.log(res);
                if (res.ok == undefined) {
                    toast.error("Username not available, try different username.");
                    isErrorServed = true;
                    throw (res.err);
                };
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            if (!isErrorServed) {
                toast.error(t("profile.edit.tab_2.error"));
            }
        },
        onSuccess: () => {
            toast.success(t("profile.edit.tab_2.success"));
            window.setTimeout(() => {
                console.log("jiweoikhfk");
                queryClient.refetchQueries({ queryKey: [queryKeys.profile] });
            }, 5000);
        },
    });
};
