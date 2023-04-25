import React from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Tabs from "@/components/Tabs";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";

const UpdateCollection = () => {
  const [activeTab, setActiveTab] = React.useState(1);

  const { t } = useTranslation();
  const { canisterId } = useParams();

  const tabItems = [
    { id: 1, name: t("manage_nfts.update.tabs.item_1") },
    { id: 2, name: t("manage_nfts.update.tabs.item_2") },
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("manage_nfts.title")}</H1>
      <Space size="medium" />

      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === 1 && <div>Hello tehere1</div>}

      {activeTab === 2 && <div>Hello tehere2</div>}
    </>
  );
};

export default UpdateCollection;
