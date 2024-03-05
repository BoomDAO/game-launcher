import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { ErrorResult } from "@/components/Results";
import Box from "@/components/ui/Box";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";
import { useGetTrustedOrigins } from "@/api/world_deployer";

const ViewTrustedOrigins = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { mutate, data, isLoading } = useGetTrustedOrigins();

  return (
    <div>
      <SubHeading>{t("world_deployer.manage_worlds.tabs.item_4.view.title")}</SubHeading>
      <Space />

      <Button
        size="big"
        rightArrow
        onClick={() => mutate({ canisterId })}
        isLoading={isLoading}
      >
        {t("world_deployer.manage_worlds.tabs.item_4.view.button")}
      </Button>

      <Space />

      {!data ? null : !data.length ? (
        <ErrorResult>{t("world_deployer.manage_worlds.tabs.item_4.view.error")}</ErrorResult>
      ) : (
        <Box className="h-[300px] overflow-auto ">
          {data.map((item, index) => (
            <div key={index}>{item}</div> 
          ))}
        </Box>
      )}
    </div>
  );
};

export default ViewTrustedOrigins;
