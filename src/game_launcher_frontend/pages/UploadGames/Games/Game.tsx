import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";

import Visibility from "./Visibility";
import UpdateGame from "./UpdateGame";

const Game = () => {
  const [activeTab, setActiveTab] = React.useState(1);

  const { t } = useTranslation();

  const tabItems = [
    { id: 1, name: t("upload_games.Game.tab_1.title") },
    { id: 2, name: t("upload_games.Game.tab_2.title") },
  ];

  return (
    <>
      <Space size="medium" />
      <H1>{t("upload_games.Game.title")}</H1>
      <Space size="medium" />

      <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

      {activeTab === 1 && (
        <div className="w-full space-y-12">
          <UpdateGame />
        </div>
      )}
      {activeTab === 2 && (
        <div className="w-full space-y-12">
          < Visibility />
        </div>
      )}
    </>
  );
};

export default Game;
