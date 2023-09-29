import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import Configure from "./Configure";
import ImportUser from "./ImportUser";
import ImportConfig from "./ImportConfig";
import ImportPermissions from "./ImportPermissions";
import ManageController from "./ManageController";
import ManageAdmin from "./ManageAdmin";
import UpgradeWorld from "./UpgradeWorld";
import ImportActions from "./ImportActions";

const ManageWorlds = () => {
  const [activeTab, setActiveTab] = React.useState(1);

  const { t } = useTranslation();

  const tabItems = [
    { id: 1, name: t("world_deployer.manage_worlds.tabs.item_1.title") },
    { id: 2, name: t("world_deployer.manage_worlds.tabs.item_2.title") },
    { id: 3, name: t("world_deployer.manage_worlds.tabs.item_3.title") },
    { id: 4, name: t("world_deployer.manage_worlds.tabs.item_4.title") }
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("world_deployer.manage_worlds.title")}</H1>
      <Space size="medium" />
      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === 1 && (
        <div className="w-full space-y-12">
          < Configure />
        </div>
      )}
      {activeTab === 2 && (
        <div className="w-full space-y-12">
          < ImportUser />
          <Divider/>
          < ImportConfig />
          <Divider/>
          <ImportActions />
          <Divider/>
          <ImportPermissions/>
        </div>
      )}
      {activeTab === 3 && (
        <div className="w-full space-y-12">
          < ManageController />
          <Divider/>
          <ManageAdmin/>
        </div>
      )}
      {activeTab === 4 && (
        <div className="w-full space-y-12">
          < UpgradeWorld />
        </div>
      )}
    </>
  );
};

export default ManageWorlds;
