import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { useGetGames, useGetTotalGames } from "@/api/games_deployer";
import Card from "@/components/Card";
import EmptyGameCard from "@/components/EmptyGameCard";
import Pagination from "@/components/Pagination";
import Slider from "@/components/Slider";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import { navPaths } from "@/shared";
import { getPaginationPages } from "@/utils";

const Home = () => {
  const [sorting, setSorting] = React.useState("featured");
  const [pageNumber, setPageNumber] = React.useState(1);
  const { t } = useTranslation();
  const navigate = useNavigate();

  const { setIsOpenNavSidebar } = useGlobalContext();
  const { session } = useAuthContext();

  const { data: games = [], isError, isLoading } = useGetGames(pageNumber, sorting);
  const { data: totalGames } = useGetTotalGames();

  const onUploadButtonClick = () => {
    if (!session) return setIsOpenNavSidebar(true);
    return navigate(navPaths.upload_games);
  };

  return (
    <>
      <Slider />
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
      <>
        <div className="w-full max-w-screen-xl flex items-center pt-10 pb-10 justify-end">
          <div><label className="pr-3">Sort By : </label></div>
          <div><select
          onChange={(event)=> setSorting(event.target.value)} 
          className="w-60 h-10 p-2 cursor-pointer" name="sorting" id="sorting">
            <option value="featured">Featured</option>
            <option value="newest">Newest</option>
          </select>
          </div>
        </div>
      </>
      {isLoading ? (
        <LoadingResult>{t("home.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("error")}</ErrorResult>
      ) : 
      games.length ? (
        <>
          <div className="card-container">
            {games.map(({ canister_id, platform, name, url, verified }) => (
              <Card
                type="game"
                key={canister_id}
                icon={<ArrowUpRightIcon />}
                title={name}
                canisterId={canister_id}
                platform={platform}
                verified={verified}
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
