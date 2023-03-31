import React from "react";
import { useTranslation } from "react-i18next";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { useGetGames, useGetTotalGames } from "@/api/games";
import Card from "@/components/Card";
import Pagination from "@/components/Pagination";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Space from "@/components/ui/Space";
import { getPaginationPages } from "@/utils";

const data = Array.from({ length: 9 }).map((_, i) => ({
  title: `Game 0${i}`,
  image: "/banner.png",
  platform: "Browser",
  canisterId: `r44we3-pqaaa-aaaap-aaosq-cai${i}`,
}));

const Home = () => {
  const [pageNumber, setPageNumber] = React.useState(1);
  const { t } = useTranslation();

  const { data: games = [], isError, isLoading } = useGetGames(pageNumber);
  const { data: totalGames } = useGetTotalGames();

  return (
    <>
      <img
        src="/banner.png"
        alt="banner"
        className="h-96 w-full rounded-primary object-cover shadow"
      />
      <Space />
      <h1 className="flex flex-wrap gap-3 text-[56px] font-semibold leading-none">
        <span className="gradient-text">{t("home.title.text_1")}</span>
        <span>{t("home.title.text_2")}</span>
        <span className="gradient-text">{t("home.title.text_3")}</span>
        <span>{t("home.title.text_4")}</span>
        <span className="gradient-text">{t("home.title.text_5")}</span>
        <span>{t("home.title.text_6")}</span>
      </h1>
      <Space size="medium" />
      {isLoading ? (
        <LoadingResult>{t("home.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("error")}</ErrorResult>
      ) : data.length ? (
        <>
          <div className="grid gap-6 grid-auto-fit-xl">
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
