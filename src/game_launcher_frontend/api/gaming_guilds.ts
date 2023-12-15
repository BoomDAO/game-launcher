// import { toast } from "react-hot-toast";
// import { useTranslation } from "react-i18next";
// import { useNavigate } from "react-router-dom";
// import { Actor } from "@dfinity/agent";
// import { Principal } from "@dfinity/principal";
// import {
//   UseQueryResult,
//   useMutation,
//   useQuery,
//   useQueryClient,
// } from "@tanstack/react-query";
// import { gamingGuildsCanisterId, useBoomLedgerClient, useGamingGuildsClient, useGamingGuildsWorldNodeClient, useGuildsVerifierClient } from "@/hooks";
// import { navPaths, serverErrorMsg } from "@/shared";
// import { useAuthContext } from "@/context/authContext";
// import { GuildConfig, GuildCard, StableEntity, Field, Action, Member, MembersInfo, ActionReturn } from "@/types";
// import DialogProvider from "@/components/DialogProvider";

// export const queryKeys = {
//   all_guild_members_info: "all_guild_members_info",
//   boom_token_balance: "boom_token_balance",
//   all_quests_info: "all_quests_info",
//   verified_status: "verified_status"
// };

// const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];

// export const useSubmitEmail = () => {
//   const { t } = useTranslation();
//   return useMutation({
//     mutationFn: async ({
//       email,
//     }: {
//       email: string;
//     }) => {
//       try {
//         const { actor, methods } = await useGuildsVerifierClient();
//         let result = await actor[methods.sendVerificationEmail](email) as {
//           ok: string | undefined;
//           err: string | undefined;
//         };
//         if (result.ok == undefined) {
//           throw (result.err);
//         }
//       } catch (error) {
//         if (error instanceof Error) {
//           throw error.message;
//         }
//         throw serverErrorMsg;
//       }
//     },
//     onError: () => {
//       toast.error(t("verification.verification_error"));
//     },
//     onSuccess: () => {
//       toast.success(t("verification.verification_success"));
//     },
//   });
// };

// export const useVerifyEmail = () => {
//   const queryClient = useQueryClient();
//   const { t } = useTranslation();
//   return useMutation({
//     mutationFn: async ({
//       email,
//       otp,
//     }: {
//       email: string;
//       otp: string;
//     }) => {
//       try {
//         const { actor, methods } = await useGuildsVerifierClient();
//         let result = await actor[methods.verifyOTP]({ email: email, otp: otp }) as {
//           ok: string | undefined;
//           err: string | undefined;
//         };
//         if (result.ok == undefined) {
//           throw (result.err);
//         }
//       } catch (error) {
//         if (error instanceof Error) {
//           throw error.message;
//         }
//         throw serverErrorMsg;
//       }
//     },
//     onError: () => {
//       toast.error(t("verification.otp_error"));
//     },
//     onSuccess: () => {
//       toast.success(t("verification.otp_success"));
//       queryClient.refetchQueries({ queryKey: [queryKeys.verified_status] });
//     }
//   });
// };

// const msToTime = (ms: number) => {
//   let seconds = Math.floor(ms / 1000);
//   let minutes = Math.floor(seconds / 60);
//   let hours = Math.floor(minutes / 60);
//   seconds = seconds % 60;
//   minutes = minutes % 60;
//   let days = (hours / 24).toString().split(".")[0];
//   hours = hours % 24;
//   return days + "D " + hours + "H " + minutes + "M ";
// }

// const getFieldsOfConfig = (configs: GuildConfig[], config: string) => {
//   let res = {
//     name: "",
//     imageUrl: "",
//     gameUrl: ""
//   };
//   for (let i = 0; i < configs.length; i += 1) {
//     if (configs[i].cid == config) {
//       for (let j = 0; j < configs[i].fields.length; j += 1) {
//         if (configs[i].fields[j].fieldName == "name") {
//           res.name = (configs[i].fields[j].fieldValue).toUpperCase();
//         };
//         if (configs[i].fields[j].fieldName == "imageUrl") {
//           res.imageUrl = configs[i].fields[j].fieldValue;
//         };
//         if (configs[i].fields[j].fieldName == "gameUrl") {
//           res.gameUrl = configs[i].fields[j].fieldValue;
//         };
//       };
//     };
//   };
//   return res;
// };

