import React from "react";
import { useTranslation } from "react-i18next";
import { NoSymbolIcon } from "@heroicons/react/20/solid";
import { useGetCycleBalance, useGetGameCover } from "@/api/games_deployer";
import Center from "./ui/Center";
import Divider from "./ui/Divider";
import Loader from "./ui/Loader";

interface CardProps {
  title: string;
  icon: React.ReactElement<React.SVGProps<SVGSVGElement>>;
  platform?: string;
  canisterId?: string;
  showCycles?: boolean;
  onClick?: () => void;
}

const Card = ({
  title,
  icon,
  platform,
  canisterId,
  showCycles,
  onClick,
}: CardProps) => {
  const { t } = useTranslation();

  const { data: image, isLoading: loadingImage } = useGetGameCover(canisterId);
  const { data: cycleBalance } = useGetCycleBalance(canisterId, showCycles);

  const iconWithProps = React.cloneElement(icon, {
    className: "w-8 h-8 bg-black rounded-full text-white p-2 min-w-[32px]",
  });

  return (
    <Center>
      <div
        onClick={onClick}
        className="gradient-bg w-full cursor-pointer rounded-primary p-0.5"
      >
        <div className="h-full w-full rounded-primary bg-white px-6 py-6 dark:bg-dark">
          <div className="mb-6 flex justify-between">
            <p className="truncate text-2xl">{title}</p>
            {iconWithProps}
          </div>

          <div className="mb-4 h-40">
            {loadingImage ? (
              <Center className="h-full flex-col gap-2">
                <Loader />
                <p className="text-sm">{t("card.loading_image")}</p>
              </Center>
            ) : !image ? (
              <Center className="h-full flex-col gap-2">
                <NoSymbolIcon className="w-10" />
                <p className="text-sm">{t("card.no_image")}</p>
              </Center>
            ) : (
              <img
                src={image}
                alt="game image"
                className="h-40 w-full object-cover"
              />
            )}
          </div>

          <div>
            {platform && (
              <>
                <div className="flex items-center gap-2">
                  <p className="font-semibold">{t("card.platform")}: </p>
                  <p>{platform}</p>
                </div>

                <Divider className="my-2" />
              </>
            )}

            {canisterId && (
              <div>
                <p className="font-semibold">{t("card.canister_id")}: </p>
                <p>{canisterId}</p>
              </div>
            )}

            {showCycles && (
              <div className="mt-4 flex items-center gap-2">
                <p className="font-semibold">{t("card.cycles")}: </p>
                <p>{cycleBalance || "0.00T"}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </Center>
  );
};

export default Card;
