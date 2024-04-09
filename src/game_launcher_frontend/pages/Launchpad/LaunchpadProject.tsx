import { useGetAllTokensInfo } from "@/api/launchpad";
import EmptyGameCard from "@/components/EmptyGameCard";
import LaunchCard from "@/components/LaunchCard";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import VerticalTabs from "@/components/VerticalTabs";
import Divider from "@/components/ui/Divider";
import { useGlobalContext } from "@/context/globalContext";
import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";

const LaunchpadProject = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { setIsOpenNavSidebar } = useGlobalContext();
    const { data: launchCards, isLoading, isError } = useGetAllTokensInfo();

    const [activeTab, setActiveTab] = React.useState(1);
    const tabItems = [
        { id: 1, name: "About Project" },
        { id: 2, name: "Token Allocations" },
        { id: 3, name: "FAQS" }
    ];

    return (
        <>
            <div>
                <div className="mt-5">
                    <div className="">
                        {isLoading ? (
                            <LoadingResult>{t("launchpad.home.loading")}</LoadingResult>
                        ) : isError ? (
                            <ErrorResult>{t("error")}</ErrorResult>
                        ) :
                            launchCards.length ? (
                                <>
                                    <div className="">
                                        {launchCards.map(({ id, project, swap, token }) => (
                                            (swap.status) ?
                                                <div key={id}>
                                                    <LaunchCard
                                                        id={id}
                                                        token={token}
                                                        project={project}
                                                        swap={swap}
                                                    />
                                                    <div className="flex mt-20 w-full mb-10">
                                                        <div className="w-1/4">
                                                            <div className=""><img src={project.creatorImageUrl} className="w-20 rounded-primary" /></div>
                                                            <div>{project.creator}</div>
                                                        </div>
                                                        <div className="w-3/4 pt-10 text-sm">
                                                            {project.creatorAbout}
                                                        </div>
                                                    </div>
                                                    <Divider />
                                                    <div className="flex w-full">
                                                        <div className="w-1/4 mt-10"><VerticalTabs tabs={tabItems} active={activeTab} setActive={setActiveTab} /></div>
                                                        <div className="w-3/4 mt-12 text-sm">
                                                            {activeTab === 1 && (
                                                                <div className="">
                                                                    {project.description}
                                                                </div>
                                                            )}
                                                            {activeTab === 2 && (
                                                                <div className="">
                                                                    Token Allocations
                                                                </div>
                                                            )}
                                                            {activeTab === 3 && (
                                                                <div className="">
                                                                    Hitesh Tripathi
                                                                </div>
                                                            )}
                                                        </div>
                                                    </div>
                                                </div> : <></>
                                        ))}
                                        <EmptyGameCard length={launchCards.length} />
                                    </div>
                                </>
                            ) : (
                                <NoDataResult>{t("launchpad.home.no_launches")}</NoDataResult>
                            )}
                    </div>
                </div>
            </div>
        </>
    );
};

export default LaunchpadProject;