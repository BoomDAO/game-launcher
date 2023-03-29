import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import { useGetUserGames } from "@/api/games";
import Card from "@/components/Card";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
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

  const { data: games = [] } = useGetUserGames();

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
        {games.map(({ canister_id, image, platform, name }) => (
          <Card
            key={canister_id}
            icon={<Cog8ToothIcon />}
            image={image}
            title={name}
            canisterId={canister_id}
            platform={platform}
            // cycles={cycles}
            onClick={() => navigate(`${navPaths.upload_games}/${canister_id}`)}
          />
        ))}
      </div>
    </>
  );
};

export default UploadGames;
