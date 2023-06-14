import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";

const WorldDeployer = () => {
  const { t } = useTranslation();

  return (
    <>
      <Space size="medium" />
      <H1>{t("world_deployer.index.title")}</H1>
      <Space size="medium" />
    </>
  );
};

export default WorldDeployer;
