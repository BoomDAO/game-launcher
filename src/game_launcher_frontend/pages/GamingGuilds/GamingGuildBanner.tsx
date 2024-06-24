import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { useGetBoomBalance } from "@/api/guilds";
import { TypeAnimation } from 'react-type-animation';
import { useGetTexts } from "@/api/common";
import { useBreakpoint } from "src/game_launcher_frontend/hooks/useBreakpoint";
import { TypeSpeed } from "@/types";
import { cx } from "@/utils";
import Loader from "@/components/ui/Loader";


const GamingGuildBanner = () => {
    const { data, isLoading } = useGetTexts();
    const { smallHeight } = useBreakpoint();

    return (
        <>
            <div className="h-200">
                <section style={{ position: "relative", justifyContent: "center", alignItems: "center" }}>
                    {
                        isLoading ? <Loader className="w-20"></Loader> :
                            <TypeAnimation
                                sequence={data.home.title_sequence}
                                speed={20}
                                style={{ fontSize: '2.5em' }}
                                repeat={Infinity}
                                className={cx(
                                    "ml-28 mt-20 gradient-text flex items-center pr-4 text-center font-black",
                                )}
                            />
                    }
                </section>
            </div>
        </>
    );
};

export default GamingGuildBanner;
