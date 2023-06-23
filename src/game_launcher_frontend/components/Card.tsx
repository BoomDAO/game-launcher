import React from "react";
import { useTranslation } from "react-i18next";
import { NoSymbolIcon } from "@heroicons/react/20/solid";
import { useGetGameCover, useGetGameCycleBalance } from "@/api/games_deployer";
import { useGetCollectionCycleBalance } from "@/api/minting_deployer";
import Center from "./ui/Center";
import Divider from "./ui/Divider";
import Loader from "./ui/Loader";
import { useGetTokenCycleBalance } from "@/api/token_deployer";
import { useGetWorldCycleBalance } from "@/api/world_deployer";
import { useGetWorldCover } from "@/api/world_deployer";

interface CardProps {
  title: string;
  icon: React.ReactElement<React.SVGProps<SVGSVGElement>>;
  platform?: string;
  canisterId?: string;
  showCycles?: boolean;
  noImage?: boolean;
  verified?: boolean;
  symbol?: string;
  visibility?: string;
  onClick?: () => void;
  type: "game" | "collection" | "token" | "world";
}

const Card = ({
  title,
  icon,
  platform,
  canisterId,
  showCycles,
  noImage,
  verified,
  symbol,
  visibility,
  onClick,
  type,
}: CardProps) => {
  const { t } = useTranslation();

  const { data: image, isLoading: loadingImage } = useGetGameCover(canisterId);
  const { data: world_cover, isLoading: loadingWorldImage } = useGetWorldCover(canisterId);

  const { data: gameCycleBalance } = useGetGameCycleBalance(
    canisterId,
    showCycles && type === "game",
  );

  const { data: worldCycleBalance } = useGetWorldCycleBalance(
    canisterId,
    showCycles && type === "world"
  );

  const { data: collectionCycleBalance } = useGetCollectionCycleBalance(
    canisterId,
    showCycles && type === "collection",
  );

  const iconWithProps = React.cloneElement(icon, {
    className: "w-8 h-8 bg-black rounded-full text-white p-2 min-w-[32px]",
  });

  const cycles = gameCycleBalance || collectionCycleBalance || worldCycleBalance || "0.00T";

  return (
    <Center>
      <div
        onClick={onClick}
        className="gradient-bg w-full cursor-pointer rounded-primary p-0.5"
      >
        <div className="h-full w-full rounded-primary bg-white px-6 py-6 dark:bg-dark">
          <div className="mb-2 flex justify-between">
            <div className="flex justify-content-center items-center">
              <p className="truncate text-2xl">{title}</p>
              {verified ? (
                <img
                  src="/verified.png"
                  alt="game image"
                  className="h-5 w-5"
                />
              ) : null}
              {(visibility == "private") ? (
                <>
                  <p className="text-xs px-1" style={{ color: "yellow" }}>(Private)</p>
                </>
              ) : (<></>)}
            </div>
            {iconWithProps}
          </div>
          {symbol ? (
            <div className="text-1xl flex justify-content-center">
              <p className="font-semibold">Symbol :</p>
              <p className="pl-3 font-bold">{symbol}</p>
            </div>
          ) : null}
          {!noImage ? (
            <div className="mb-4 h-40">
              {(loadingImage && type === "game") ? (
                <Center className="h-full flex-col gap-2">
                  <Loader />
                  <p className="text-sm">{t("card.loading_image")}</p>
                </Center>
              ) : (loadingWorldImage && type === "world") ? (
                <Center className="h-full flex-col gap-2">
                  <Loader />
                  <p className="text-sm">{t("card.loading_image")}</p>
                </Center>
              ) : (type === "world") ? (
                <img
                  src={world_cover}
                  alt="game image"
                  className="h-40 w-full object-cover"
                />
              ) : !image ? (
                <Center className="h-full flex-col gap-2">
                  <NoSymbolIcon className="w-10" />
                  <p className="text-sm">{t("card.no_image")}</p>
                </Center>
              ) : (
                <div className="relative text-center">
                  {(visibility == "soon") ? (
                    <>
                      <img
                        src={image}
                        alt="game image"
                        className="h-40 w-full object-cover blur-sm"
                      />
                      <h3 className="font-semibold text-5xl text-white absolute left-1/5 top-1/4">Coming Soon!</h3>
                    </>
                  ) : (<>
                    <img
                      src={image}
                      alt="game image"
                      className="h-40 w-full object-cover"
                    />
                  </>)}
                </div>
              )}
            </div>
          ) : null}

          <div>
            <div className="flex items-center gap-2">
              {platform && (
                <>
                  <div className="flex items-center gap-2">
                    <p className="font-semibold">{t("card.platform")}: </p>
                    <p>{platform}</p>
                  </div>
                </>
              )}
            </div>
            <Divider className="my-2" />

            {canisterId && (
              <div>
                <p className="font-semibold">{t("card.canister_id")} : </p>
                <p>{canisterId}</p>
              </div>
            )}

            {showCycles && (
              <div className="mt-4 flex items-center gap-2">
                <p className="font-semibold">{t("card.cycles")}: </p>
                <p>{cycles}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </Center>
  );
};

export default Card;
