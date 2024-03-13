import { useAuthContext } from "@/context/authContext";
import React from "react";
import { useTranslation } from "react-i18next";


const TwitterPost = () => {
    

    const { t } = useTranslation();
    const { session } = useAuthContext();
    return (
        <>
            <p className="font-bold text-xl pb-2 gradient-text">POST ON TWITTER</p>
            <p className="font-semibold text-sm pb-4">Click <span className="text-sky-500">Tweet It!</span> button below to share this to twitter and <span className="text-sky-500">Tag 3 friends</span> to get rewarded with BOOM tokens. <br></br>Your post will be verified in the next 24 hours and rewards will be disbursed.</p>
            <div className="gradient-bg rounded-2xl p-1">
                <div className="bg-white rounded-2xl">
                    <div className="mx-4 px-2 cursor-default font-semibold text-black pt-5" id="post">
                        I joined the BOOM Gaming Guilds and I received 100 BOOM tokens for doing quests in $ICP games!<br></br>
                        <p className="text-blue-600">👉 guilds.boomdao.xyz/ 👈</p>
                        <p>Sign up now to earn tokens & memecoins!🏆</p>
                        <p className="text-blue-600">#BOOMGUILD</p>
                        ID : {(session?.address)}
                    </div>
                    <button id="button1" className="bg-sky-400 text-white font-semibold py-2 px-3 rounded-xl mb-4 mt-2" onClick={() => { 
                        let address = session?.address;
                        let url = "https://twitter.com/intent/post?text=I%20joined%20the%20BOOM%20Gaming%20Guilds%20and%20I%20received%20100%20BOOM%20tokens%20for%20doing%20quests%20in%20%24ICP%20games!%0D%0A%0D%0A%F0%9F%91%89%20guilds.boomdao.xyz%2F%20%F0%9F%91%88%0D%0A%0D%0ASign%20up%20now%20to%20earn%20tokens%20%26%20memecoins!%F0%9F%8F%86%0D%0A%0D%0A%23BOOMGUILD%0D%0A%0D%0AID%3A%20" + address;
                        window.open(url, "_blank");
                    }}>Tweet It!</button>
                </div>
            </div>
        </>
    );
};

export default TwitterPost;
