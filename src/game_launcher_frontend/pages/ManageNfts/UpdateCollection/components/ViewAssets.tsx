import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { useGetAssetIds} from "@/api/minting_deployer";
import { ErrorResult } from "@/components/Results";
import Box from "@/components/ui/Box";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const ViewAssets = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { mutate, data, isLoading } = useGetAssetIds();

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.assets.view.title")}</SubHeading>
      <Space />

      <Button
        size="big"
        rightArrow
        onClick={() => mutate({ canisterId })}
        isLoading={isLoading}
      >
        {t("manage_nfts.update.assets.view.button")}
      </Button>

      <Space />

      {!data ? null : !data.length ? (
        <ErrorResult>{t("manage_nfts.update.assets.view.error")}</ErrorResult>
      ) : (
        <Box className="h-[300px] overflow-auto ">
          {data.map((item) => (
            <div key={item}>{item}</div>
          ))}
        </Box>
      )}
    </div>
  );
};

export default ViewAssets;
