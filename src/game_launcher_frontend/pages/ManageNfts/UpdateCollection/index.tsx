import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import Airdrop from "./components/Airdrop";
import BurnNft from "./components/BurnNft";
import GetTokenMetadata from "./components/GetTokenMetadata";
import GetTokenRegistry from "./components/GetTokenRegistry";
import ManageAdmin from "./components/ManageAdmin";
import ManageController from "./components/ManageController";
import Mint from "./components/Mint";
import UploadAsset from "./components/UploadAsset";
import ViewAssets from "./components/ViewAssets";
import ViewAsset from "./components/ViewAsset";
import ViewTrustedOrigins from "../../WorldDeployer/ManageWorlds/ViewTrustedOrigins";
import TrustedOrigins from "../../WorldDeployer/ManageWorlds/TrustedOrigins";

const UpdateCollection = () => {
  const [activeTab, setActiveTab] = React.useState(1);

  const { t } = useTranslation();

  const tabItems = [
    { id: 1, name: t("manage_nfts.update.tabs.item_1") },
    { id: 2, name: t("manage_nfts.update.tabs.item_2") },
    { id: 3, name: t("manage_nfts.update.tabs.item_3") },
    { id: 4, name: t("manage_nfts.update.tabs.item_4") },
    { id: 5, name: t("manage_nfts.update.tabs.item_5") },
    { id: 6, name: t("manage_nfts.update.tabs.item_6") },
    { id: 7, name: t("world_deployer.manage_worlds.tabs.item_5.title") }
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("manage_nfts.update.title")}</H1>
      <Space size="medium" />

      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === 1 && (
        <div className="w-full space-y-12">
          <GetTokenRegistry />
          <Divider />
          <GetTokenMetadata />
        </div>
      )}

      {activeTab === 2 && (
        <div className="w-full space-y-12">
          <ManageAdmin />
          <Divider />
          <ManageController />
        </div>
      )}

      {activeTab === 3 && (
        <div className="w-full space-y-12">
          <UploadAsset />
          <Divider/>
          <ViewAssets/>
          <Divider/>
          <ViewAsset/>
        </div>
      )}

      {activeTab === 4 && (
        <div className="w-full space-y-12">
          <Mint />
        </div>
      )}

      {activeTab === 5 && (
        <div className="w-full space-y-12">
          <Airdrop />
        </div>
      )}

      {activeTab === 6 && (
        <div className="w-full space-y-12">
          <BurnNft/>
        </div>
      )}

      {activeTab === 7 && (
        <div className="w-full space-y-12">
          <ViewTrustedOrigins/>
          <Divider/>
          <TrustedOrigins/>
        </div>
      )}
    </>
  );
};

export default UpdateCollection;