// const getTotalCompletionOfQuest = (fields: Field[], quest: string) => {
//   for (let i = 0; i < fields.length; i += 1) {
//     if (fields[i].fieldName == quest) {
//       return ((fields[i].fieldValue).split("."))[0];
//     };
//   };
//   return "0";
// };

// const getUserInfo = (fields: Field[]) => {
//   let res = {
//     imageUrl: "",
//     username: "",
//     guilds: "",
//     joinDate: "",
//   };

//   for (let j = 0; j < fields.length; j += 1) {
//     if (fields[j].fieldName == "imageUrl") {
//       res.imageUrl = fields[j].fieldValue;
//     };
//     if (fields[j].fieldName == "username") {
//       res.username = fields[j].fieldValue;
//     };
//     if (fields[j].fieldName == "xp") {
//       res.guilds = fields[j].fieldValue;
//     };
//     if (fields[j].fieldName == "joinDate") {
//       res.joinDate = fields[j].fieldValue;
//     };
//   };
//   return res;
// };

// export const useGetAllQuestsInfo = (): UseQueryResult<GuildCard[]> => {
//   const { session } = useAuthContext();
//   return useQuery({
//     queryKey: [queryKeys.all_quests_info],
//     queryFn: async () => {
//       const { actor, methods } = await useGamingGuildsClient();
//       const worldNode = await useGamingGuildsWorldNodeClient();
//       let configs = await actor[methods.getAllConfigs]() as GuildConfig[];
//       let actions = await actor[methods.getAllActions]() as Action[];
//       let entities = await worldNode.actor[worldNode.methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as { ok: [StableEntity] };
//       let current_user_principal = (session?.identity?.getPrincipal())? ((session?.identity?.getPrincipal()).toString()) :  "2vxsx-fae";
//       let current_user_entities = await worldNode.actor[worldNode.methods.getAllUserEntities](current_user_principal, gamingGuildsCanisterId, []) as { ok: [StableEntity] | undefined };
//       let claimed_quests: string[] = [];

//       if (current_user_entities.ok != undefined) {
//         for(let i = 0; i < current_user_entities.ok.length; i += 1) {
//           if(current_user_entities.ok[i].eid == "quests") {
//             let fields = current_user_entities.ok[0].fields;
//             for (let j = 0; j < fields.length; j += 1) {
//               if (fields[j].fieldName == "claimedQuests") {
//                 claimed_quests = (fields[j].fieldValue).split(",");
//               };
//             };
//           };
//         }
//       };

//       // processing total completions
//       let total_completions_fields: Field[] = [];
//       if (entities.ok != undefined) {
//         for (let j = 0; j < entities.ok.length; j += 1) {
//           if (entities.ok[j].eid == "totalCompletions") {
//             total_completions_fields = entities.ok[j].fields;
//           };
//         };
//       };
//       let response: GuildCard[] = [];

//       for (let k = 0; k < actions.length; k += 1) {
//         for (let i = 0; i < configs.length; i += 1) {
//           let entry: GuildCard = {
//             aid: "",
//             title: "",
//             image: "",
//             rewards: [],
//             countCompleted: "0",
//             gameUrl: "",
//             mustHave: [],
//             expiration: "None",
//             type: "Incomplete"
//           };
//           if (configs[i].cid == actions[k].aid) {
//             let diff : bigint = 0n;
//             let config_fields: { name: string; imageUrl: string; gameUrl: string; } = getFieldsOfConfig(configs, configs[i].cid);
//             entry.aid = actions[k].aid;
//             entry.title = config_fields.name;
//             entry.image = config_fields.imageUrl;
//             entry.gameUrl = config_fields.gameUrl;
//             entry.countCompleted = getTotalCompletionOfQuest(total_completions_fields, configs[i].cid);

