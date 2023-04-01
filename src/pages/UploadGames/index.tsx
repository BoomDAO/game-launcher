import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import { useGetTotalUserGames, useGetUserGames } from "@/api/deployer";
import Card from "@/components/Card";
import Pagination from "@/components/Pagination";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";
import { getPaginationPages } from "@/utils";

const data = Array.from({ length: 9 }).map((_, i) => ({
  title: `Game 0${i}`,
  image: "/banner.png",
  platform: "Browser",
  canisterId: `r44we3-pqaaa-aaaap-aaosq-cai${i}`,
  cycles: "2.3T",
}));

const UploadGames = () => {
  const [pageNumber, setPageNumber] = React.useState(1);
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { data: games = [], isLoading, isError } = useGetUserGames(pageNumber);
  const { data: totalGames } = useGetTotalUserGames();

  return (
    <>
      <Space size="medium" />

      <Button
        size="big"
        rightArrow
        onClick={() => navigate(`${navPaths.upload_games}/create_game`)}
      >
        {t("upload_games.button_upload")}
      </Button>

      <Space />

      <H1>{t("upload_games.title")}</H1>

      <Space size="medium" />

      {isLoading ? (
        <LoadingResult>{t("upload_games.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("error")}</ErrorResult>
      ) : data.length ? (
        <>
          <div className="grid gap-6 grid-auto-fit-xl">
            {games.map(({ canister_id, platform, name }) => (
              <Card
                key={canister_id}
                icon={<Cog8ToothIcon />}
                title={name}
                canisterId={canister_id}
                platform={platform}
                showCycles
                onClick={() =>
                  navigate(`${navPaths.upload_games}/${canister_id}`)
                }
              />
            ))}
          </div>

          <Pagination
            pageNumber={pageNumber}
            setPageNumber={setPageNumber}
            totalNumbers={getPaginationPages(totalGames, 9)}
          />
        </>
      ) : (
        <NoDataResult>{t("upload_games.no_games")}</NoDataResult>
      )}
    </>
  );
};

export default UploadGames;
