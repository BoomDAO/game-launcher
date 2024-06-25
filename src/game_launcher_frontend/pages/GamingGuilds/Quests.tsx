import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { navPaths } from "@/shared";
import H1 from "@/components/ui/H1";
import { useGetAllQuestsInfo, useGetUserVerifiedStatus, getConfigsData } from "@/api/guilds";
import { useAuthContext } from "@/context/authContext";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import EmptyGameCard from "@/components/EmptyGameCard";
import { getPaginationPages } from "@/utils";
import { ArrowUpRightIcon } from "@heroicons/react/24/solid";
import Pagination from "@/components/Pagination";
import GuildCard from "@/components/GuildCard";
import Space from "@/components/ui/Space";
import { useGlobalContext } from "@/context/globalContext";
import toast from "react-hot-toast";

const Quests = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [pageNumber, setPageNumber] = React.useState(1);
    const { setIsOpenNavSidebar } = useGlobalContext();

    const { session } = useAuthContext();
    const { data: configs = [], isError, isLoading } = useGetAllQuestsInfo();
    const { data: status = { emailVerified: false, phoneVerified: false } } = useGetUserVerifiedStatus();
    let req = [];
    req.push("airdrop_badge");
    req.push("phone_badge");
    const { data: badges = [], isLoading: loading } = getConfigsData(req);

    const doesQuestKindExist = (kind: string) => {
        for (let i = 0; i < configs.length; i += 1) {
            if (configs[i].kind == kind) {
                return true;
            }
        }
        return false;
    };

    const onVerifyEmailButtonClick = () => {
        if (!session) {
            return setIsOpenNavSidebar(true);
        }
        return navigate((navPaths.gaming_guilds_email_verification));
    };

    const onVerifyPhoneButtonClick = () => {
        if (!session) {
            return setIsOpenNavSidebar(true);
        }
        return navigate((navPaths.gaming_guilds_phone_verification));
    };

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

    return (
        <>
            <div className="flex w-auto h-fit float-right">
                <div className="dark:text-black text-white flex dark:bg-white bg-dark rounded-full text-center p-2 justify-around cursor-pointer" onClick={() => handleItemsOnClick(badges[0].name, badges[0].imageUrl, badges[0].description)}>
                    <img src={(!loading) ? badges[0].imageUrl : ""} alt="Airdrop Badge" className="w-8 h-8 mt-0.5" />
                    <p className="text-lg p-1">Airdrop Badge : {(status.emailVerified) ? "Verified" : "Unverified"}</p>
                </div>
                <div className="dark:text-black text-white flex dark:bg-white bg-dark rounded-full text-center p-2 justify-around ml-3 mr-2 cursor-pointer" onClick={() => handleItemsOnClick(badges[1].name, badges[1].imageUrl, badges[1].description)}>
                    <img src={(!loading) ? badges[1].imageUrl : ""} alt="Phone Badge" className="w-8 h-8 mt-0.5" />
                    <p className="text-lg p-1">Phone Badge : {(status.phoneVerified) ? "Verified" : "Unverified"}</p>
                </div>
            </div>
            <Space size="small" />
            <div className="flex gradient-bg-amber w-1/4 rounded-primary">
                <div className="pl-4 py-1 text-2xl font-bold">FEATURED</div>
                <div className="pl-1 pt-2.5 text-xxl font-bold">QUESTS</div>
            </div>
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("gaming_guilds.Quests.feature_loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    doesQuestKindExist("Featured") ? (
                        <>
                            <div className="grid grid-cols-2 gap-4">
                                {configs.map(({ title, image, rewards, countCompleted, gameUrl, mustHave, progress, expiration, type, aid, description, gamersImages, dailyQuest, kind }) => {
                                    return (kind == "Featured") ? <div key={aid}>
                                        <GuildCard
                                            aid={aid}
                                            title={title}
                                            description={description}
                                            image={image}
                                            rewards={rewards}
                                            countCompleted={countCompleted}
                                            gameUrl={gameUrl}
                                            mustHave={mustHave}
                                            progress={progress}
                                            expiration={expiration}
                                            type={type}
                                            gamersImages={gamersImages}
                                            dailyQuest={dailyQuest}
                                        />
                                    </div> : <></>
                                })}
                                <EmptyGameCard length={configs.length} />
                            </div>
                        </>
                    ) : (
                        <NoDataResult>{t("gaming_guilds.quest_kinds.feature_error")}</NoDataResult>
                    )}
            </div>
            <div className="flex gradient-bg-amber w-1/4 rounded-primary">
                <div className="pl-4 py-1 text-2xl font-bold">GAMING</div>
                <div className="pl-1 pt-2.5 text-xxl font-bold">QUESTS</div>
            </div>
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("gaming_guilds.Quests.gaming_loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    doesQuestKindExist("Gaming") ? (
                        <>
                            <div className="grid grid-cols-2 gap-4">
                                {configs.map(({ title, image, rewards, countCompleted, gameUrl, mustHave, progress, expiration, type, aid, description, gamersImages, dailyQuest, kind }) => {
                                    return (kind == "Gaming") ? <div key={aid}>
                                        <GuildCard
                                            aid={aid}
                                            title={title}
                                            description={description}
                                            image={image}
                                            rewards={rewards}
                                            countCompleted={countCompleted}
                                            gameUrl={gameUrl}
                                            mustHave={mustHave}
                                            progress={progress}
                                            expiration={expiration}
                                            type={type}
                                            gamersImages={gamersImages}
                                            dailyQuest={dailyQuest}
                                        />
                                    </div> : <></>
                                })}
                                <EmptyGameCard length={configs.length} />
                            </div>
                        </>
                    ) : (
                        <NoDataResult>{t("gaming_guilds.quest_kinds.gaming_error")}</NoDataResult>
                    )}
            </div>
            <div className="flex gradient-bg-amber w-1/4 rounded-primary">
                <div className="pl-4 py-1 text-2xl font-bold">SOCIAL</div>
                <div className="pl-1 pt-2.5 text-xxl font-bold">QUESTS</div>
            </div>
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("gaming_guilds.Quests.social_loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    doesQuestKindExist("Social") ? (
                        <>
                            <div className="grid grid-cols-2 gap-4">
                                {configs.map(({ title, image, rewards, countCompleted, gameUrl, mustHave, progress, expiration, type, aid, description, gamersImages, dailyQuest, kind }) => {
                                    return (kind == "Social") ? <div key={aid}>
                                        <GuildCard
                                            aid={aid}
                                            title={title}
                                            description={description}
                                            image={image}
                                            rewards={rewards}
                                            countCompleted={countCompleted}
                                            gameUrl={gameUrl}
                                            mustHave={mustHave}
                                            progress={progress}
                                            expiration={expiration}
                                            type={type}
                                            gamersImages={gamersImages}
                                            dailyQuest={dailyQuest}
                                        />
                                    </div> : <></>
                                })}
                                <EmptyGameCard length={configs.length} />
                            </div>
                        </>
                    ) : (
                        <NoDataResult>{t("gaming_guilds.quest_kinds.social_error")}</NoDataResult>
                    )}
            </div>
        </>
    );
}

export default Quests;
