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
import toast from "react-hot-toast";


const GamingGuilds = () => {
    const [activeTab, setActiveTab] = React.useState(1);
    const { t } = useTranslation();

    const tabItems = [
        { id: 1, name: t("gaming_guilds.items.item_1.title") },
        { id: 2, name: t("gaming_guilds.items.item_2.title") }
    ];

    React.useEffect(() => {
        let details = navigator.userAgent;
        let regexp = /android|iphone|kindle|ipad/i;
        let isMobileDevice = regexp.test(details);
        if (isMobileDevice) {
            toast.custom((t) => (
                <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                    <div className="w-full rounded-3xl mb-7 p-1 gradient-bg mt-60 inline-block">
                        <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center ">
                            <p className="mb-4 font-semibold">This website is not optimized for mobile and should only be accessed on desktop.</p>
                            <Button size="normal" onClick={() => toast.remove()} className="m-0 inline-block">Close</Button>
                        </div>
                    </div>
                </div>
            ));
        };
    }, []);

    return (
        <>
            <GamingGuildBanner />
            <div className="flex justify-around">
                <div className="w-full">
                    <GuildTabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />
                    {activeTab === 1 && (
                        <div className="w-full space-y-12">
                            <Quests />
                        </div>
                    )}
                    {activeTab === 2 && (
                        <div className="w-full space-y-12">
                            <Members />
                        </div>
                    )}
                </div>
            </div>
        </>
    );
};

export default GamingGuilds;
