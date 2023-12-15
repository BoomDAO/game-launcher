import React from "react";
import { useTranslation } from "react-i18next";
import Tabs from "@/components/Tabs";
import Divider from "@/components/ui/Divider";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { useGetBoomBalance } from "@/api/guilds";


const GamingGuildBanner = () => {

    const { t } = useTranslation();
    const { data : balance = "0" } = useGetBoomBalance();

    return (
        <>
            <div>
                <section style={{ position: "relative", justifyContent: "center", alignItems: "center" }}>
                    <img src={t("gaming_guilds.banner_image")} className="mb-10" alt="logo" />
                    <div className="w-9/12 rounded-3xl m-auto py-7 dark:bg-white bg-dark text-center">
                        <div className="text-4xl font-semibold gradient-text">Treasury</div>
                        <div className="flex justify-around pt-5">
                            <div className="dark:text-black text-white flex justify-around">
                                <img src="/boom-logo.png" className="pr-2 h-10" />
                                <p className="text-3xl font-medium pt-1" >{balance}</p>
                                <p className="text-xl pt-2 pl-2">BOOM Tokens</p>
                            </div>
                            {/* <div className="dark:text-black text-white flex justify-around">
                                <img src="/boom-logo.png" className="pr-2 h-fit"/>
                                <p className="text-3xl font-medium">100,000</p>
                                <p className="text-xl p-1">TOYO Tokens</p>
                            </div> */}
                        </div>
                    </div>
                </section>
            </div>
        </>
    );
};

export default GamingGuildBanner;
