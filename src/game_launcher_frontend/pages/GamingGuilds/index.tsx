import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import GamingGuildBanner from "./GamingGuildBanner";
import GuildTabs from "@/components/GuildTabs";
import Button from "@/components/ui/Button";
import Members from "./Members";
import Quests from "./Quests";


const GamingGuilds = () => {
    const [activeTab, setActiveTab] = React.useState(1);
    const { t } = useTranslation();

    const tabItems = [
        { id: 1, name: t("gaming_guilds.items.item_1.title") },
        { id: 2, name: t("gaming_guilds.items.item_2.title") }
    ];

    return (
        <>
            <GamingGuildBanner />
            <Space size="medium" />
            <div className="flex justify-around">
                <div className="w-full">
                    <GuildTabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />
                    {activeTab === 1 && (
                        <div className="w-full space-y-12">
                            <Quests/>
                        </div>
                    )}
                    {activeTab === 2 && (
                        <div className="w-full space-y-12">
                            <Members/>
                        </div>
                    )}
                </div>
            </div>
        </>
    );
};

export default GamingGuilds;
