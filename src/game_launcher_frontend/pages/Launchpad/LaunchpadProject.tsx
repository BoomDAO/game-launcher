import { useGetAllTokensInfo, useGetTokenInfo } from "@/api/launchpad";
import EmptyGameCard from "@/components/EmptyGameCard";
import LaunchCard from "@/components/LaunchCard";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import VerticalTabs from "@/components/VerticalTabs";
import Divider from "@/components/ui/Divider";
import { useGlobalContext } from "@/context/globalContext";
import { SupplyConfigs } from "@/types";
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

    const getSupplyPercent = (token: string, configs: SupplyConfigs) => {
        if (token == "icp") {
            let total = configs.boom_dao_treasury.icp + configs.gaming_guilds.icp + configs.liquidity_pool.icp + configs.team.icp;
            return {
                gaming_guilds: (configs.gaming_guilds.icp * 100n) / total,
                boom_dao_treasury: (configs.boom_dao_treasury.icp * 100n) / total,
                liquidity_pool: (configs.liquidity_pool.icp * 100n) / total,
                team: (configs.team.icp * 100n) / total,
                participants: 0
            };
        } else if (token == "boom") {
            let total = configs.boom_dao_treasury.boom + configs.gaming_guilds.boom + configs.liquidity_pool.boom + configs.team.boom;
            return {
                gaming_guilds: (configs.gaming_guilds.boom * 100n) / total,
                boom_dao_treasury: (configs.boom_dao_treasury.boom * 100n) / total,
                liquidity_pool: (configs.liquidity_pool.boom * 100n) / total,
                team: (configs.team.boom * 100n) / total,
                participants: 0
            };
        } else {
            let total = configs.boom_dao_treasury.icrc + configs.gaming_guilds.icrc + configs.liquidity_pool.icrc + configs.team.icrc;
            return {
                gaming_guilds: (configs.gaming_guilds.icrc * 100n) / total,
                boom_dao_treasury: (configs.boom_dao_treasury.icrc * 100n) / total,
                liquidity_pool: (configs.liquidity_pool.icrc * 100n) / total,
                team: (configs.team.icrc * 100n) / total,
                participants: 0
            };
        };
    };

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
                                                                <div className="mb-4">
                                                                    <div className="font-semibold text-lg">Token Sale Allocation</div>
                                                                    <div>
                                                                        {String(swap.supply_configs.gaming_guilds.icrc / 100000000n)} {token.symbol + " - "}
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).gaming_guilds) + "%"
                                                                        }
                                                                    </div>
                                                                </div>

                                                                <div className="mb-4">
                                                                    <div className="font-semibold text-lg">BOOM Gaming Guilds Allocation</div>
                                                                    <div>
                                                                        {(swap.swapType == "BOOM") ?
                                                                            String(swap.supply_configs.gaming_guilds.boom / 100000000n) + " BOOM - " :
                                                                            String(swap.supply_configs.gaming_guilds.icp / 100000000n) + " ICP - "
                                                                        }
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).gaming_guilds) + "%"
                                                                        }
                                                                    </div>
                                                                    <div>
                                                                        {String(swap.supply_configs.gaming_guilds.icrc / 100000000n)} {token.symbol + " - "}
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).gaming_guilds) + "%"
                                                                        }
                                                                    </div>
                                                                </div>

                                                                <div className="mb-4">
                                                                    <div className="font-semibold text-lg">Project Team Allocation</div>
                                                                    <div>
                                                                        {(swap.swapType == "BOOM") ?
                                                                            String(swap.supply_configs.team.boom / 100000000n) + " BOOM - " :
                                                                            String(swap.supply_configs.team.icp / 100000000n) + " ICP - "
                                                                        }
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).team) + "%"
                                                                        }
                                                                    </div>
                                                                    <div>
                                                                        {String(swap.supply_configs.team.icrc / 100000000n)} {token.symbol + " - "}
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).team) + "%"
                                                                        }
                                                                    </div>
                                                                </div>

                                                                <div className="mb-4">
                                                                    <div className="font-semibold text-lg">BOOM DAO Treasury Allocation</div>
                                                                    <div>
                                                                        {(swap.swapType == "BOOM") ?
                                                                            String(swap.supply_configs.boom_dao_treasury.boom / 100000000n) + " BOOM - " :
                                                                            String(swap.supply_configs.boom_dao_treasury.icp / 100000000n) + " ICP - "
                                                                        }
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).boom_dao_treasury) + "%"
                                                                        }
                                                                    </div>
                                                                    <div>
                                                                        {String(swap.supply_configs.boom_dao_treasury.icrc / 100000000n)} {token.symbol + " - "}
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).boom_dao_treasury) + "%"
                                                                        }
                                                                    </div>
                                                                </div>

                                                                <div className="mb-4">
                                                                    <div className="font-semibold text-lg">Liquidity Pool Allocation</div>
                                                                    <div>
                                                                        {(swap.swapType == "BOOM") ?
                                                                            String(swap.supply_configs.liquidity_pool.boom / 100000000n) + " BOOM - " :
                                                                            String(swap.supply_configs.liquidity_pool.icp / 100000000n) + " ICP - "
                                                                        }
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).liquidity_pool) + "%"
                                                                        }
                                                                    </div>
                                                                    <div>
                                                                        {String(swap.supply_configs.liquidity_pool.icrc / 100000000n)} {token.symbol + " - "}
                                                                        {
                                                                            String(getSupplyPercent(swap.swapType, swap.supply_configs).liquidity_pool) + "%"
                                                                        }
                                                                    </div>
                                                                </div>
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