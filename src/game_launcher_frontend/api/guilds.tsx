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
import { gamingGuildsCanisterId, useBoomLedgerClient, useExtClient, useGamingGuildsClient, useGamingGuildsWorldNodeClient, useGuildsVerifierClient, useWorldHubClient } from "@/hooks";
import { navPaths, serverErrorMsg } from "@/shared";
import { useAuthContext } from "@/context/authContext";
import { GuildConfig, GuildCard, StableEntity, Field, Action, Member, MembersInfo, ActionReturn, VerifiedStatus, UserProfile, UpdateEntity, TransferIcrc, MintNft, SetNumber, IncrementNumber, DecrementNumber, NftTransfer } from "@/types";
import DialogProvider from "@/components/DialogProvider";
import Button from "@/components/ui/Button";
import { AccountIdentifier } from "@dfinity/ledger-icp";

export const queryKeys = {
    all_guild_members_info: "all_guild_members_info",
    boom_token_balance: "boom_token_balance",
    all_quests_info: "all_quests_info",
    verified_status: "verified_status",
    profile: "profile"
};

const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

export const useGetBoomBalance = (): UseQueryResult<string> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.boom_token_balance],
        queryFn: async () => {
            const { actor, methods } = await useBoomLedgerClient();
            let balance = await actor[methods.icrc1_balance_of]({
                owner: Principal.fromText(gamingGuildsCanisterId),
                subaccount: [],
            }) as bigint;
            balance = BigInt(balance) / BigInt(100000000);
            return balance.toString();
        },
    });
};

