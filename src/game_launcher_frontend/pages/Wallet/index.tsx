import React from "react";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import Space from "@/components/ui/Space";
import H1 from "@/components/ui/H1";
import Tabs from "@/components/Tabs";
import SubHeading from "@/components/ui/SubHeading";
import { useGetUserProfileDetail } from "@/api/profile";
import Token from "./Token";
import Nft from "./Nft";

const Wallet = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [activeTab, setActiveTab] = React.useState(1);

    const { data: userProfile } = useGetUserProfileDetail();

    const tabItems = [
        { id: 1, name: t("wallet.tab_1.title") },
        { id: 2, name: t("wallet.tab_2.title") },
      ];

    return (
        <>
            <Space />
            <div className="gradient-text">
                <SubHeading>Hello {userProfile?.username}, Here are your Fungies-Nonfungies!</SubHeading>
            </div>
            <Space />
            <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

            {activeTab === 1 && (
                <div className="w-full space-y-12">
                    < Token />
                </div>
            )}
            {activeTab === 2 && (
                <div className="w-full space-y-12">
                    <Nft/>
                </div>
            )}
        </>
    );
}

export default Wallet;
