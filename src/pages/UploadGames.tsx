import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon, NoSymbolIcon } from "@heroicons/react/20/solid";
import { useGetUserGames } from "@/api/games";
import Card from "@/components/Card";
import Pagination from "@/components/Pagination";
import Button from "@/components/ui/Button";
import Center from "@/components/ui/Center";
import H1 from "@/components/ui/H1";
import LogoLoader from "@/components/ui/LogoLoader";
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

  const displayLoading = (
    <Center className="flex-col gap-2">
      <LogoLoader />
      <p>Loading games...</p>
    </Center>
  );

  const displayError = (
    <Center className="flex-col gap-2">
      <NoSymbolIcon className="h-12 w-12" />
      <p>Sorry something happend... try again later</p>
    </Center>
  );

  return (
    <>
      <Space size="medium" />

      <Button
        size="big"
        rightArrow
        onClick={() => navigate(`${navPaths.upload_games}/new`)}
      >
        {t("upload_new_game")}
      </Button>

      <Space />

      <H1>{t("previously_uploaded_games")}</H1>

      <Space size="medium" />

      {isLoading ? (
        displayLoading
      ) : isError ? (
        displayError
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
                // cycles={cycles}
                onClick={() =>
                  navigate(`${navPaths.upload_games}/${canister_id}`)
                }
              />
            ))}
          </div>

          <Pagination
            pageNumber={pageNumber}
            setPageNumber={setPageNumber}
            totalNumbers={getPaginationPages(12, 9)}
          />
        </>
      ) : (
        <Center className="flex-col gap-2">
          <NoSymbolIcon className="h-12 w-12" />
          <p>You have no games created yet...</p>
        </Center>
      )}
    </>
  );
};

export default UploadGames;
