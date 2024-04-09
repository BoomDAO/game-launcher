import { useGetAllTokensInfo } from "@/api/launchpad";
import EmptyGameCard from "@/components/EmptyGameCard";
import LaunchCard from "@/components/LaunchCard";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import { useGlobalContext } from "@/context/globalContext";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";

const Launchpad = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { setIsOpenNavSidebar } = useGlobalContext();
    const { data: launchCards, isLoading, isError } = useGetAllTokensInfo();

    return (
        <>
            <div className="w-full text-center"><p className="gradient-text text-5xl font-semibold pb-10 mt-10">CROWDFUND YOUR GAMING PROJECT</p></div>
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
                                        (swap.status) ?
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
                <p className="gradient-text text-5xl font-semibold mt-10 mb-5">Past Launchpads</p>
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
                                        (!swap.status) ?
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
        </>
    );
};

export default Launchpad;