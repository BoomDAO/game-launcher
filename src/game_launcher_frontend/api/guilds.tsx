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
import { GuildConfig, GuildCard, StableEntity, Field, Action, Member, MembersInfo, ActionReturn, VerifiedStatus, UserProfile, UpdateEntity, TransferIcrc, MintNft, SetNumber, IncrementNumber, DecrementNumber, NftTransfer, ActionState, UpdateAction, ActionOutcomeHistory, ActionStatusReturn, configId, StableConfig, ConfigData, QuestGamersInfo, Result_5, Result_6, Result_7 } from "@/types";
import DialogProvider from "@/components/DialogProvider";
import Button from "@/components/ui/Button";
import { AccountIdentifier } from "@dfinity/ledger-icp";

export const queryKeys = {
    all_guild_members_info: "all_guild_members_info",
    boom_token_balance: "boom_token_balance",
    all_quests_info: "all_quests_info",
    verified_status: "verified_status",
    profile: "profile",
    total_quests: "total_quests",
    page: "page"
};

const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];


function closeToast() {
    setTimeout(() => {
        toast.remove();
    }, 3000);
};
function isTransferIcrc(data: { 'updateEntity': UpdateEntity } | { 'updateAction': UpdateAction } | { 'transferIcrc': TransferIcrc } | { 'mintNft': MintNft }): data is { transferIcrc: TransferIcrc; } {
    return (data as { transferIcrc: TransferIcrc; }).transferIcrc !== undefined;
}
function isUpdateEntity(data: { 'updateEntity': UpdateEntity } | { 'updateAction': UpdateAction } | { 'transferIcrc': TransferIcrc } | { 'mintNft': MintNft }): data is { updateEntity: UpdateEntity; } {
    return (data as { updateEntity: UpdateEntity; }).updateEntity !== undefined;
}
function isMintNft(data: { 'updateEntity': UpdateEntity } | { 'updateAction': UpdateAction } | { 'transferIcrc': TransferIcrc } | { 'mintNft': MintNft }): data is { mintNft: MintNft; } {
    return (data as { mintNft: MintNft; }).mintNft !== undefined;
}
function isIncreamentNumber(data: { 'setNumber': SetNumber } | { 'incrementNumber': IncrementNumber } | { 'decrementNumber': DecrementNumber }): data is { 'incrementNumber': IncrementNumber } {
    return (data as { 'incrementNumber': IncrementNumber }).incrementNumber !== undefined;
}
function isHoldNft(data: { 'hold': { 'originalEXT': null } | { 'boomEXT': null } } | { 'transfer': NftTransfer }): data is { 'hold': { 'originalEXT': null } | { 'boomEXT': null } } {
    return (data as { 'hold': { 'originalEXT': null } | { 'boomEXT': null } }).hold !== undefined;
}
function isActionStatesUserNotFoundErr(data: { 'ok': Array<ActionState> } | { 'err': string }): data is { 'err': string } {
    return ((data as { 'err': string }).err !== undefined);
}
function isActionStatusNotEnabledErr(data: { 'ok' : ActionStatusReturn } | { 'err' : string }): data is { 'err': string } {
    return ((data as { 'err': string }).err !== undefined);
}
function isActionStatusOk(data: { 'ok' : ActionStatusReturn } | { 'err' : string }): data is { 'ok' : ActionStatusReturn } {
    return ((data as { 'ok' : ActionStatusReturn }).ok !== undefined);
}
function isActionStatesUserOk(data: { 'ok': Array<ActionState> } | { 'err': string }): data is { 'ok': Array<ActionState> } {
    return ((data as { 'ok': Array<ActionState> }).ok !== undefined);
}
function isResult_5Ok(data: { 'ok' : Array<StableEntity> } | { 'err' : string }): data is { 'ok' : Array<StableEntity> } {
    return ((data as { 'ok' : Array<StableEntity> }).ok !== undefined);
}

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
                    err: string;
                };
                if (result.ok == undefined) {
                    toast.error(result.err);
                    closeToast();
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
            closeToast();
        },
        onSuccess: () => {
            toast.success(t("verification.verification_success"));
            closeToast();
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
                for (let i = 0; i < phone.length; i += 1) {
                    if (phone[i] == ' ') {
                        toast.error("Try again without spaces.");
                        closeToast();
                        throw ("");
                    }
                };
                const { actor, methods } = await useGuildsVerifierClient();
                let result = await actor[methods.sendVerificationSMS](phone) as {
                    ok: string | undefined;
                    err: string;
                };
                if (result.ok == undefined) {
                    toast.error(result.err);
                    closeToast();
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
            closeToast();
        },
        onSuccess: () => {
            toast.success(t("verification.verification_success_phone"));
            closeToast();
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
                    toast.error((result.err) ? result.err : "");
                    closeToast();
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
            closeToast();
        },
        onSuccess: () => {
            toast.success(t("verification.otp_success"));
            closeToast();
            queryClient.refetchQueries({ queryKey: [queryKeys.verified_status] });
            queryClient.refetchQueries({ queryKey: [queryKeys.all_quests_info] });
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
                    toast.error((result.err) ? result.err : "");
                    closeToast();
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
            closeToast();
        },
        onSuccess: () => {
            toast.success(t("verification.otp_success_sms"));
            closeToast();
            queryClient.refetchQueries({ queryKey: [queryKeys.verified_status] });
            queryClient.refetchQueries({ queryKey: [queryKeys.all_quests_info] });
        }
    });
};

