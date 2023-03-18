import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import Button from "@/components/Button";
import Card from "@/components/Card";
import H1 from "@/components/H1";
import Space from "@/components/Space";
import { navPaths } from "@/shared";

const data = Array.from({ length: 9 }).map((_, i) => ({
  title: `Game 0${i}`,
  image: "/banner.png",
  platform: "Browser",
  canisterId: `r44we3-pqaaa-aaaap-aaosq-cai${i}`,
  cycles: "2.3T",
}));

const UploadGames = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

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

      <div className="grid gap-6 grid-auto-fit-xl">
        {data.map(({ canisterId, image, platform, title, cycles }) => (
          <Card
            key={canisterId}
            icon={<Cog8ToothIcon />}
            image={image}
            title={title}
            canisterId={canisterId}
            platform={platform}
            cycles={cycles}
            onClick={() => navigate(`${navPaths.upload_games}/${canisterId}`)}
          />
        ))}
      </div>
    </>
  );
};

export default UploadGames;
