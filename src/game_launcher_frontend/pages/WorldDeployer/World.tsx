import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import { useGetTotalUserWorlds, useGetUserWorlds } from "@/api/world_deployer";
import Card from "@/components/Card";
import EmptyGameCard from "@/components/EmptyGameCard";
import Pagination from "@/components/Pagination";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";
import { getPaginationPages } from "@/utils";

const World = () => {
  const [pageNumber, setPageNumber] = React.useState(1);
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data: worlds = [], isLoading, isError } = useGetUserWorlds(pageNumber);
  const { data: totalWorlds } = useGetTotalUserWorlds();

  return (
    <>
      <Button
        size="big"
        rightArrow
        onClick={() => navigate(`${navPaths.create_new_world}`)}
      >
        {t("world_deployer.index.button_world_deployer")}
      </Button>
      <H1>{t("world_deployer.index.tabs.item_1_title")}</H1>

      {isLoading ? (
        <LoadingResult>{t("world_deployer.index.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("world_deployer.index.error")}</ErrorResult>
      ) : worlds.length ? (
        <>
          <div className="card-container">
            {worlds.map(({ canister, name, cover }) => (
              <Card
                type="world"
                key={canister}
                icon={<Cog8ToothIcon />}
                title={name}
                canisterId={canister}
                showCycles
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
        <NoDataResult>{t("world_deployer.index.error")}</NoDataResult>
      )}
    </>
  );
};

export default World;