export const useSubmitEmail = () => {
    const { t } = useTranslation();
    return useMutation({
        mutationFn: async ({
            email,
        }: {
            email: string;
        }) => {
            try {
                const { actor, methods } = await useGuildsVerifierClient();
                let result = await actor[methods.sendVerificationEmail](email) as {
                    ok: string | undefined;
                    err: string | undefined;
                };
                if (result.ok == undefined) {
                    throw (result.err);
                }
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            toast.error(t("verification.verification_error"));
        },
        onSuccess: () => {
            toast.success(t("verification.verification_success"));
        },
    });
};

export const useSubmitPhone = () => {
    const { t } = useTranslation();
    return useMutation({
        mutationFn: async ({
            phone,
        }: {
            phone: string;
        }) => {
            try {
                const { actor, methods } = await useGuildsVerifierClient();
                let result = await actor[methods.sendVerificationSMS](phone) as {
                    ok: string | undefined;
                    err: string | undefined;
                };
                if (result.ok == undefined) {
                    throw (result.err);
                }
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            toast.error(t("verification.verification_error_phone"));
        },
        onSuccess: () => {
            toast.success(t("verification.verification_success_phone"));
        },
    });
};

export const useVerifyEmail = () => {
    const queryClient = useQueryClient();
    const { t } = useTranslation();
    return useMutation({
        mutationFn: async ({
            email,
            otp,
        }: {
            email: string;
            otp: string;
        }) => {
            try {
                const { actor, methods } = await useGuildsVerifierClient();
                let result = await actor[methods.verifyOTP]({ email: email, otp: otp }) as {
                    ok: string | undefined;
                    err: string | undefined;
                };
                if (result.ok == undefined) {
                    throw (result.err);
                }
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            toast.error(t("verification.otp_error"));
        },
        onSuccess: () => {
            toast.success(t("verification.otp_success"));
            window.setTimeout(() => {
                queryClient.refetchQueries({ queryKey: [queryKeys.verified_status] });
            }, 15000);
        }
    });
};

export const useVerifyPhone = () => {
    const queryClient = useQueryClient();
    const { t } = useTranslation();
    return useMutation({
        mutationFn: async ({
            phone,
            otp,
        }: {
            phone: string;
            otp: string;
        }) => {
            try {
                const { actor, methods } = await useGuildsVerifierClient();
                let result = await actor[methods.verifySmsOTP]({ phone: phone, otp: otp }) as {
                    ok: string | undefined;
                    err: string | undefined;
                };
                if (result.ok == undefined) {
                    throw (result.err);
                }
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            toast.error(t("verification.otp_error"));
        },
        onSuccess: () => {
            toast.success(t("verification.otp_success"));
            window.setTimeout(() => {
                queryClient.refetchQueries({ queryKey: [queryKeys.verified_status] });
            }, 15000);
        }
    });
};

const getUserInfo = (fields: Field[]) => {
    let res = {
        guilds: "",
        joinDate: "",
    };
    for (let j = 0; j < fields.length; j += 1) {
        if (fields[j].fieldName == "xp") {
            res.guilds = fields[j].fieldValue;
        };
        if (fields[j].fieldName == "joinDate") {
            res.joinDate = fields[j].fieldValue;
        };
    };
    return res;
};

export const useGetAllMembersInfo = (): UseQueryResult<MembersInfo> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.all_guild_members_info],
        queryFn: async () => {
            let response: MembersInfo = {
                totalMembers: "",
                members: [],
            };
            const { actor, methods } = await useGamingGuildsWorldNodeClient();
            const worldHub = await useWorldHubClient();
            // fetching totalMembers
            let totalMembersEntity = await actor[methods.getSpecificUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, ["totalMembers"]) as { ok: [StableEntity]; };
            let entities = await actor[methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as { ok: [StableEntity] };

            let fields = totalMembersEntity.ok[0].fields;
            for (let i = 0; i < fields.length; i += 1) {
                if (fields[i].fieldName == "quantity") {
                    response.totalMembers = (((fields[i].fieldValue).split("."))[0]).toString();
                }
            };
            let members_info: Member[] = [];
            // processing members info
            let current_user_principal = (session?.identity?.getPrincipal())?.toString();
            for (let i = 0; i < entities.ok.length; i += 1) {
                fields = entities.ok[i].fields;
                let memberInfo = getUserInfo(fields);
                let current_member: Member = {
                    uid: "",
                    image: "/usericon.jpeg",
                    username: "",
                    guilds: "0",
                    joinDate: ""
                };
                if (entities.ok[i].eid.length >= 63) {
                    current_member.username = (entities.ok[i].eid).substring(0, 20) + ".....";
                    current_member.uid = entities.ok[i].eid;
                    let reg_time: number = Number(memberInfo.joinDate) / (1000000);
                    let date = new Date(reg_time);
                    current_member.joinDate = months[(date.getMonth())] + ' ' + date.getFullYear();
                    current_member.guilds = (memberInfo.guilds).split(".")[0];
                    members_info.push(current_member);
                };
            };

            let users_profile = [];
            for (let i = 0; i < members_info.length; i += 1) {
                users_profile.push(worldHub.actor[worldHub.methods.getUserProfile]({ uid: members_info[i].uid }));
            };
            await Promise.all(users_profile).then(
                (res2: any) => {
                    for (let k = 0; k < res2.length; k++) {
                        if (res2[k].image != "") {
                            members_info[k].image = res2[k].image;
                        };
                        if (res2[k].username != members_info[k].uid) {
                            members_info[k].username = res2[k].username;
                            if (members_info[k].username.length > 20) {
                                members_info[k].username = members_info[k].username.substring(0, 20) + "...";
                            }
                        };
                    };
                    return res2;
                }
            ).then(
                response => {
                    users_profile = response;
                }
            );
            response.members = members_info;
            return response;
        },
    });
};

const msToTime = (ms: number) => {
    let seconds = Math.floor(ms / 1000);
    let minutes = Math.floor(seconds / 60);
    let hours = Math.floor(minutes / 60);
    seconds = seconds % 60;
    minutes = minutes % 60;
    let days = (hours / 24).toString().split(".")[0];
    hours = hours % 24;
    return days + "D " + hours + "H " + minutes + "M ";
}

const getFieldsOfConfig = (configs: GuildConfig[], config: string) => {
    let res = {
        name: "",
        imageUrl: "",
        gameUrl: "",
        description: ""
    };
    for (let i = 0; i < configs.length; i += 1) {
        if (configs[i].cid == config) {
            for (let j = 0; j < configs[i].fields.length; j += 1) {
                if (configs[i].fields[j].fieldName == "name") {
                    res.name = (configs[i].fields[j].fieldValue).toUpperCase();
                };
                if (configs[i].fields[j].fieldName == "imageUrl") {
                    res.imageUrl = configs[i].fields[j].fieldValue;
                };
                if (configs[i].fields[j].fieldName == "gameUrl") {
                    res.gameUrl = configs[i].fields[j].fieldValue;
                };
                if (configs[i].fields[j].fieldName == "description") {
                    res.description = configs[i].fields[j].fieldValue;
                };
            };
        };
    };
    return res;
};

const getTotalCompletionOfQuest = (fields: Field[], quest: string) => {
    for (let i = 0; i < fields.length; i += 1) {
        if (fields[i].fieldName == quest) {
            return ((fields[i].fieldValue).split("."))[0];
        };
    };
    return "0";
};

export const useGetUserProfileDetail = (): UseQueryResult<UserProfile> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.profile],
        queryFn: async () => {
            let current_user_principal = ((session?.identity?.getPrincipal())?.toString() != undefined) ? (session?.identity?.getPrincipal())?.toString() : "";
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
            } else {
                let entities = await actor[methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as { ok: [StableEntity] };
                let userIsMember = false;
                for (let i = 0; i < entities.ok.length; i += 1) {
                    if (entities.ok[i].eid == current_user_principal) {
                        userIsMember = true;
                    }
                };
                if (!userIsMember) {
                    let guildCanister = await useGamingGuildsClient();
                    let res = await guildCanister.actor[guildCanister.methods.processAction]({
                        fields: [],
                        actionId: "create_profile"
                    });
                }
            };
            let profile = await worldHub.actor[worldHub.methods.getUserProfile]({ uid: current_user_principal }) as { uid: string; username: string; image: string; };
            response = {
                uid: profile.uid,
                username: (profile.username == profile.uid) ? (profile.uid).substring(0, 10) + "..." : (profile.username.length > 10) ? (profile.username).substring(0, 10) + "..." : profile.username,
                xp: response.xp,
                image: (profile.image != "") ? profile.image : "/usericon.jpeg"
            };
            return response;
        },
    });
};

