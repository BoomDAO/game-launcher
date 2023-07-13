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
import { useGetAllCollections, useGetTotalCollections } from "@/api/minting_deployer";

const AllNfts = () => {
    const [pageNumber, setPageNumber] = React.useState(1);
    const { t } = useTranslation();
    const navigate = useNavigate();

    const { data: collections = [], isLoading, isError } = useGetAllCollections(pageNumber);
    const { data: totalCollections } = useGetTotalCollections();

    return (
        <>
            {isLoading ? (
                <LoadingResult>{t("manage_nfts.loading")}</LoadingResult>
            ) : isError ? (
                <ErrorResult>{t("error")}</ErrorResult>
            ) : collections.length ? (
                <>
                    <div className="card-container">
                        {collections.map(({ name, canister_id }) => (
                            <Card
                                type="collection"
                                key={canister_id}
                                icon={<Cog8ToothIcon />}
                                title={name}
                                canisterId={canister_id}
                                noImage
                                showCycles
                                onClick={() =>
                                    navigate(`${navPaths.manage_nfts}/${canister_id}`)
                                }
                            />
                        ))}
                        <EmptyGameCard length={collections.length} />
                    </div>

                    <Pagination
                        pageNumber={pageNumber}
                        setPageNumber={setPageNumber}
                        totalNumbers={getPaginationPages(totalCollections, 9)}
                    />
                </>
            ) : (
                <NoDataResult>{t("manage_nfts.no_collections_at_all")}</NoDataResult>
            )}
        </>
    );
};

export default AllNfts;