//             // console.log(actions[k]);
//             if (actions[k].callerAction.length != 0) {    
//               //process actionConstraints
//               if (actions[k].callerAction[0].actionConstraint.length != 0) {
//                 // update time constraints if present
//                 if (actions[k].callerAction[0].actionConstraint[0].timeConstraint.length != 0) {
//                   if (actions[k].callerAction[0].actionConstraint[0].timeConstraint[0].actionExpirationTimestamp.length != 0) {
//                     let current = BigInt(new Date().getTime());
//                     let expiration: bigint = (actions[k].callerAction[0].actionConstraint[0].timeConstraint[0].actionExpirationTimestamp[0]) / BigInt(1000000);
//                     diff = expiration - current;
//                     if (diff > 0) {
//                       entry.expiration = msToTime(Number(diff));
//                     }
//                   }
//                 };
//                 // process entity constraints
//                 let entitiesCons = actions[k].callerAction[0].actionConstraint[0].entityConstraint;
//                 let world_ids = [gamingGuildsCanisterId];
//                 for(let m = 0; m < entitiesCons.length; m += 1) {
//                   if(entitiesCons[m].wid.length > 0) {
//                     world_ids.push(entitiesCons[m].wid[0]);
//                   };
//                 };
//                 let current_user_entities_of_specific_worlds = await worldNode.actor[worldNode.methods.getAllUserEntitiesOfSpecificWorlds](current_user_principal, world_ids, []) as { ok: [StableEntity] | undefined };
//                 let isQuestCompleted = await actor[methods.validateEntityConstraints](current_user_entities_of_specific_worlds.ok, entitiesCons) as boolean;
//                 console.log(configs[i].cid + " " + isQuestCompleted);
//                 if (isQuestCompleted) {
//                   entry.type = "Completed";
//                 } else {
//                   entry.type = "Incomplete";
//                 };
//                 for (let f = 0; f < entitiesCons.length; f += 1) {
//                   config_fields = getFieldsOfConfig(configs, entitiesCons[f].eid);
//                   if (config_fields.name != "" && config_fields.imageUrl != "") {
//                     let mustHaveEntry = {
//                       name: config_fields.name,
//                       imageUrl: config_fields.imageUrl,
//                       quantity: ""
//                     };
//                     if (entitiesCons[f].entityConstraintType.greaterThanEqualToNumber != null && entitiesCons[f].entityConstraintType.greaterThanEqualToNumber.fieldName == "quantity") {
//                       mustHaveEntry.quantity = (entitiesCons[f].entityConstraintType.greaterThanEqualToNumber.value).toString();
//                     };
//                     entry.mustHave.push(mustHaveEntry);
//                   };
//                 };
//               } else {
//                 entry.type = "Completed";
//               };

//               // process actionResults for rewards
//               let outcomes = actions[k].callerAction[0].actionResult.outcomes;
//               if (outcomes.length != 0) {
//                 for (let f = 0; f < outcomes.length; f += 1) {
//                   let possible_outcome_type = outcomes[f].possibleOutcomes[0].option;
//                   if (possible_outcome_type.transferIcrc != undefined) {
//                     entry.rewards.push({
//                       name: "BOOM",
//                       imageUrl: "/boom-logo.png",
//                       value: (possible_outcome_type.transferIcrc.quantity).toString()
//                     });
//                   };
//                   if (possible_outcome_type.updateEntity != undefined) {
//                     config_fields = getFieldsOfConfig(configs, possible_outcome_type.updateEntity.eid);
//                     if (config_fields.name != "" && config_fields.imageUrl != "") {
//                       entry.rewards.push({
//                         name: config_fields.name,
//                         imageUrl: config_fields.imageUrl,
//                         value: ((possible_outcome_type.updateEntity.updates[0].incrementNumber.fieldValue.number) ? (possible_outcome_type.updateEntity.updates[0].incrementNumber.fieldValue.number).toString() : "")
//                       });
//                     };
//                   };
//                   if (possible_outcome_type.mintNft != undefined) {
//                     // will be handled later
//                   };
//                 };
//               };
//             };
//             for (let j = 0; j < claimed_quests.length; j += 1) {
//               if (claimed_quests[j] == configs[i].cid) {
//                 entry.type = "Claimed";
//               };
//             };
//             if(diff >= 0n){
//               response.push(entry);
//             } 
//           };
//         };
//       };
//       return response;
//     },
//   });
// };