function isTransferIcrc(data: { updateEntity: UpdateEntity; } | { transferIcrc: TransferIcrc; } | { mintNft: MintNft; }): data is { transferIcrc: TransferIcrc; } {
    return (data as { transferIcrc: TransferIcrc; }).transferIcrc !== undefined;
}
function isUpdateEntity(data: { updateEntity: UpdateEntity; } | { transferIcrc: TransferIcrc; } | { mintNft: MintNft; }): data is { updateEntity: UpdateEntity; } {
    return (data as { updateEntity: UpdateEntity; }).updateEntity !== undefined;
}
function isMintNft(data: { updateEntity: UpdateEntity; } | { transferIcrc: TransferIcrc; } | { mintNft: MintNft; }): data is { mintNft: MintNft; } {
    return (data as { mintNft: MintNft; }).mintNft !== undefined;
}
function isIncreamentNumber(data: { 'setNumber': SetNumber } | { 'incrementNumber': IncrementNumber } | { 'decrementNumber': DecrementNumber }): data is { 'incrementNumber': IncrementNumber } {
    return (data as { 'incrementNumber': IncrementNumber }).incrementNumber !== undefined;
}
function isHoldNft(data: { 'hold': { 'originalEXT': null } | { 'boomEXT': null } } | { 'transfer': NftTransfer }): data is { 'hold': { 'originalEXT': null } | { 'boomEXT': null } } {
    return (data as { 'hold': { 'originalEXT': null } | { 'boomEXT': null } }).hold !== undefined;
}

