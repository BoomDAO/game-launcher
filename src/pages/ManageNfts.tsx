import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import Card from "@/components/Card";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";

const data = Array.from({ length: 9 }).map((_, i) => ({
  title: `Collection 0${i}`,
  image: "/banner.png",
  canisterId: `r44we3-pqaaa-aaaap-aaosq-cai${i}`,
  cycles: "2.3T",
}));

const ManageNfts = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <>
      <Space size="medium" />

      <Button
        size="big"
        rightArrow
        onClick={() => navigate(`${navPaths.manage_nfts}/new`)}
      >
        {t("create_new_nft_collection")}
      </Button>

      <Space />

      <H1>{t("previously_created_collections")}</H1>

      <Space size="medium" />

      <div className="grid gap-6 grid-auto-fit-xl">
        {data.map(({ canisterId, title, cycles }) => (
          <Card
            key={canisterId}
            icon={<Cog8ToothIcon />}
            title={title}
            canisterId={canisterId}
            cycles={cycles}
            onClick={() => navigate(`${navPaths.manage_nfts}/${canisterId}`)}
          />
        ))}
      </div>
    </>
  );
};

export default ManageNfts;