const getFieldsOfConfig = (configs: GuildConfig[], config: string) => {
    let res = {
        cid: config,
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
                if (configs[i].fields[j].fieldName == "image_url") {
                    res.imageUrl = configs[i].fields[j].fieldValue;
                };
                if (configs[i].fields[j].fieldName == "quest_url") {
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

export const getConfigsData = (configIds: configId[]): UseQueryResult<ConfigData[]> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [],
        queryFn: async () => {
            const { actor, methods } = await useGamingGuildsClient();
            let response: ConfigData[] = [];
            let configs = await actor[methods.getAllConfigs]() as StableConfig[];
            for (let id = 0; id < configIds.length; id += 1) {
                let config = getFieldsOfConfig(configs, configIds[id]);
                response.push(config);
            }
            return response;
        },
    });
};

const getUserInfo = (fields: Field[]) => {
    let res = {
        guilds: "",
        joinDate: "",
    };
    for (let j = 0; j < fields.length; j += 1) {
        if (fields[j].fieldName == "xp_leaderboard") {
            res.guilds = fields[j].fieldValue;
        };
        if (fields[j].fieldName == "join_date_leaderboard") {
            res.joinDate = fields[j].fieldValue;
        };
    };
    return res;
};

export const useGetAllMembersInfo = (page: number = 1): UseQueryResult<MembersInfo> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.all_guild_members_info, page],
        queryFn: async () => {
            let response: MembersInfo = {
                totalMembers: "",
                members: [],
            };
            const { actor, methods } = await useGamingGuildsWorldNodeClient();
            const worldHub = await useWorldHubClient();
            // fetching totalMembers
            let totalMembersEntity: { ok: StableEntity[] } = { ok: [] };
            let entities: { ok: StableEntity[] } = { ok: [] };
            await Promise.all(
                [actor[methods.getSpecificUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, ["total_members"]) as Promise<{ ok: StableEntity[]; }>, actor[methods.getUserEntitiesFromWorldNodeComposite](gamingGuildsCanisterId, gamingGuildsCanisterId, [BigInt(page - 1)]) as Promise<{ ok: StableEntity[] }>]
            ).then((results => {
                totalMembersEntity = results[0];
                entities = results[1];
            }));

            let fields = totalMembersEntity.ok[0].fields;
            for (let i = 0; i < fields.length; i += 1) {
                if (fields[i].fieldName == "quantity") {
                    response.totalMembers = (((fields[i].fieldValue).split("."))[0]).toString();
                }
            };
            let members_info: Member[] = [];
            // processing members info
            let isAnonPresent = false;
            for (let i = 0; i < entities.ok.length; i += 1) {
                fields = entities.ok[i].fields;
                let memberInfo = getUserInfo(fields);
                let current_member: Member = {
                    uid: "",
                    rank: "",
                    image: "/usericon.png",
                    username: "",
                    guilds: "0",
                    joinDate: ""
                };
                if (entities.ok[i].eid == Principal.anonymous().toString()) {
                    isAnonPresent = true;
                };
                try {
                    let p = Principal.fromText(entities.ok[i].eid);
                    if (p._isPrincipal && !isAnonPresent) {
                        current_member.username = (entities.ok[i].eid).substring(0, 20) + ".....";
                        current_member.uid = entities.ok[i].eid;
                        let reg_time: number = Number(memberInfo.joinDate) / (1000000);
                        let date = new Date(reg_time);
                        current_member.joinDate = months[(date.getMonth())] + ' ' + date.getFullYear();
                        current_member.guilds = (memberInfo.guilds).split(".")[0];
                        members_info.push(current_member);
                    };
                } catch (e) {};
                current_member.rank = String(((page - 1)  * 40) + i + 1);
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
            if (isAnonPresent) {
                response.totalMembers = (Number(response.totalMembers) - 1).toString();
            }
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

const getFieldsOfEntity = (entities: StableEntity[], entityId: string) => {
    for (let j = 0; j < entities.length; j += 1) {
        if (entities[j].eid == entityId) {
            return entities[j].fields;
        };
    };
    return [];
};

const getTotalCompletionOfQuest = (fields: Field[], quest: string) => {
    for (let i = 0; i < fields.length; i += 1) {
        if (fields[i].fieldName == quest) {
            return ((fields[i].fieldValue).split("."))[0];
        };
    };
    return "0";
};

const getActionState = (actionStates: ActionState[], actionId: string) => {
    for (let i = 0; i < actionStates.length; i += 1) {
        if (actionId == actionStates[i].actionId) {
            return actionStates[i];
        }
    };
    return {
        actionCount: 0,
        intervalStartTs: 0,
        actionId: ""
    };
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
                image: "/usericon.png"
            };
            const { actor, methods } = await useGamingGuildsWorldNodeClient();
            const worldHub = await useWorldHubClient();
            let UserEntity : Result_5 = { ok : [] };
            let entities : Result_5 = { ok : [] };
            let profile : { uid: string; username: string; image: string; } = { uid : "", username : "", image : ""};
            await Promise.all(
                [actor[methods.getSpecificUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, [current_user_principal]) as Promise<Result_5>, worldHub.actor[worldHub.methods.getUserProfile]({ uid: current_user_principal }) as Promise<{ uid: string; username: string; image: string; }>, actor[methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as Promise<Result_5>]
            ).then((results) => {
                UserEntity = results[0];
                profile = results[1];
                entities = results[2];
            });
            if (isResult_5Ok(UserEntity)) {
                let fields = UserEntity.ok[0].fields;
                for (let i = 0; i < fields.length; i += 1) {
                    if (fields[i].fieldName == "xp_leaderboard") {
                        response.xp = (((fields[i].fieldValue).split("."))[0]).toString();
                    }
                };
            } else {
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
            response = {
                uid: profile.uid,
                username: (profile.username == profile.uid) ? (profile.uid).substring(0, 10) + "..." : (profile.username.length > 10) ? (profile.username).substring(0, 10) + "..." : profile.username,
                xp: response.xp,
                image: (profile.image != "") ? profile.image : "/usericon.png"
            };
            return response;
        },
    });
};

