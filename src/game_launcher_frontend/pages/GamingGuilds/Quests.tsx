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
import { useGetAllQuestsInfo, useGetUserVerifiedStatus } from "@/api/guilds";
import { useAuthContext } from "@/context/authContext";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import EmptyGameCard from "@/components/EmptyGameCard";
import { getPaginationPages } from "@/utils";
import { ArrowUpRightIcon } from "@heroicons/react/24/solid";
import Pagination from "@/components/Pagination";
import GuildCard from "@/components/GuildCard";
import Space from "@/components/ui/Space";
import { useGlobalContext } from "@/context/globalContext";

const Quests = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [pageNumber, setPageNumber] = React.useState(1);
    const { setIsOpenNavSidebar } = useGlobalContext();

    const { session } = useAuthContext();
    const { data: configs = [], isError, isLoading } = useGetAllQuestsInfo();
    const { data: isVerified = false } = useGetUserVerifiedStatus();

    const onVerifyEmailButtonClick = () => {
        if (!session) {
            return setIsOpenNavSidebar(true);
        }
        return navigate((navPaths.gaming_guilds_verification));
    };

    return (
        <>
            <div className="w-auto h-fit dark:text-black text-white flex float-right dark:bg-white bg-dark rounded-full text-center p-2 justify-around">
                <img src="/ogicon.png" className="w-8 h-8 mt-0.5" />
                <p className="text-lg p-1">OG Badge : {(isVerified) ? "Verified" : "Unverified"}</p>
                {
                    (isVerified) ? <></> : <Button
                        onClick={onVerifyEmailButtonClick}
                        className="py-2 px-3"
                        rightArrow
                        size="normal"
                    >
                        {t("gaming_guilds.items.item_3.verify_button")}
                    </Button>
                }
            </div>
            <Space />
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("gaming_guilds.Quests.loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    configs.length ? (
                        <>
                            <div className="">
                                {configs.map(({ title, image, rewards, countCompleted, gameUrl, mustHave, expiration, type, aid }) => (
                                    <div key={title}>
                                        <GuildCard
                                            aid={aid}
                                            title={title}
                                            image={image}
                                            rewards={rewards}
                                            countCompleted={countCompleted}
                                            gameUrl={gameUrl}
                                            mustHave={mustHave}
                                            expiration={expiration}
                                            type={type}
                                        />
                                    </div>
                                ))}
                                <EmptyGameCard length={configs.length} />
                            </div>

                            <Pagination
                                pageNumber={pageNumber}
                                setPageNumber={setPageNumber}
                                totalNumbers={getPaginationPages(configs.length, 9)}
                            />
                        </>
                    ) : (
                        <NoDataResult>{t("gaming_guilds.items.item_1.no_quest")}</NoDataResult>
                    )}
            </div>
        </>
    );
}

export default Quests;
