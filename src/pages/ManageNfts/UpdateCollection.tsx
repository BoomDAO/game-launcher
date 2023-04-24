import React from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Tabs from "@/components/Tabs";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";

const canisterId = "jh775-jaaaa-aaaal-qbuda-cai";

const UpdateCollection = () => {
  const [activeTab, setActiveTab] = React.useState("View");

  const { t } = useTranslation();
  // const { canisterId } = useParams();

  const tabItems = [
    t("manage_nfts.update.tabs.item_1"),
    t("manage_nfts.update.tabs.item_2"),
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("upload_games.update.title")}</H1>
      <Space size="medium" />

      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === t("manage_nfts.update.tabs.item_1") && (
        <div>Hello tehere1</div>
      )}

      {activeTab === t("manage_nfts.update.tabs.item_2") && (
        <div>Hello tehere2</div>
      )}
    </>
  );
};

export default UpdateCollection;
