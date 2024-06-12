import React from "react";
import { useTranslation } from "react-i18next";
import { NoSymbolIcon } from "@heroicons/react/20/solid";
import Center from "./ui/Center";
import Divider from "./ui/Divider";
import Loader from "./ui/Loader";
import Button from "./ui/Button";
import { useNavigate } from "react-router-dom";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import { useClaimReward, useGetUserCompleteDetail, useGetUserProfileDetail } from "@/api/guilds";
import toast from "react-hot-toast";
import { cx } from "@/utils";
import { UserCompleteDetail, UserProfile } from "@/types";
import { useGetTexts } from "@/api/common";
import axios from "axios";
import ENV from "../../../env.json";
import { navPaths } from "@/shared";

interface CardProps {
  aid: string;
  title: string;
  description: string;
  image: string;
  rewards: { name: string; imageUrl: string; value: string; description: string; }[];
  countCompleted: string;
  gameUrl: string;
  mustHave: { name: string; imageUrl: string; quantity: string; description: string; }[],
  progress: { name: string; imageUrl: string; quantity: string; description: string; }[],
  expiration: string;
  onClick?: () => void;
  type: "Completed" | "Incomplete" | "Claimed";
  gamersImages: string[];
  dailyQuest: {
    isDailyQuest: boolean;
    resetsIn: string;
  };
}

