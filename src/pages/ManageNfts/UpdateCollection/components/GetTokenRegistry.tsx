import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { useGetTokenRegistry } from "@/api/minting_deployer";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const GetTokenRegistry = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { mutate, data, isLoading } = useGetTokenRegistry();

  console.log("data", data);

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.view.registry.title")}</SubHeading>
      <Space />

      <Button
        size="big"
        rightArrow
        onClick={() => mutate({ canisterId })}
        isLoading={isLoading}
      >
        {t("manage_nfts.update.view.registry.button")}
      </Button>
    </div>
  );
};

export default GetTokenRegistry;