export const useGetAllQuestsInfo = (): UseQueryResult<GuildCard[]> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.all_quests_info],
        queryFn: async () => {
            const { actor, methods } = await useGamingGuildsClient();
            const worldNode = await useGamingGuildsWorldNodeClient();
            let configs = await actor[methods.getAllConfigs]() as GuildConfig[];
            let actions = await actor[methods.getAllActions]() as Action[];
            let entities = await worldNode.actor[worldNode.methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as { ok: [StableEntity] };
            let current_user_principal = (session?.identity?.getPrincipal()) ? ((session?.identity?.getPrincipal()).toString()) : "2vxsx-fae";
            let current_user_entities = await worldNode.actor[worldNode.methods.getAllUserEntities](current_user_principal, gamingGuildsCanisterId, []) as { ok: [StableEntity] | undefined };
            let claimed_quests: string[] = [];

            if (current_user_entities.ok != undefined) {
                for (let i = 0; i < current_user_entities.ok.length; i += 1) {
                    if (current_user_entities.ok[i].eid == "quests") {
                        let fields = current_user_entities.ok[i].fields;
                        for (let j = 0; j < fields.length; j += 1) {
                            if (fields[j].fieldName == "claimedQuests") {
                                claimed_quests = (fields[j].fieldValue).split(",");
                            };
                        };
                    };
                }
            };

            // processing total completions
            let total_completions_fields: Field[] = [];
            if (entities.ok != undefined) {
                for (let j = 0; j < entities.ok.length; j += 1) {
                    if (entities.ok[j].eid == "totalCompletions") {
                        total_completions_fields = entities.ok[j].fields;
                    };
                };
            };
            let response: GuildCard[] = [];

            for (let k = 0; k < actions.length; k += 1) {
                for (let i = 0; i < configs.length; i += 1) {
                    let entry: GuildCard = {
                        aid: "",
                        title: "",
                        image: "",
                        rewards: [],
                        countCompleted: "0",
                        gameUrl: "",
                        mustHave: [],
                        expiration: "None",
                        type: "Incomplete"
                    };
                    if (configs[i].cid == actions[k].aid) {
                        let diff: bigint = 0n;
                        let config_fields: { name: string; imageUrl: string; gameUrl: string; description: string; } = getFieldsOfConfig(configs, configs[i].cid);
                        entry.aid = actions[k].aid;
                        entry.title = config_fields.name;
                        entry.image = config_fields.imageUrl;
                        entry.gameUrl = config_fields.gameUrl;
                        entry.countCompleted = getTotalCompletionOfQuest(total_completions_fields, configs[i].cid);

                        if (actions[k]['callerAction']) {
                            //process actionConstraints
                            if (actions[k]['callerAction'][0]?.['actionConstraint']) {
                                // update time constraints if present
                                if (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]) {
                                    if (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionExpirationTimestamp'][0] != undefined) {
                                        let current = BigInt(new Date().getTime());
                                        let expiration: undefined | bigint = (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionExpirationTimestamp'][0]);
                                        expiration = ((expiration != undefined) ? expiration : 0n) / BigInt(1000000);
                                        diff = expiration - current;
                                        if (diff > 0) {
                                            entry.expiration = msToTime(Number(diff));
                                        }
                                    }
                                };
                                // process entity constraints
                                let entitiesCons = actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['entityConstraint'];
                                let nftCons = actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['nftConstraint'];
                                console.log(nftCons);
                                let world_ids: Array<string | undefined> = [gamingGuildsCanisterId];
                                if (entitiesCons) {
                                    for (let m = 0; m < entitiesCons.length; m += 1) {
                                        if (entitiesCons[m]['wid'].length > 0) {
                                            world_ids.push(entitiesCons[m]['wid'][0]);
                                        };
                                    };
                                }

                                let current_user_entities_of_specific_worlds = await worldNode.actor[worldNode.methods.getAllUserEntitiesOfSpecificWorlds](current_user_principal, world_ids, []) as { ok: [StableEntity] | undefined };

                                // Edge case for entityConstraints
                                var isConstraintsFulfilled = true;
                                if (current_user_entities_of_specific_worlds.ok && entitiesCons) {
                                    let _status = await actor[methods.validateEntityConstraints](current_user_principal, current_user_entities_of_specific_worlds.ok, entitiesCons) as boolean;
                                    if(!_status){
                                        isConstraintsFulfilled = false;
                                    }
                                };
                                // if (isEntityConstraintsFulfilled) {
                                //     entry.type = "Completed";
                                // } else {
                                //     entry.type = "Incomplete";
                                // };
                                if (entitiesCons) {
                                    for (let f = 0; f < entitiesCons.length; f += 1) {
                                        config_fields = getFieldsOfConfig(configs, entitiesCons[f].eid);
                                        if (config_fields.name != "" && config_fields.imageUrl != "") {
                                            let mustHaveEntry = {
                                                name: config_fields.name,
                                                imageUrl: config_fields.imageUrl,
                                                quantity: "",
                                                description: ""
                                            };
                                            mustHaveEntry.description = config_fields.description;
                                            if (entitiesCons[f]['entityConstraintType']['greaterThanEqualToNumber'] != undefined && entitiesCons[f]['entityConstraintType']['greaterThanEqualToNumber']['fieldName'] == "quantity") {
                                                mustHaveEntry.quantity = (entitiesCons[f].entityConstraintType.greaterThanEqualToNumber.value).toString();
                                            };
                                            entry.mustHave.push(mustHaveEntry);
                                        };
                                    };
                                }
                                let registries = [];
                                let nftConstraintsStatus : boolean[] = [];
                                if(nftCons) {
                                    for (let f = 0; f < nftCons.length; f += 1) {
                                        if(isHoldNft(nftCons[f]['nftConstraintType'])){
                                            let nftActor = await useExtClient(nftCons[f].canister);
                                            registries.push(nftActor.actor[nftActor.methods.getRegistry]);
                                        }
                                        config_fields = getFieldsOfConfig(configs, nftCons[f].canister);
                                        if (config_fields.name != "" && config_fields.imageUrl != "") {
                                            let mustHaveEntry = {
                                                name: config_fields.name,
                                                imageUrl: config_fields.imageUrl,
                                                quantity: "1",
                                                description: ""
                                            };
                                            mustHaveEntry.description = config_fields.description;
                                            entry.mustHave.push(mustHaveEntry);
                                        };
                                    };
                                    await Promise.all(registries).then(
                                        (_registries: any) => {
                                            for (let k = 0; k < _registries.length; k++) {
                                                let _status = false;
                                                for(let i = 0; i < _registries[k].length; i += 1) {
                                                    if (AccountIdentifier.fromPrincipal({
                                                        principal: Principal.fromText(current_user_principal),
                                                        subAccount: undefined
                                                    }).toHex() == _registries[k][i][1]) {
                                                      _status = true;
                                                    };
                                                }
                                                nftConstraintsStatus.push(_status);
                                            };
                                            return _registries;
                                        }
                                    ).then(
                                        response => {
                                            registries = response;
                                        }
                                    );
                                }
                                for(let i = 0; i < nftConstraintsStatus.length; i += 1) {
                                    if(!nftConstraintsStatus[i]) {
                                        isConstraintsFulfilled = false;
                                    }
                                };

                                if(isConstraintsFulfilled) {
                                    entry.type = "Completed"
                                } else {
                                    entry.type = "Incomplete"
                                }

                            } else {
                                entry.type = "Completed";
                            };

                            // process actionResults for rewards
                            let outcomes = actions[k]['callerAction'][0]?.['actionResult']?.['outcomes'];
                            if (outcomes) {
                                for (let f = 0; f < outcomes.length; f += 1) {
                                    let possible_outcome_type = outcomes[f]['possibleOutcomes'][0]['option'];
                                    if (isTransferIcrc(possible_outcome_type)) {
                                        entry.rewards.push({
                                            name: "BOOM",
                                            imageUrl: "/boom-logo.png",
                                            value: (possible_outcome_type.transferIcrc.quantity).toString(),
                                            description: "The BOOM token that powers the BOOM gaming ecosystem and can be traded on ICP DEXs."
                                        });
                                    };
                                    if (isUpdateEntity(possible_outcome_type)) {
                                        config_fields = getFieldsOfConfig(configs, possible_outcome_type.updateEntity.eid);
                                        if (config_fields.name != "" && config_fields.imageUrl != "") {
                                            entry.rewards.push({
                                                name: config_fields.name,
                                                imageUrl: config_fields.imageUrl,
                                                value: ((isIncreamentNumber(possible_outcome_type.updateEntity.updates[0])) ? (possible_outcome_type.updateEntity.updates[0].incrementNumber.fieldValue.number).toString() : ""),
                                                description: config_fields.description
                                            });
                                        };
                                    };
                                    if (isMintNft(possible_outcome_type)) {
                                        // will be handled later
                                    };
                                };
                            };
                        };
                        for (let j = 0; j < claimed_quests.length; j += 1) {
                            if (claimed_quests[j] == configs[i].cid) {
                                entry.type = "Claimed";
                            };
                        };
                        if (diff >= 0n) {
                            response.push(entry);
                        }
                    };
                };
            };
            let final_response: GuildCard[] = [];
            for (let x = 0; x < response.length; x += 1) {
                if (response[x].type != "Claimed") {
                    final_response.push(response[x]);
                }
            };
            for (let x = 0; x < response.length; x += 1) {
                if (response[x].type == "Claimed") {
                    final_response.push(response[x]);
                }
            };
            return final_response;
        },
    });
};