export const useGetAllQuestsInfo = (): UseQueryResult<GuildCard[]> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.all_quests_info],
        queryFn: async () => {
            let current_user_principal = (session?.identity?.getPrincipal()) ? ((session?.identity?.getPrincipal()).toString()) : "2vxsx-fae";
            const { actor, methods } = await useGamingGuildsClient();
            const worldNode = await useGamingGuildsWorldNodeClient();
            const worldHub = await useWorldHubClient();

            let configs: GuildConfig[] = [];
            let actions: Action[] = [];
            let actionStates: Result_6 = { ok: [] };
            let entities: { ok: StableEntity[] } = { ok: [] };
            let actionStatusResponseOfUser: Result_7[] = [];
            await Promise.all(
                [actor[methods.getAllActions]() as Promise<Action[]>, actor[methods.getAllConfigs]() as Promise<GuildConfig[]>, actor[methods.getAllUserActionStatesComposite]({ uid: current_user_principal }) as Promise<Result_6>, worldNode.actor[worldNode.methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as Promise<{ ok: StableEntity[] }>]
            ).then((results) => {
                actions = results[0];
                configs = results[1];
                actionStates = results[2];
                entities = results[3];
            });

            // Check for new user
            if (isActionStatesUserNotFoundErr(actionStates)) {
                console.log("new user found!");
                if (session?.identity) {
                    let principal = Principal.fromText(current_user_principal);
                    console.log("new user principal : " + current_user_principal);
                    let new_user = await worldHub.actor[worldHub.methods.createNewUser]({
                        user: principal,
                        requireEntireNode: false
                    });
                    console.log("createNewUser response : " + new_user);
                    actionStates = await actor[methods.getAllUserActionStatesComposite]({ uid: current_user_principal }) as Result_6;
                }
            };
            let total_completions_fields: Field[] = getFieldsOfEntity(entities.ok, "total_completions");
            let claimed_quests: string[] = [];
            let response: GuildCard[] = [];

            let actionStatusResponse_promises = [];
            for (let k = 0; k < actions.length; k += 1) {
                for (let i = 0; i < configs.length; i += 1) {
                    if (configs[i].cid == actions[k].aid) {
                        actionStatusResponse_promises.push(actor[methods.getActionStatusComposite]({ uid: current_user_principal, aid: actions[k].aid }) as Promise<Result_7>);
                    };
                }
            };

            await Promise.all(actionStatusResponse_promises).then((result) => {
                actionStatusResponseOfUser = result;
            });

            let actionStatusResponseOfUserIndex = 0;
            for (let k = 0; k < actions.length; k += 1) {
                for (let i = 0; i < configs.length; i += 1) {
                    let entry: GuildCard = {
                        aid: "",
                        title: "",
                        description: "",
                        image: "",
                        rewards: [],
                        countCompleted: "0",
                        gameUrl: "",
                        mustHave: [],
                        expiration: "0",
                        type: "Incomplete",
                        gamersImages: [],
                        isDailyQuest: false
                    };
                    if (configs[i].cid == actions[k].aid) {
                        let diff: bigint = 0n;
                        let config_fields: { name: string; imageUrl: string; gameUrl: string; description: string; } = getFieldsOfConfig(configs, configs[i].cid);
                        entry.aid = actions[k].aid;
                        entry.title = config_fields.name;
                        entry.image = config_fields.imageUrl;
                        entry.gameUrl = config_fields.gameUrl;
                        entry.description = config_fields.description;
                        entry.countCompleted = getTotalCompletionOfQuest(total_completions_fields, configs[i].cid);
                        var isConstraintsFulfilled = true;
                        if (actions[k]['callerAction']) {
                            //process actionConstraints
                            if (actions[k]['callerAction'][0]?.['actionConstraint']) {
                                // process timeConstraints
                                if (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]) {
                                    // update action expiration
                                    let current = BigInt(new Date().getTime());
                                    if (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionExpirationTimestamp'][0]) {
                                        let expiration: undefined | bigint = (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionExpirationTimestamp'][0]);
                                        expiration = ((expiration != undefined) ? expiration : 0n) / BigInt(1000000);
                                        diff = expiration - current;
                                        if (diff > 0) {
                                            entry.expiration = "-" + msToTime(Number(diff));
                                        }
                                    }

                                    if (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionStartTimestamp'][0]) {
                                        let start: undefined | bigint = (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionStartTimestamp'][0]);
                                        start = ((start != undefined) ? start : 0n) / BigInt(1000000);
                                        entry.expiration = "+" + msToTime(Number(start - current));
                                    }

                                    // process action time intervals
                                    if (actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionTimeInterval'][0]) {
                                        let duration = actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionTimeInterval'][0]?.intervalDuration;

                                        if (duration == 86400000000000n) {
                                            entry.isDailyQuest = true;
                                        };
                                        let actionsPerInterval = actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['timeConstraint'][0]?.['actionTimeInterval'][0]?.actionsPerInterval;
                                        let { intervalStartTs, actionCount, actionId } = getActionState(isActionStatesUserOk(actionStates) ? actionStates.ok : [], actions[k].aid);
                                        duration = ((duration != undefined) ? duration : 0n) / BigInt(1000000);
                                        intervalStartTs = ((intervalStartTs != undefined) ? BigInt(intervalStartTs) : 0n) / BigInt(1000000);
                                        actionsPerInterval = ((actionsPerInterval != undefined) ? BigInt(actionsPerInterval) : 0n);
                                        if ((intervalStartTs + duration) > current && actionCount >= actionsPerInterval && actionsPerInterval > 0) {
                                            claimed_quests.push(actionId);
                                        };
                                    };
                                };

                                // process ActionStatusResponse
                                let actionStatusResponse = actionStatusResponseOfUser[actionStatusResponseOfUserIndex];
                                actionStatusResponseOfUserIndex = actionStatusResponseOfUserIndex + 1;
                                if (isActionStatusOk(actionStatusResponse)) {
                                    let status = actionStatusResponse.ok;
                                    if (!status.isValid) {
                                        isConstraintsFulfilled = false;
                                    };
                                    for (let x = 0; x < status.actionHistoryStatus.length; x += 1) {
                                        let currentValue = (status.actionHistoryStatus[x].currentValue).split(".")[0].toString();
                                        let expected = (status.actionHistoryStatus[x].expectedValue).split(".")[0].toString();
                                        let fields = getFieldsOfConfig(configs, status.actionHistoryStatus[x].eid);
                                        if (fields.name != "" && fields.imageUrl != "") {
                                            let mustHaveEntry = {
                                                name: fields.name,
                                                imageUrl: fields.imageUrl,
                                                quantity: currentValue + "/" + expected,
                                                description: ""
                                            };
                                            mustHaveEntry.description = fields.description;
                                            entry.mustHave.push(mustHaveEntry);
                                        };
                                    };
                                    for (let x = 0; x < status.entitiesStatus.length; x += 1) {
                                        let currentValue = (status.entitiesStatus[x].currentValue).split(".")[0].toString();
                                        let expected = (status.entitiesStatus[x].expectedValue).split(".")[0].toString();
                                        let fields = getFieldsOfConfig(configs, status.entitiesStatus[x].eid);
                                        if (fields.name != "" && fields.imageUrl != "") {
                                            let mustHaveEntry = {
                                                name: fields.name,
                                                imageUrl: fields.imageUrl,
                                                quantity: currentValue + "/" + expected,
                                                description: ""
                                            };
                                            mustHaveEntry.description = fields.description;
                                            entry.mustHave.push(mustHaveEntry);
                                        };
                                        fields = getFieldsOfConfig(configs, status.entitiesStatus[x].fieldName);
                                        if (fields.name != "" && fields.imageUrl != "") {
                                            let mustHaveEntry = {
                                                name: fields.name,
                                                imageUrl: fields.imageUrl,
                                                quantity: currentValue + "/" + expected,
                                                description: ""
                                            };
                                            mustHaveEntry.description = fields.description;
                                            entry.mustHave.push(mustHaveEntry);
                                        };
                                    };
                                } else if(isActionStatesUserNotFoundErr(actionStatusResponse)) {
                                    isConstraintsFulfilled = false;
                                };

                                // process nftConstraints
                                let nftCons = actions[k]['callerAction'][0]?.['actionConstraint'][0]?.['nftConstraint'];
                                let registries = [];
                                let nftConstraintsStatus: number[] = [];
                                if (nftCons?.length) {
                                    for (let f = 0; f < nftCons.length; f += 1) {
                                        if (isHoldNft(nftCons[f]['nftConstraintType'])) {
                                            let nftActor = await useExtClient(nftCons[f].canister);
                                            registries.push(nftActor.actor[nftActor.methods.getRegistry]());
                                        }

                                    };
                                    await Promise.all(registries).then(
                                        (_registries: any) => {
                                            for (let k = 0; k < _registries.length; k++) {
                                                let _count = 0;
                                                for (let i = 0; i < _registries[k].length; i += 1) {
                                                    if (AccountIdentifier.fromPrincipal({
                                                        principal: Principal.fromText(current_user_principal),
                                                        subAccount: undefined
                                                    }).toHex() == _registries[k][i][1]) {
                                                        _count = _count + 1;
                                                    };
                                                }
                                                nftConstraintsStatus.push(_count);
                                            };
                                            return _registries;
                                        }
                                    ).then(
                                        response => {
                                            registries = response;
                                        }
                                    );

                                    for (let i = 0; i < nftCons.length; i += 1) {
                                        if (nftConstraintsStatus[i] == 0) {
                                            isConstraintsFulfilled = false;
                                        }
                                        config_fields = getFieldsOfConfig(configs, nftCons[i].canister);
                                        if (config_fields.name != "" && config_fields.imageUrl != "") {
                                            let mustHaveEntry = {
                                                name: config_fields.name,
                                                imageUrl: config_fields.imageUrl,
                                                quantity: nftConstraintsStatus[i] + "/" + "1",
                                                description: ""
                                            };
                                            mustHaveEntry.description = config_fields.description;
                                            entry.mustHave.push(mustHaveEntry);
                                        };
                                    };
                                }

                                if (isConstraintsFulfilled) {
                                    entry.type = "Completed"
                                } else {
                                    entry.type = "Incomplete"
                                }

                            } else { // if actionConstraints not present
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
                        let user_principals: string[] = [];
                        let quest_fields: Field[] = getFieldsOfEntity(entities.ok, "quest_participants");
                        for (let field = 0; field < quest_fields.length; field += 1) {
                            if (quest_fields[field].fieldName == actions[k].aid) {
                                user_principals = (quest_fields[field].fieldValue).split(",");
                            };
                        };
                        if (user_principals.length == 0) {
                            user_principals.push("lgjp4-nfvab-rl4wt-77he2-3hnxe-24pvi-7rykv-6yyr4-sqwdd-4j2fz-fae");
                        };
                        let profiles_promises = [];
                        let user_profiles: { uid: string; username: string; image: string; }[] = [];
                        for (let id = 0; id < user_principals.length; id += 1) {
                            profiles_promises.push(worldHub.actor[worldHub.methods.getUserProfile]({ uid: user_principals[id] }) as Promise<{ uid: string; username: string; image: string; }>);
                        };
                        await Promise.all(profiles_promises).then((res) => { user_profiles = res; });
                        for (let id = 0; id < user_profiles.length; id += 1) {
                            if(user_profiles[id].image != "") {
                                entry.gamersImages.push(user_profiles[id].image);
                            };
                            if(entry.gamersImages.length == 3) {
                                break;
                            };
                        };
                        if(entry.gamersImages.length < 3) {
                            for(let id = 0; id <= Math.min(3, (3 - entry.gamersImages.length)); id += 1) {
                                entry.gamersImages.push("/usericon.png");
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
                if (response[x].type == "Completed") {
                    final_response.push(response[x]);
                }
            };
            for (let x = 0; x < response.length; x += 1) {
                if ((response[x].type == "Incomplete" && response[x].expiration[0] == "-") || (response[x].type == "Incomplete" && response[x].expiration[0] == "0")) {
                    final_response.push(response[x]);
                }
            };
            for (let x = 0; x < response.length; x += 1) {
                if (response[x].type == "Incomplete" && response[x].expiration[0] == "+") {
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

export const useGetTotalQuests = (): UseQueryResult<number> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.total_quests],
        queryFn: async () => {
            const { actor, methods } = await useGamingGuildsClient();
            const worldNode = await useGamingGuildsWorldNodeClient();
            let configs : GuildConfig[] = [];
            let actions : Action[] = [];
            await Promise.all(
                [actor[methods.getAllConfigs]() as Promise<GuildConfig[]>, actor[methods.getAllActions]() as Promise<Action[]>]
            ).then((results) => {
                configs = results[0];
                actions = results[1];
            });
            let total = 0;
            for (let k = 0; k < actions.length; k += 1) {
                for (let i = 0; i < configs.length; i += 1) {
                    if (configs[i].cid == actions[k].aid) {
                        total += 1;
                    };
                };
            };
            return total;
        },
    });
};

export const useGetUserVerifiedStatus = (): UseQueryResult<VerifiedStatus> => {
    const { session } = useAuthContext();
    return useQuery({
        queryKey: [queryKeys.verified_status],
        queryFn: async () => {
            const { actor, methods } = await useGamingGuildsClient();
            let current_user_principal = (session?.identity?.getPrincipal()) ? ((session?.identity?.getPrincipal()).toString()) : "2vxsx-fae";
            var res: VerifiedStatus = {
                emailVerified: false,
                phoneVerified: false
            };
            let entities = await actor[methods.getAllUserEntitiesComposite]({ uid: current_user_principal, page: [] }) as {
                ok: StableEntity[] | undefined;
            };
            if (entities.ok?.length && entities.ok.length > 0) {
                for (let i = 0; i < entities.ok.length; i += 1) {
                    if (entities.ok[i].eid == "airdrop_badge") {
                        res.emailVerified = true;
                    };
                    if (entities.ok[i].eid == "phone_badge") {
                        res.phoneVerified = true;
                    };
                }
            }
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
                let result = await actor[methods.processActionAwait]({ actionId: aid, fields: [] }) as {
                    ok: ActionReturn[];
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
            toast.error(t("gaming_guilds.Quests.claim_reward_error"));
            closeToast();
        },
        onSuccess: (undefined, { aid: aid, rewards: rewards }) => {
            toast.custom((t) => (
                <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                    <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
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
                            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                        </div>
                    </div>
                </div>
            ));
            queryClient.refetchQueries({ queryKey: [queryKeys.boom_token_balance] });
            queryClient.refetchQueries({ queryKey: [queryKeys.all_guild_members_info] });
            queryClient.refetchQueries({ queryKey: [queryKeys.all_quests_info] });
            queryClient.refetchQueries({ queryKey: [queryKeys.profile] });
            closeToast();
        },
    });
};