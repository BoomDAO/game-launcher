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
import { useClaimReward } from "@/api/guilds";
import toast from "react-hot-toast";

interface CardProps {
  aid: string;
  title: string;
  image: string;
  rewards: { name: string; imageUrl: string; value: string; description: string; }[];
  countCompleted: string;
  gameUrl: string;
  mustHave: { name: string; imageUrl: string; quantity: string; description: string; }[],
  expiration: string;
  onClick?: () => void;
  type: "Completed" | "Incomplete" | "Claimed";
}

const GuildCard = ({
  aid,
  title,
  image,
  rewards,
  countCompleted,
  gameUrl,
  mustHave,
  expiration,
  onClick,
  type,
}: CardProps) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const session = useAuthContext();
  const { setIsOpenNavSidebar } = useGlobalContext();

  const { mutate, data, isLoading } = useClaimReward();

  const handleItemsOnClick = (name : string, imageUrl : string, description : string) => {
    toast.custom((t) => (
      <div className="w-1/2 rounded-3xl mb-7 p-0.5 gradient-bg mt-40 backdrop-blur-sm">
        <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
          <div className="flex justify-center mt-5">
            <img src={imageUrl} className="mx-2 h-12" />
            <p className="pt-2 pl-3 text-xl">{name}</p>
          </div>
          <p className="text-base pt-3 pb-6">{description}</p>
          <Button onClick={() => toast.remove()} className="float-right mb-3">Close</Button>
        </div>
      </div>
    ), {
      position: 'top-center'
    });
  };

  return (
    <Center>
      {
        (type === "Completed") ?
          <div className="w-full rounded-3xl mb-7 p-0.5 gradient-bg-green">
            <div className="flex h-full w-full dark:bg-dark bg-white rounded-3xl p-4 dark:text-white text-black">
              <div className="w-4/12">
                <img className="w-full h-60 object-cover rounded-3xl" src={image} />
              </div>
              <div className="w-8/12 ml-20">
                <div className="text-lg">{title}</div>
                {mustHave.length ?
                  <div className="flex mt-1">
                    <div className="font-semibold mt-1">Must Have : </div>
                    <div className="flex">
                      {
                        mustHave.map(({ name, imageUrl, quantity, description }) => (
                          <div className="flex pl-2 cursor-pointer" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            <img src={imageUrl} className="mx-2 h-8" />
                            {(quantity != "") ? <div className="mt-1 mr-1">{quantity}</div> : <></>}
                            <div className="mt-1">{name}</div>
                          </div>
                        ))
                      }
                    </div>
                  </div> :
                  <div className="flex mt-1">
                    <div className="font-semibold mt-1">Must Have : </div>
                  </div>}
                {rewards.length ?
                  <div className="flex mt-1">
                    <div className="font-semibold mt-1">Rewards : </div>
                    <div className="flex">
                      {
                        rewards.map(({ name, imageUrl, value, description }) => (
                          <div className="flex pl-2 cursor-pointer" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            <img src={imageUrl} className="mx-2 h-8" />
                            {(value != "") ? <div className="mt-1 mr-1">{value}</div> : <></>}
                            <div className="mt-1">{name}</div>
                          </div>
                        ))
                      }
                    </div>
                  </div> : <div className="flex mt-1">
                    <div className="font-semibold mt-1">Must Have : </div>
                  </div>}
                <div className="mt-10 text-lg font-extralight">Gamers who have completed this quest : <p className="gradient-text text-2xl font-normal">{countCompleted}</p></div>
                <div className="text-lg font-extralight">Quest Expiration : <p className="gradient-text text-2xl font-normal">{expiration}</p></div>
                <div className="w-full flex mt-1">
                  <div className="text-lg">Your quest status : <p className="gradient-text text-xl font-normal">{type}</p></div>
                  <Button className="h-fit order-2 ml-auto gradient-bg-green" onClick={() => { if (session.session == null) return setIsOpenNavSidebar(true); mutate({ aid, rewards }); }} isLoading={isLoading}>{t("gaming_guilds.Quests.complete_button")}</Button>
                </div>
              </div>
            </div>
          </div>
          : (type === "Incomplete") ?
            <div className="w-full flex dark:text-white border-stone-400 text-black border-2 rounded-3xl mb-7 p-4">
              <div className="w-4/12">
                <img className="w-full h-60 rounded-3xl object-cover" src={image} />
              </div>
              <div className="w-8/12 ml-20">
                <div className="text-lg">{title}</div>
                {mustHave.length ?
                  <div className="flex mt-1">
                    <div className="font-semibold mt-1">Must Have : </div>
                    <div className="flex">
                      {
                        mustHave.map(({ name, imageUrl, quantity, description }) => (
                          <div className="flex pl-2 cursor-pointer" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            <img src={imageUrl} className="mx-2 h-8" />
                            {(quantity != "") ? <div className="mt-1 mr-1">{quantity}</div> : <></>}
                            <div className="mt-1">{name}</div>
                          </div>
                        ))
                      }
                    </div>
                  </div> : <div className="flex mt-1">
                    <div className="font-semibold mt-1">Must Have : </div>
                  </div>}
                {rewards.length ?
                  <div className="flex mt-1">
                    <div className="font-semibold mt-1">Rewards : </div>
                    <div className="flex">
                      {
                        rewards.map(({ name, imageUrl, value, description }) => (
                          <div className="flex pl-2 cursor-pointer" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                            <img src={imageUrl} className="mx-2 h-8" />
                            {(value != "") ? <div className="mt-1 mr-1">{value}</div> : <></>}
                            <div className="mt-1">{name}</div>
                          </div>
                        ))
                      }
                    </div>
                  </div> : <div className="flex mt-1">
                    <div className="font-semibold mt-1">Must Have : </div>
                  </div>}
                <div className="mt-10 text-lg font-extralight">Gamers who have completed this quest : <p className="gradient-text text-2xl font-normal">{countCompleted}</p></div>
                <div className="text-lg font-extralight">Quest Expiration : <p className="gradient-text text-2xl font-normal">{expiration}</p></div>
                <div className="w-full flex mt-1">
                  <div className="text-lg">Your quest status : <p className="gradient-text text-xl font-normal">{type}</p></div>
                  <Button className="h-fit order-2 ml-auto" onClick={() => { if (session.session == null) return setIsOpenNavSidebar(true); (window.open(gameUrl, "_blank")); }}>{t("gaming_guilds.Quests.incomplete_button")}</Button>
                </div>
              </div>
            </div> :
            <div className="w-full rounded-3xl mb-7 p-0.5 gradient-bg-grey">
              <div className="flex h-full w-full dark:bg-dark bg-white rounded-3xl p-4 dark:text-white text-black">
                <div className="w-4/12">
                  <img className="w-full h-60 rounded-3xl object-cover" src={image} />
                </div>
                <div className="w-8/12 ml-20">
                  <div className="text-lg">{title}</div>
                  {mustHave.length ?
                    <div className="flex mt-1">
                      <div className="font-semibold mt-1">Must Have : </div>
                      <div className="flex">
                        {
                          mustHave.map(({ name, imageUrl, quantity, description }) => (
                            <div className="flex pl-2 cursor-pointer" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              <img src={imageUrl} className="mx-2 h-8" />
                              {(quantity != "") ? <div className="mt-1 mr-1">{quantity}</div> : <></>}
                              <div className="mt-1">{name}</div>
                            </div>
                          ))
                        }
                      </div>
                    </div> : <div className="flex mt-1">
                      <div className="font-semibold mt-1">Must Have : </div>
                    </div>}
                  {rewards.length ?
                    <div className="flex mt-1">
                      <div className="font-semibold mt-1">Rewards : </div>
                      <div className="flex">
                        {
                          rewards.map(({ name, imageUrl, value, description }) => (
                            <div className="flex pl-2 cursor-pointer" key={imageUrl} onClick={() => handleItemsOnClick(name, imageUrl, description)}>
                              <img src={imageUrl} className="mx-2 h-8" />
                              {(value != "") ? <div className="mt-1 mr-1">{value}</div> : <></>}
                              <div className="mt-1">{name}</div>
                            </div>
                          ))
                        }
                      </div>
                    </div> : <div className="flex mt-1">
                      <div className="font-semibold mt-1">Must Have : </div>
                    </div>}
                  <div className="mt-10 text-lg font-extralight">Gamers who have completed this quest : <p className="gradient-text text-2xl font-normal">{countCompleted}</p></div>
                  <div className="text-lg font-extralight">Quest Expiration : <p className="gradient-text text-2xl font-normal">{expiration}</p></div>
                  <div className="w-full flex mt-1">
                    <div className="text-lg">Your quest status : <p className="gradient-text text-xl font-normal">{type}</p></div>
                    <Button className="h-fit order-2 ml-auto gradient-bg-grey" onClick={() => { if (session.session == null) return setIsOpenNavSidebar(true); }}>{t("gaming_guilds.Quests.claimed_button")}</Button>
                  </div>
                </div>
              </div>
            </div>
      }
    </Center>
  );
};

export default GuildCard;
