import { useGetAllTokensInfo, useGetTokenInfo } from "@/api/launchpad";
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
    const { data: launchCards, isLoading, isError } = useGetTokenInfo();
    const [activeTab, setActiveTab] = React.useState(1);
    const tabItems = [
        { id: 1, name: "ABOUT PROJECT" },
        { id: 2, name: "TOKEN ALLOCATIONS" },
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
                                                <div key={id}>
                                                    <LaunchCard
                                                        id={id}
                                                        token={token}
                                                        project={project}
                                                        swap={swap}
                                                    />
                                                    <div className="flex mt-20 w-full mb-10">
                                                        <div className="w-1/4">
                                                            <div><img src={project.creatorImageUrl} className="w-20 h-20 rounded-primary" /></div>
                                                            <div className="text-base font-semibold">{project.creator}</div>
                                                        </div>
                                                        <div className="w-3/4 pt-10 text-base">
                                                            {project.creatorAbout}
                                                        </div>
                                                    </div>
                                                    <Divider />
                                                    <div className="flex w-full">
                                                        <div className="w-1/4 mt-10"><VerticalTabs tabs={tabItems} active={activeTab} setActive={setActiveTab} /></div>
                                                        <div className="w-3/4 mt-12 text-sm">
                                                            {activeTab === 1 && (
                                                                <div className="text-base">
                                                                    {project.description}
                                                                </div>
                                                            )}
                                                            {activeTab === 2 && (
                                                                <div className="text-base">
                                                                    <div>
                                                                    <div>Token Sale</div>
                                                                    <div>{ (swap.swapType == "BOOM") ? String(swap.supply_configs.gaming_guilds.boom) + " BOOM" : String(swap.supply_configs.gaming_guilds.icp) + " ICP" }</div>
                                                                    <div>{String(swap.supply_configs.gaming_guilds.icrc)} {token.symbol}</div>
                                                                    </div>

                                                                    <div>Gaming Guilds</div>
                                                                    <div>{String(swap.supply_configs.gaming_guilds.boom)} BOOM</div>
                                                                    <div>{String(swap.supply_configs.gaming_guilds.icp)} ICP</div>
                                                                    <div>Project Team</div>
                                                                    <div>{String(swap.supply_configs.team.boom)} BOOM</div>
                                                                    <div>{String(swap.supply_configs.team.icp)} ICP</div>
                                                                    <div>BOOM DAO Treasury</div>
                                                                    <div>{String(swap.supply_configs.boom_dao_treasury.boom)} BOOM</div>
                                                                    <div>{String(swap.supply_configs.boom_dao_treasury.icp)} ICP</div>
                                                                    <div>Liquidity Pool</div>
                                                                    <div>{String(swap.supply_configs.liquidity_pool.boom)} BOOM</div>
                                                                    <div>{String(swap.supply_configs.liquidity_pool.icp)} ICP</div>
                                                                    <div>Token Sale</div>
                                                                    <div>{String(swap.supply_configs.gaming_guilds.boom)} BOOM</div>
                                                                    <div>{String(swap.supply_configs.gaming_guilds.icp)} ICP</div>
                                                                </div>
                                                            )}
                                                            {activeTab === 3 && (
                                                                <div className="">
                                                                    {
                                                                        (project.faqs.map((val) => (
                                                                            <div className="mt-4" key={val[0]}>
                                                                                <li className="text-lg font-semibold">{val[0]}</li>
                                                                                <div className="text-base ml-7">{val[1]}</div>
                                                                            </div>
                                                                        )))
                                                                    }
                                                                </div>
                                                            )}
                                                        </div>
                                                    </div>
                                                </div>
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