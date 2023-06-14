import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import { useGetTotalTokens, useGetTokens } from "@/api/token_deployer";
import Card from "@/components/Card";
import EmptyGameCard from "@/components/EmptyGameCard";
import Pagination from "@/components/Pagination";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";
import { getPaginationPages } from "@/utils";

const AllTokens = () => {
    const [pageNumber, setPageNumber] = React.useState(1);
    const { t } = useTranslation();
    const navigate = useNavigate();

    const { data: tokens = [], isLoading, isError } = useGetTokens(pageNumber);
    const { data: totalUserTokens } = useGetTotalTokens();

    return (
        <>
            {isLoading ? (
                <LoadingResult>{t("token_deployer.loading")}</LoadingResult>
            ) : isError ? (
                <ErrorResult>{t("error")}</ErrorResult>
            ) : tokens.length ? (
                <>
                    <div className="card-container">
                        {tokens.map(({ canister, name, description, cover, symbol }) => (
                            <Card
                                type="token"
                                key={canister}
                                icon={<Cog8ToothIcon />}
                                title={name}
                                canisterId={canister}
                                noImage
                                symbol={symbol}
                                onClick={() =>
                                    navigate(`${navPaths.token}/${canister}`)
                                }
                            />
                        ))}
                        <EmptyGameCard length={tokens.length} />
                    </div>

                    <Pagination
                        pageNumber={pageNumber}
                        setPageNumber={setPageNumber}
                        totalNumbers={getPaginationPages(totalUserTokens, 9)}
                    />
                </>
            ) : (
                <NoDataResult>{t("token_deployer.no_tokens")}</NoDataResult>
            )}
        </>
    );
};

export default AllTokens;