export const useGetUserVerifiedStatus = (): UseQueryResult<VerifiedStatus> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.verified_status],
        queryFn: async () => {
            const { actor, methods } = await useGamingGuildsWorldNodeClient();
            let current_user_principal = (session?.identity?.getPrincipal()) ? ((session?.identity?.getPrincipal()).toString()) : "2vxsx-fae";
            var res: VerifiedStatus = {
                emailVerified: false,
                phoneVerified: false
            };
            let res_email = await actor[methods.getSpecificUserEntities](current_user_principal, gamingGuildsCanisterId, ["ogBadge"]) as {
                ok: [StableEntity] | undefined;
            };
            let res_phone = await actor[methods.getSpecificUserEntities](current_user_principal, gamingGuildsCanisterId, ["phoneBadge"]) as {
                ok: [StableEntity] | undefined;
            };
            if ((res_email.ok) ? (res_email.ok).length : 0 > 0) {
                res.emailVerified = true;
            };
            if ((res_phone.ok) ? (res_phone.ok).length : 0 > 0) {
                res.phoneVerified = true;
            };
            return res;
        },
    });
};

export const useClaimReward = () => {
    const queryClient = useQueryClient();
    const { t } = useTranslation();
    return useMutation({
        mutationFn: async ({
            aid,
            rewards
        }: {
            aid: string;
            rewards: { name: string; imageUrl: string; value: string; }[];
        }) => {
            try {
                const { actor, methods } = await useGamingGuildsClient();
                let result = await actor[methods.processAction]({ actionId: aid, fields: [] }) as {
                    ok: ActionReturn[];
                    err: string | undefined;
                };
                console.log(result);
                if (result.ok == undefined) {
                    throw (result.err);
                }
            } catch (error) {
                if (error instanceof Error) {
                    throw error.message;
                }
                throw serverErrorMsg;
            }
        },
        onError: () => {
            toast.error(t("gaming_guilds.Quests.claim_reward_error"));
        },
        onSuccess: (undefined, { aid: aid, rewards: rewards }) => {
            toast.custom((t) => (
                <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-40 backdrop-blur-sm">
                    <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <p className="mt-2 font-semibold text-3xl">Congratulations! You received : </p>
                        <div className="flex justify-center">
                            {rewards.length ?
                                <div className="flex mt-5 mb-12">
                                    <div className="flex justify-center">
                                        {
                                            rewards.map(({ name, imageUrl, value }) => (
                                                <div className="flex pl-5" key={imageUrl}>
                                                    <img src={imageUrl} className="mx-2 h-8" />
                                                    {(value != "") ? <div className="mt-1 mr-1">{value}</div> : <></>}
                                                    <div className="mt-1">{name}</div>
                                                </div>
                                            ))
                                        }
                                    </div>
                                </div> : <div></div>
                            }
                        </div>
                        <Button onClick={() => toast.remove()} className="float-right mb-3">Close</Button>
                    </div>
                </div>
            ), {
                position: 'top-center'
            });
            window.setTimeout(() => {
                queryClient.refetchQueries({ queryKey: [queryKeys.boom_token_balance] });
                queryClient.refetchQueries({ queryKey: [queryKeys.all_guild_members_info] });
                queryClient.refetchQueries({ queryKey: [queryKeys.all_quests_info] });
                queryClient.refetchQueries({ queryKey: [queryKeys.profile] });
            }, 15000);
        },
    });
};