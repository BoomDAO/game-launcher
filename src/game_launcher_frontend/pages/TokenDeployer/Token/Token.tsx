import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import AllowTransfer from "./AllowTransfer";
import Transfer from "./Transfer";
import TransferFrom from "./TransferFrom";
import ViewTrustedOrigins from "../../WorldDeployer/ManageWorlds/ViewTrustedOrigins";
import TrustedOrigins from "../../WorldDeployer/ManageWorlds/TrustedOrigins";

const Token = () => {
  const [activeTab, setActiveTab] = React.useState(1);

  const { t } = useTranslation();

  const tabItems = [
    { id: 1, name: t("token_deployer.token.tabs.item_1") },
    { id: 2, name: t("token_deployer.token.tabs.item_2") },
    { id: 3, name: t("world_deployer.manage_worlds.tabs.item_5.title") }
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("token_deployer.token.title")}</H1>
      <Space size="medium" />

      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === 1 && (
        <div className="w-full space-y-12">
          <Transfer/>
        </div>
      )}
      {activeTab === 2 && (
        <div className="w-full space-y-12">
          < AllowTransfer />
          <Divider/>
          <TransferFrom/>
        </div>
      )}
      {activeTab === 3 && (
        <div className="w-full space-y-12">
          < ViewTrustedOrigins/>
          <Divider/>
          <TrustedOrigins/>
        </div>
      )}
    </>
  );
};

export default Token;
