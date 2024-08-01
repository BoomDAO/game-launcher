import { useGetAllTokensInfo } from "@/api/launchpad";
import { useGetBoomStakeTier } from "@/api/profile";
import EmptyGameCard from "@/components/EmptyGameCard";
import LaunchCard from "@/components/LaunchCard";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Loader from "@/components/ui/Loader";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import { boom_ledger_canisterId } from "@/hooks";
import { navPaths } from "@/shared";
import { Button } from "@mui/material";
import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";

const Launchpad = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { session } = useAuthContext();
    const { setIsOpenNavSidebar } = useGlobalContext();
    const [totalUpcomingSale, setTotalUpcomingSale] = React.useState(0);
    const [totalPastSale, setTotalPastSale] = React.useState(0);
    const { data: launchCards, isLoading, isError } = useGetAllTokensInfo();
    const { data: stakingTier, isLoading: isStakingTierLoading } = useGetBoomStakeTier();

    React.useEffect(() => {
        if (!isLoading) {
            let upcoming = 0, past = 0;
            launchCards?.map(({ swap }) => {
                if (swap.status == "Upcoming") upcoming += 1;
                else if (swap.status == "Inactive") past += 1;
            })
            setTotalUpcomingSale(upcoming);
            setTotalPastSale(past);
        }
    }, [launchCards, isLoading]);

    return (
        <>
            <div className="w-full text-center"><p className="gradient-text text-5xl font-semibold pb-10 mt-10">CROWDFUND YOUR GAMING PROJECT</p></div>
            <div className="pt-2 text-center bg-white rounded-xl pt-5 pb-5">
                <div className="dark:text-black text-white text-xl font-bold">SALE OPENS 24 HOUR EARLY FOR ELITE STAKERS AND 12 HOUR EARLY FOR PRO STAKERS</div>
                {
                    (isStakingTierLoading) ? <Loader className="w-8 h-8 mt-4 mx-auto"></Loader> :
                        (stakingTier == "") ? <Button size="large" className="!mt-4 !rounded-xl yellow-red-gradient-bg !text-white !font-semibold !px-6" onClick={(e) => {
                            if (session) {
                                navigate(navPaths.launchpad_stake + "/" + boom_ledger_canisterId);
                                e.stopPropagation();
                            } else {
                                setIsOpenNavSidebar(true);
                            }
                        }}>STAKE BOOM FOR EARLY SALE ACCESS</Button> :
                            <p className="gradient-text text-lg font-semibold mt-4">YOU ARE IN THE {stakingTier} STAKING TIER</p>
                }
            </div>
            <div className="mt-10">
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
                                        (swap.status == "Active") ?
                                            <div key={id}>
                                                <LaunchCard
                                                    id={id}
                                                    token={token}
                                                    project={project}
                                                    swap={swap}
                                                />
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

            <div className="mt-10">
                {
                    (totalUpcomingSale > 0) ? <p className="h-16 gradient-text text-5xl font-semibold mt-4 mb-4">Upcoming Sales</p> : <></>
                }
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
                                        (swap.status == "Upcoming") ?
                                            <div key={id} className="mb-4">
                                                <LaunchCard
                                                    id={id}
                                                    token={token}
                                                    project={project}
                                                    swap={swap}
                                                />
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

            <div className="mt-10">
                {
                    (totalPastSale > 0) ? <p className="h-16 gradient-text text-5xl font-semibold mt-4 mb-4">Past Sales</p> : <></>
                }
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
                                        (swap.status == "Inactive") ?
                                            <div key={id} className="mb-4">
                                                <LaunchCard
                                                    id={id}
                                                    token={token}
                                                    project={project}
                                                    swap={swap}
                                                />
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
        </>
    );
};

export default Launchpad;