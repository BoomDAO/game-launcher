import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { useGetGames, useGetTotalGames } from "@/api/games_deployer";
import Card from "@/components/Card";
import EmptyGameCard from "@/components/EmptyGameCard";
import Pagination from "@/components/Pagination";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import { navPaths } from "@/shared";
import { getPaginationPages } from "@/utils";

const Home = () => {
  const [pageNumber, setPageNumber] = React.useState(1);
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { setIsOpenNavSidebar } = useGlobalContext();
  const { session } = useAuthContext();

  const { data: games = [], isError, isLoading } = useGetGames(pageNumber);
  const { data: totalGames } = useGetTotalGames();

  const onUploadButtonClick = () => {
    if (!session) return setIsOpenNavSidebar(true);
    return navigate(navPaths.upload_games);
  };

  return (
    <>
      <img
        src="/banner.png"
        alt="banner"
        className="h-72 w-full rounded-primary object-cover shadow md:h-96"
      />
      <Space />

      <H1 className="flex flex-wrap gap-3 font-semibold leading-none">
        <span className="gradient-text">{t("home.title.text_1")}</span>
        <span>{t("home.title.text_2")}</span>
        <span className="gradient-text">{t("home.title.text_3")}</span>
        <span>{t("home.title.text_4")}</span>
        <span className="gradient-text">{t("home.title.text_5")}</span>
        <span className="mr-4">{t("home.title.text_6")}</span>
        <Button
          onClick={onUploadButtonClick}
          className="h-fit"
          rightArrow
          size="big"
        >
          {t("home.button_upload")}
        </Button>
      </H1>

      <Space size="medium" />
      {isLoading ? (
        <LoadingResult>{t("home.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("error")}</ErrorResult>
      ) : games.length ? (
        <>
          <div className="grid grid-cols-card gap-6">
            {games.map(({ canister_id, platform, name, url }) => (
              <Card
                key={canister_id}
                icon={<ArrowUpRightIcon />}
                title={name}
                canisterId={canister_id}
                platform={platform}
                onClick={() => window.open(url, "_blank")}
              />
            ))}
            <EmptyGameCard length={games.length} />
          </div>

          <Pagination
            pageNumber={pageNumber}
            setPageNumber={setPageNumber}
            totalNumbers={getPaginationPages(totalGames, 9)}
          />
        </>
      ) : (
        <NoDataResult>{t("home.no_games")}</NoDataResult>
      )}
    </>
  );
};

export default Home;