// export const useGetBoomBalance = (): UseQueryResult<string> => {
//   const { session } = useAuthContext();
//   return useQuery({
//     queryKey: [queryKeys.boom_token_balance],
//     queryFn: async () => {
//       const { actor, methods } = await useBoomLedgerClient();
//       let balance = await actor[methods.icrc1_balance_of]({
//         owner: Principal.fromText(gamingGuildsCanisterId),
//         subaccount: [],
//       }) as bigint;
//       balance = BigInt(balance) / BigInt(100000000);
//       return balance.toString();
//     },
//   });
// };

// export const useGetUserVerifiedStatus = (): UseQueryResult<boolean> => {
//   const { session } = useAuthContext();
//   return useQuery({
//     queryKey: [queryKeys.verified_status],
//     queryFn: async () => {
//       const { actor, methods } = await useGamingGuildsWorldNodeClient();
//       let current_user_principal = (session?.identity?.getPrincipal())? ((session?.identity?.getPrincipal()).toString()) :  "2vxsx-fae";
//       let res = await actor[methods.getSpecificUserEntities](current_user_principal, gamingGuildsCanisterId, ["ogBadge"]) as {
//         ok: [StableEntity] | undefined;
//       };
//       if((res.ok)?(res.ok).length : 0 > 0) {
//         return true;
//       } else {
//         return false;
//       };
//     },
//   });
// };

// export const useGetAllMembersInfo = (): UseQueryResult<MembersInfo> => {
//   const { session } = useAuthContext();
//   return useQuery({
//     queryKey: [queryKeys.all_guild_members_info],
//     queryFn: async () => {
//       let response: MembersInfo = {
//         totalMembers: "",
//         members: [],
//       };
//       const { actor, methods } = await useGamingGuildsWorldNodeClient();
//       // fetching totalMembers
//       let totalMembersEntity = await actor[methods.getSpecificUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, ["totalMembers"]) as { ok: [StableEntity]; };
//       let entities = await actor[methods.getAllUserEntities](gamingGuildsCanisterId, gamingGuildsCanisterId, []) as { ok: [StableEntity] };
//       let fields = totalMembersEntity.ok[0].fields;
//       for (let i = 0; i < fields.length; i += 1) {
//         if (fields[i].fieldName == "quantity") {
//           response.totalMembers = (((fields[i].fieldValue).split("."))[0]).toString();
//         }
//       };
//       // processing members info
//       let current_user_principal = (session?.identity?.getPrincipal())?.toString();
//       let isCurrentUserAlreadyGuildMember = false;
//       for (let i = 0; i < entities.ok.length; i += 1) {
//         fields = entities.ok[i].fields;
//         let member = getUserInfo(fields);
//         if (entities.ok[i].eid.length >= 63) {
//           if((entities.ok[i].eid) == current_user_principal) {
//             isCurrentUserAlreadyGuildMember = true;
//           };
//           member.username = (entities.ok[i].eid).substring(0, 20) + ".....";
//           let reg_time: number = Number(member.joinDate) / (1000000);
//           let date = new Date(reg_time);
//           member.joinDate = months[(date.getMonth())] + ' ' + date.getFullYear();
//           member.guilds = (member.guilds).split(".")[0];
//           response.members.push(member);
//         };
//       };
//       if(!isCurrentUserAlreadyGuildMember) {
//         let guildCanister = await useGamingGuildsClient();
//         let res = await guildCanister.actor[guildCanister.methods.processAction]({
//           fields: [],
//           actionId: "join_guild"
//         });
//       };
//       return response;
//     },
//   });
// };

