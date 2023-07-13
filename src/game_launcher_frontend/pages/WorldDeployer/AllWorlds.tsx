import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import Card from "@/components/Card";
import EmptyGameCard from "@/components/EmptyGameCard";
import Pagination from "@/components/Pagination";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import { navPaths } from "@/shared";
import { getPaginationPages } from "@/utils";
import { useGetTotalWorlds, useGetWorlds } from "@/api/world_deployer";

const AllWorlds = () => {
    const [pageNumber, setPageNumber] = React.useState(1);
    const { t } = useTranslation();
    const navigate = useNavigate();

    const { data: worlds = [], isLoading, isError } = useGetWorlds(pageNumber);
    const { data: totalWorlds } = useGetTotalWorlds();

    return (
        <>
            {isLoading ? (
                <LoadingResult>{t("manage_nfts.loading")}</LoadingResult>
            ) : isError ? (
                <ErrorResult>{t("error")}</ErrorResult>
            ) : worlds.length ? (
                <>
                    <div className="card-container">
                        {worlds.map(({ name, canister, cover }) => (
                            <Card
                                type="world"
                                showCycles
                                key={canister}
                                icon={<Cog8ToothIcon />}
                                title={name}
                                canisterId={canister}
                                onClick={() =>
                                    window.open(`${navPaths.boomdao_candid_url}?id=${canister}`, "_blank")
                                }
                            />
                        ))}
                        <EmptyGameCard length={worlds.length} />
                    </div>

                    <Pagination
                        pageNumber={pageNumber}
                        setPageNumber={setPageNumber}
                        totalNumbers={getPaginationPages(totalWorlds, 9)}
                    />
                </>
            ) : (
                <NoDataResult>{t("world_deployer.no_worlds_at_all")}</NoDataResult>
            )}
        </>
    );
};

export default AllWorlds;
