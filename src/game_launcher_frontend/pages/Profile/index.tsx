import React from "react";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import Space from "@/components/ui/Space";
import H1 from "@/components/ui/H1";
import Tabs from "@/components/Tabs";
import EditImage from "./EditImage";
import EditUsername from "./EditUsername";
import { navPaths } from "@/shared";

const Profile = (props: {activeTab : string}) => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [activeTab, setActiveTab] = React.useState((props.activeTab == "Picture")? 1 : 2);

    const tabItems = [
        { id: 1, name: t("profile.edit.tab_1.title"), url: navPaths.profile_picture },
        { id: 2, name: t("profile.edit.tab_2.title"), url: navPaths.profile_username },
      ];

    return (
        <>
            <Space size="medium" />
            <H1>{t("profile.edit.title")}</H1>
            <Space size="medium" />
            <Tabs tabs={tabItems} active={activeTab} setActive={setActiveTab} />

            {activeTab === 1 && (
                <div className="w-full space-y-12">
                    < EditImage />
                </div>
            )}
            {activeTab === 2 && (
                <div className="w-full space-y-12">
                    < EditUsername />
                </div>
            )}
        </>
    );
}

export default Profile;
