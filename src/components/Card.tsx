import React from "react";
import { useTranslation } from "react-i18next";
import Divider from "./Divider";

interface CardProps {
  title: string;
  icon: React.ReactElement<React.SVGProps<SVGSVGElement>>;
  image: string;
  platform?: string;
  canisterId?: string;
  cycles?: string;
  onClick?: () => void;
}

const Card = ({
  title,
  icon,
  image,
  platform,
  canisterId,
  cycles,
  onClick,
}: CardProps) => {
  const { t } = useTranslation();

  const iconWithProps = React.cloneElement(icon, {
    className: "w-8 h-8 bg-black rounded-full text-white p-2",
  });

  return (
    <div className="flex items-center justify-center">
      <div
        onClick={onClick}
        className="gradient-bg w-full cursor-pointer rounded-card p-1"
      >
        <div className="h-full w-full rounded-card bg-white px-6 py-6 dark:bg-dark">
          <div className="mb-6 flex justify-between">
            <p className="text-2xl">{title}</p>
            {iconWithProps}
          </div>

          <img src={image} alt="game image" className="mb-4 w-full" />

          <div>
            {platform && (
              <>
                <div className="flex items-center gap-2">
                  <p className="font-semibold">{t("platform")}: </p>
                  <p>{platform}</p>
                </div>

                <Divider className="my-2" />
              </>
            )}

            {canisterId && (
              <div>
                <p className="font-semibold">{t("canister_id")}: </p>
                <p>{canisterId}</p>
              </div>
            )}

            {cycles && (
              <div className="mt-4 flex items-center gap-2">
                <p className="font-semibold">{t("cycles")}: </p>
                <p>{cycles}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Card;