const GuildCard = ({
  aid,
  title,
  description,
  image,
  rewards,
  countCompleted,
  gameUrl,
  mustHave,
  progress,
  expiration,
  onClick,
  type,
  gamersImages,
  dailyQuest
}: CardProps) => {
  const [iframe, setIframe] = React.useState(false);
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { session } = useAuthContext();
  const { setIsOpenNavSidebar } = useGlobalContext();
  const { data: userProfile, isLoading: isProfileLoading } = useGetUserCompleteDetail();
  const { mutate, data, isLoading, isSuccess } = useClaimReward();
  const { data: text, isLoading: isTextLoading } = useGetTexts();

  const handleItemsOnClick = (name: string, imageUrl: string, description: string) => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <div className="flex justify-center mt-5">
              <img src={imageUrl} className="mx-2 h-12" />
              <p className="pt-2 pl-3 text-xl">{name}</p>
            </div>
            <p className="text-base pt-3 pb-6">{description}</p>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  const checkUserDetailsExist = (detail: UserCompleteDetail | undefined) => {
    if (detail == undefined) {
      return false;
    } else if (detail.uid.substring(0, 10) == detail.username.substring(0, 10) || detail.image == "/usericon.png") {
      return false;
    } else return true;
  };

  const checkTwitterQuestAndUserTwitterDetails = (detail: UserCompleteDetail | undefined) => {
    if (aid.includes("twitter") && !aid.includes("twitter_login")) {
      if (detail == undefined) {
        return 1;
      } else if (detail.twitter.username == "" || detail.twitter.id == "") {
        return 1;
      } else return 2;
    } else {
      return 0;
    }
  };

  const checkTwitterLoginQuestAndUserTwitterDetails = (detail: UserCompleteDetail | undefined) => {
    if (aid.includes("twitter_login")) {
      if (detail == undefined) {
        return false;
      } else if (detail.twitter.username == "" || detail.twitter.id == "") {
        return false;
      } else return true;
    } else {
      return true;
    }
  };

  const checkDiscordQuestAndUserDiscordDetails = (detail: UserCompleteDetail | undefined) => {
    if (aid.includes("discord") && !aid.includes("discord_login")) {
      if (detail == undefined) {
        return 1;
      } else if (detail.discord.username == "") {
        return 1;
      } else return 2;
    } else {
      return 0;
    }
  };

  const checkDiscordLoginQuestAndUserDiscordDetails = (detail: UserCompleteDetail | undefined) => {
    if (aid.includes("discord_login")) {
      if (detail == undefined) {
        return false;
      } else if (detail.discord.username == "") {
        return false;
      } else return true;
    } else {
      return true;
    }
  };

  const handleUserDetailsNotExist = () => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <div className="text-center">
              <p className="text-xl font-semibold">SET UP YOUR ACCOUNT</p>
              {
                (isTextLoading) ? <Loader className="w-10 h-10"></Loader> : <p className="mt-2">{text.guild_card.setup_detail}</p>
              }
              {
                (isTextLoading) ? <Loader className="w-10 h-10"></Loader> : <p className="mt-4"><b>Warning</b> : {text.guild_card.setup_warning}</p>
              }
              <Button onClick={() => {
                let current_url = new URL(window.location.href);
                navigate("/profile/picture");
                toast.remove();
              }} className="m-auto mt-4">PROCEED</Button>
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  const handleUserDiscordDetailsNotExist = () => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <div className="text-center">
              <p className="text-xl font-semibold">Connect your Discord account</p>
              <p>You have not connected a Discord account to your BOOM account. Press the button below to connect your Discord account. BOT accounts will not be eligible to complete quests.</p>
              <Button onClick={() => {
                let uid = session?.address;
                window.location.href = "https://sy6ok-pyaaa-aaaak-qig4a-cai.icp0.io/?user_id=" + uid;
                toast.remove();
              }} className="m-auto mt-4">PROCEED</Button>
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  const handleUserTwitterDetailsNotExist = () => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <div className="text-center">
              <p className="text-xl font-semibold">Connect your Twitter account</p>
              <p>You have not connected a Twitter account to your BOOM account. Press the button below to connect your Twitter account. Fake Twitter accounts will not be eligible to complete quests.</p>
              <Button onClick={() => {
                let uid = session?.address;
                window.location.href = "https://boom-dao-twitter-auth.up.railway.app/?userId=" + uid;
                toast.remove();
              }} className="m-auto mt-4">PROCEED</Button>
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  const handleUserTwitterDetailsExist = () => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <div className="text-center">
              <p className="text-xl font-semibold">Make a Tweet about BOOM DAO</p>
              <p>Make a tweet about BOOM DAO and dont forget to use hashtag #BOOMDAO</p>
              <Button onClick={async () => {
                let current_user_principal = ((session?.identity?.getPrincipal())?.toString() != undefined) ? (session?.identity?.getPrincipal())?.toString() : "";
                let url = "https://twitter.com/intent/post?text=I%20joined%20the%20BOOM%20Gaming%20Guilds%20and%20I%20received%20100%20BOOM%20tokens%20for%20doing%20quests%20in%20%24ICP%20games!%0D%0A%0D%0A%F0%9F%91%89%20guilds.boomdao.xyz%2F%20%F0%9F%91%88%0D%0A%0D%0ASign%20up%20now%20to%20earn%20tokens%20%26%20memecoins!%F0%9F%8F%86%0D%0A%0D%0A%23BOOMDAO%0D%0A%0D%0AID%3A%20" + session?.address;
                window.open(url, "_blank");
                await axios.post(ENV.GRANT_TWITTER_QUEST_ENTITY_URL, {}, {
                  headers: {
                    'key': ENV.KEY,
                    'uid': current_user_principal,
                  },
                  baseURL: ENV.BASE_URL
                });
                window.location.reload();
              }} className="m-auto mt-4">TWEET</Button>
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  const handleUserDiscordDetailsExist = () => {
    toast.custom((t) => (
      <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
        <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
          <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
            <div className="text-center">
              <p className="text-xl font-semibold">Greet BOOM Gaming Guild in our Discord</p>
              <p>Make a Post about BOOM DAO and BOOM Gaming Guild and dont forget to use "BOOM DAO" in your Post.</p>
              <Button onClick={async () => {
                let url = "https://discord.com/invite/Tnja22wy";
                window.open(url, "_blank");
              }} className="m-auto mt-4">POST</Button>
            </div>
            <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
          </div>
        </div>
      </div>
    ));
  };

  return (
    <Center>
      {
        (type === "Completed") ?
          <div className={cx(
            "w-full rounded-3xl mb-3 p-0.5",
            !isSuccess ? "gradient-bg-green" : "gradient-bg-grey"
          )}>
            <div className="flex h-64 w-full dark:bg-dark bg-white rounded-3xl p-4 dark:text-white text-black">
              <div className="w-4/12 relative">
                <img className="w-full h-56  object-cover rounded-3xl" src={image} />
                <div className="absolute bottom-3 text-center w-full">{(dailyQuest.isDailyQuest) ? <p className="font-semibold text-base text-white bg-orange-400 mx-3 rounded-3xl">Daily Quest</p> : <p className="font-semibold text-xs invisible">Daily Quest</p>}</div>
              </div>
              <div className="w-8/12 ml-4">
                <div className="w-full flex">
                  <div className="text-xl font-semibold mt-1">{title}</div>
                  <Button className="order-2 ml-auto gradient-bg-green h-8" onClick={() => {
                    if (session == null) return setIsOpenNavSidebar(true);
                    if (!checkUserDetailsExist(userProfile)) return handleUserDetailsNotExist();
                    if (!checkDiscordLoginQuestAndUserDiscordDetails(userProfile)) {
                      handleUserDiscordDetailsNotExist();
                    } else if (!checkTwitterLoginQuestAndUserTwitterDetails(userProfile)) {
                      handleUserTwitterDetailsNotExist();
                    }
                    mutate({ aid, rewards });
                  }} isLoading={isLoading} isClaimSuccess={isSuccess}>{(aid.includes("twitter") && !aid.includes("twitter_login")) ? t("gaming_guilds.Quests.twitter_quest_button") : t("gaming_guilds.Quests.complete_button")}</Button>
                </div>
                <div className="text-sm font-light mt-2">{description}</div>
                {
                  (progress.length) ?
                    <>
                      {
                        progress.map(({ name, imageUrl, quantity, description }) => (
                          <div className="flex w-2/3 h-6 bg-gray-300/50 rounded-3xl mt-4 relative" key={imageUrl}>
                            <div className="flex cursor-pointer text-sm z-10 absolute pl-3" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              {(quantity != "") ? <div className="mt-0.5">{quantity}</div> : <></>}
                              <div className="mt-0.5 ml-1">{name}</div>
                            </div>
                            <div className="yellow-gradient-bg h-6 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(quantity.split("/")[0]) / Number(quantity.split("/")[1])) >= 100) ? 100 : (100 * Number(quantity.split("/")[0]) / Number(quantity.split("/")[1]))}%` }}></div>
                          </div>
                        ))
                      }
                    </>
                    : <div className="flex w-2/3 h-6 bg-gray-300/50 rounded-3xl mt-4 relative invisible">
                      {
                        progress.map(({ name, imageUrl, quantity, description }) => (
                          <div className="flex cursor-pointer text-sm z-10 absolute pl-3" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            {(quantity != "") ? <div className="mt-0.5">{quantity}</div> : <></>}
                            <div className="mt-0.5 ml-1">{name}</div>
                          </div>
                        ))
                      }
                      <div className="w-2/3 yellow-gradient-bg h-6 rounded-3xl absolute z-5"></div>
                    </div>
                }
                {mustHave.length ?
                  <div className="flex mt-8">
                    <div className="text-sm font-semibold">Eligibility: </div>
                    <div className="flex">
                      {
                        mustHave.map(({ name, imageUrl, quantity, description }) => (
                          <div className="flex cursor-pointer text-xs" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            <img src={imageUrl} className="ml-1 h-6" />
                            {(quantity != "") ? <div className="mt-1 mr-1 text-xs ml-0.5">{quantity}</div> : <></>}
                            <div className="mt-1">{name}</div>
                          </div>
                        ))
                      }
                    </div>
                  </div> :
                  <div className="flex mt-8">
                    <div className="text-sm font-semibold invisible">Eligibility: </div>
                  </div>}
                {rewards.length ?
                  <div className="flex mt-0.5">
                    <div className="text-sm font-semibold">Rewards : </div>
                    <div className="flex">
                      {
                        rewards.map(({ name, imageUrl, value, description }) => (
                          <div className="flex cursor-pointer text-xs" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            <img src={imageUrl} className="ml-1 h-6" />
                            {(value != "") ? <div className="mt-1 mr-1 text-xs ml-0.5">{value}</div> : <></>}
                            <div className="mt-1 text-xs">{name}</div>
                          </div>
                        ))
                      }
                    </div>
                  </div> : <div className="flex mt-0.5">
                    <div className="text-sm font-semibold">Rewards : </div>
                  </div>}
                <div className="mt-5">
                  <div className="w-full flex justify-between pr-5">
                    {(expiration == "0") ? <div className="w-1/2"></div> : (expiration[0] == "-") ? <div className="text-sm font-semibold rounded-2xl"><p className="gradient-text">Ends in {expiration.split("-")[1]}</p></div> : <div className="text-sm font-semibold rounded-2xl"><p className="gradient-text pt-0.5">Starts in {(expiration).split("+")[1]}</p></div>}
                    {(expiration[0] != "+") ?
                      <div className="flex">
                        {
                          gamersImages.length ?
                            <div className="flex">
                              <div className="flex">
                                {
                                  gamersImages.map((image, index) => (<img key={index} src={image} className="w-6 h-6 rounded-2xl bg-white" />))
                                }
                              </div>
                              <p className="ml-0.5">+{(countCompleted == "0") ? 1 : countCompleted}</p>
                            </div> : <></>
                        }
                      </div> : <></>}
                  </div>
                </div>
              </div>
            </div>
          </div>
          : (type === "Incomplete") ?
            <div className="w-full rounded-3xl mb-3 p-0.5 gradient-bg">
              <div className="flex h-64 w-full dark:bg-dark bg-white rounded-3xl p-4 dark:text-white text-black">
                <div className="w-4/12 relative">
                  <img className="w-full h-56 object-cover rounded-3xl" src={image} />
                  <div className="absolute bottom-3 text-center w-full">{(dailyQuest.isDailyQuest) ? <p className="font-semibold text-base text-white bg-orange-400 mx-3 rounded-3xl">Daily Quest</p> : <p className="font-semibold text-xs invisible">Daily Quest</p>}</div>
                </div>
                <div className="w-8/12 ml-4">
                  <div className="w-full flex">
                    <div className="text-xl font-semibold mt-1">{title}</div>
                    {
                      (expiration[0] == "+") ?
                        <></> :
                        <Button className="h-8 order-2 ml-auto" isLoading={isProfileLoading} onClick={() => {
                          if (session == null) {
                            return setIsOpenNavSidebar(true);
                          };
                          if (!checkUserDetailsExist(userProfile)) return handleUserDetailsNotExist();
                          if (checkTwitterQuestAndUserTwitterDetails(userProfile) == 1) {
                            return handleUserTwitterDetailsNotExist();
                          } else if (checkTwitterQuestAndUserTwitterDetails(userProfile) == 2) {
                            return handleUserTwitterDetailsExist();
                          }
                          if (checkDiscordQuestAndUserDiscordDetails(userProfile) == 1) {
                            return handleUserDiscordDetailsNotExist();
                          } else if (checkDiscordQuestAndUserDiscordDetails(userProfile) == 2) {
                            return handleUserDiscordDetailsExist();
                          }
                          if (!checkDiscordLoginQuestAndUserDiscordDetails(userProfile)) {
                            return handleUserDiscordDetailsNotExist();
                          } else if (!checkTwitterLoginQuestAndUserTwitterDetails(userProfile)) {
                            return handleUserTwitterDetailsNotExist();
                          }
                          let new_url = new URL(gameUrl);
                          let current_url = new URL(window.location.href);
                          if (new_url.origin == current_url.origin) {
                            navigate(new_url.pathname);
                          } else {
                            let url = gameUrl.substring(8);
                            navigate(navPaths.game_iframe + "/" + url.split(".")[0]);
                          };
                        }}>{t("gaming_guilds.Quests.incomplete_button")}</Button>
                    }
                  </div>
                  <div className="text-sm font-light mt-2">{description}</div>
                  {
                    (progress.length) ?
                      <>
                        {
                          progress.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex w-2/3 h-6 bg-gray-300/50 rounded-3xl mt-4 relative" key={imageUrl}>
                              <div className="flex cursor-pointer text-sm z-10 absolute pl-3" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                                {(quantity != "") ? <div className="mt-0.5">{quantity}</div> : <></>}
                                <div className="mt-0.5 ml-1">{name}</div>
                              </div>
                              <div className="yellow-gradient-bg h-6 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(quantity.split("/")[0]) / Number(quantity.split("/")[1])) >= 100) ? 100 : (100 * Number(quantity.split("/")[0]) / Number(quantity.split("/")[1]))}%` }}></div>
                            </div>
                          ))
                        }
                      </>
                      : <div className="flex w-2/3 h-6 bg-gray-300/50 rounded-3xl mt-4 relative invisible">
                        {
                          progress.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex cursor-pointer text-sm z-10 absolute pl-3" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              {(quantity != "") ? <div className="mt-0.5">{quantity}</div> : <></>}
                              <div className="mt-0.5 ml-1">{name}</div>
                            </div>
                          ))
                        }
                        <div className="w-2/3 yellow-gradient-bg h-6 rounded-3xl absolute z-5"></div>
                      </div>
                  }
                  {mustHave.length ?
                    <div className="flex mt-8">
                      <div className="text-sm font-semibold">Eligibility: </div>
                      <div className="flex">
                        {
                          mustHave.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex cursor-pointer text-xs" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              <img src={imageUrl} className="ml-1 h-6" />
                              {(quantity != "") ? <div className="mt-1 mr-1 text-xs ml-0.5">{quantity}</div> : <></>}
                              <div className="mt-1">{name}</div>
                            </div>
                          ))
                        }
                      </div>
                    </div> :
                    <div className="flex mt-8">
                      <div className="text-sm font-semibold invisible">Eligibility: </div>
                    </div>}
                  {rewards.length ?
                    <div className="flex mt-0.5">
                      <div className="text-sm font-semibold">Rewards : </div>
                      <div className="flex">
                        {
                          rewards.map(({ name, imageUrl, value, description }) => (
                            <div className="flex cursor-pointer text-xs" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              <img src={imageUrl} className="ml-1 h-6" />
                              {(value != "") ? <div className="mt-1 mr-1 text-xs ml-0.5">{value}</div> : <></>}
                              <div className="mt-1 text-xs">{name}</div>
                            </div>
                          ))
                        }
                      </div>
                    </div> : <div className="flex mt-0.5">
                      <div className="text-sm font-semibold">Rewards : </div>
                    </div>}
                  <div className="mt-5">
                    <div className="w-full flex justify-between pr-5">
                      {(expiration == "0") ? <div className="w-1/2"></div> : (expiration[0] == "-") ? <div className="text-sm font-semibold rounded-2xl"><p className="gradient-text">Ends in {expiration.split("-")[1]}</p></div> : <div className="text-sm font-semibold rounded-2xl"><p className="gradient-text pt-0.5">Starts in {(expiration).split("+")[1]}</p></div>}

                      {(expiration[0] != "+") ? <div className="flex">
                        {
                          gamersImages.length ?
                            <div className="flex">
                              <div className="flex">
                                {
                                  gamersImages.map((image, index) => (<img key={index} src={image} className="w-6 h-6 rounded-2xl bg-white" />))
                                }
                              </div>
                              <p className="ml-0.5">+{(countCompleted == "0") ? 1 : countCompleted}</p>
                            </div> : <></>
                        }
                      </div> : <></>}
                    </div>
                  </div>
                </div>
              </div>
            </div> :
            <div className="mb-3 p-0.5 gradient-bg-grey w-full rounded-3xl">
              <div className="flex h-64 w-full dark:bg-dark bg-white rounded-3xl p-4 dark:text-white text-black">
                <div className="w-4/12 relative">
                  <img className="w-full h-56  object-cover rounded-3xl" src={image} />
                  <div className="absolute bottom-3 text-center w-full">{(dailyQuest.isDailyQuest) ? <p className="font-semibold text-base text-white bg-orange-400 mx-3 rounded-3xl">Daily Quest</p> : <p className="font-semibold text-xs invisible">Daily Quest</p>}</div>
                </div>
                <div className="w-8/12 ml-4">
                  <div className="w-full flex">
                    <div className="text-xl font-semibold mt-1">{title}</div>
                    <Button className="order-2 ml-auto gradient-bg-grey h-8 cursor-default" onClick={() => {
                      if (session == null) return setIsOpenNavSidebar(true);
                      if (!checkUserDetailsExist(userProfile)) return handleUserDetailsNotExist();
                      if (checkTwitterQuestAndUserTwitterDetails(userProfile) == 1) {
                        return handleUserTwitterDetailsNotExist();
                      } else if (checkTwitterQuestAndUserTwitterDetails(userProfile) == 2) {
                        return handleUserTwitterDetailsExist();
                      }
                      if (checkDiscordQuestAndUserDiscordDetails(userProfile) == 1) {
                        return handleUserDiscordDetailsNotExist();
                      } else if (checkDiscordQuestAndUserDiscordDetails(userProfile) == 2) {
                        return handleUserDiscordDetailsExist();
                      }
                      if (!checkDiscordLoginQuestAndUserDiscordDetails(userProfile)) {
                        handleUserDiscordDetailsNotExist();
                      } else if (!checkTwitterLoginQuestAndUserTwitterDetails(userProfile)) {
                        handleUserTwitterDetailsNotExist();
                      }
                    }}>{t("gaming_guilds.Quests.claimed_button")}</Button>
                  </div>
                  <div className="text-sm font-light mt-2">{description}</div>
                  {
                    (progress.length) ?
                      <>
                        {
                          progress.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex w-2/3 h-6 bg-gray-300/50 rounded-3xl mt-4 relative" key={imageUrl}>
                              <div className="flex cursor-pointer text-sm z-10 absolute pl-3" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                                {(quantity != "") ? <div className="mt-0.5">{quantity}</div> : <></>}
                                <div className="mt-0.5 ml-1">{name}</div>
                              </div>
                              <div className="yellow-gradient-bg h-6 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(quantity.split("/")[0]) / Number(quantity.split("/")[1])) >= 100) ? 100 : (100 * Number(quantity.split("/")[0]) / Number(quantity.split("/")[1]))}%` }}></div>
                            </div>
                          ))
                        }
                      </>
                      : <div className="flex w-2/3 h-6 bg-gray-300/50 rounded-3xl mt-4 relative invisible">
                        {
                          progress.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex cursor-pointer text-sm z-10 absolute pl-3" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              {(quantity != "") ? <div className="mt-0.5">{quantity}</div> : <></>}
                              <div className="mt-0.5 ml-1">{name}</div>
                            </div>
                          ))
                        }
                        <div className="w-2/3 yellow-gradient-bg h-6 rounded-3xl absolute z-5"></div>
                      </div>
                  }
                  {mustHave.length ?
                    <div className="flex mt-8">
                      <div className="text-sm font-semibold">Eligibility: </div>
                      <div className="flex">
                        {
                          mustHave.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex cursor-pointer text-xs" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              <img src={imageUrl} className="ml-1 h-6" />
                              {(quantity != "") ? <div className="mt-1 mr-1 text-xs ml-0.5">{quantity}</div> : <></>}
                              <div className="mt-1">{name}</div>
                            </div>
                          ))
                        }
                      </div>
                    </div> :
                    <div className="flex mt-8">
                      <div className="text-sm font-semibold invisible">Eligibility: </div>
                    </div>}
                  {rewards.length ?
                    <div className="flex mt-0.5">
                      <div className="text-sm font-semibold">Rewards : </div>
                      <div className="flex">
                        {
                          rewards.map(({ name, imageUrl, value, description }) => (
                            <div className="flex cursor-pointer text-xs" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              <img src={imageUrl} className="ml-1 h-6" />
                              {(value != "") ? <div className="mt-1 mr-1 text-xs ml-0.5">{value}</div> : <></>}
                              <div className="mt-1 text-xs">{name}</div>
                            </div>
                          ))
                        }
                      </div>
                    </div> : <div className="flex mt-0.5">
                      <div className="text-sm font-semibold">Rewards : </div>
                    </div>}
                  <div className="mt-5">
                    <div className="w-full flex justify-between pr-5">
                      {(expiration == "0") ? <div className="w-1/2">{(dailyQuest.isDailyQuest) ? <p className="gradient-text text-sm font-semibold">Resets in {dailyQuest.resetsIn}</p> : <></>}</div> : (expiration[0] == "-") ? <div className="text-sm font-semibold rounded-2xl"><p className="gradient-text">Ends in {expiration.split("-")[1]}</p></div> : <div className="text-sm font-semibold rounded-2xl"><p className="gradient-text pt-0.5">Starts in {(expiration).split("+")[1]}</p></div>}
                      {(expiration[0] != "+") ?
                        <div className="flex">
                          {
                            gamersImages.length ?
                              <div className="flex">
                                <div className="flex">
                                  {
                                    gamersImages.map((image, index) => (<img key={index} src={image} className="w-6 h-6 rounded-2xl bg-white" />))
                                  }
                                </div>
                                <p className="ml-0.5">+{(countCompleted == "0") ? 1 : countCompleted}</p>
                              </div> : <></>
                          }
                        </div> : <></>}
                    </div>
                  </div>
                </div>
              </div>
            </div>
      }
    </Center>
  );
};

export default GuildCard;
