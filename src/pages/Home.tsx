import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { NoSymbolIcon } from "@heroicons/react/20/solid";
import { useGetGames, useGetGamesCount } from "@/api/games";
import Card from "@/components/Card";
import Pagination from "@/components/Pagination";
import Center from "@/components/ui/Center";
import LogoLoader from "@/components/ui/LogoLoader";
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
  const { data: games = [], isError, isLoading } = useGetGames(pageNumber);
  const { data: totalGames } = useGetGamesCount();

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

  const displayNoData = (
    <Center className="flex-col gap-2">
      <NoSymbolIcon className="h-12 w-12" />
      <p>There was no games created yet...</p>
    </Center>
  );

  return (
    <>
      <img
        src="/banner.png"
        alt="banner"
        className="h-96 w-full rounded-primary object-cover shadow"
      />
      <Space />
      <h1 className="flex flex-wrap gap-3 text-[56px] font-semibold leading-none">
        <span className="gradient-text">Games</span>
        <span>hosted in</span>
        <span className="gradient-text">smart contract canisters</span>
        <span>on the</span>
        <span className="gradient-text">ICP</span>
        <span>blockchain</span>
      </h1>
      <Space size="medium" />
      {isError ? (
        displayError
      ) : isLoading ? (
        displayLoading
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
        displayNoData
      )}
    </>
  );
};

export default Home;
