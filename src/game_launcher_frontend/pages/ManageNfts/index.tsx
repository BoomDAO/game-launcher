import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import Nfts from "./Nfts";
import AllNfts from "./AllNfts";

const TokenDeployer = () => {
  const [activeTab, setActiveTab] = React.useState(1);

  const { t } = useTranslation();

  const tabItems = [
    { id: 1, name: t("manage_nfts.index.tabs.item_1") },
    { id: 2, name: t("manage_nfts.index.tabs.item_2") }
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("manage_nfts.index.title")}</H1>
      <Space size="medium" />

      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === 1 && (
        <div className="w-full space-y-12">
          < Nfts />
        </div>
      )}
      {activeTab === 2 && (
        <div className="w-full space-y-12">
          < AllNfts />
        </div>
      )}
    </>
  );
};

export default TokenDeployer;
