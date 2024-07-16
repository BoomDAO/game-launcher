import { useGetTwitterTexts } from "@/api/common";
import { useAuthContext } from "@/context/authContext";
import React from "react";
import { useTranslation } from "react-i18next";


const TwitterPost = () => {


    const { t } = useTranslation();
    const { session } = useAuthContext();
    const { data, isLoading } = useGetTwitterTexts();

    return (
        <>
            {
                (!isLoading) ? <div>
                    <p className="font-bold text-xl pb-2 gradient-text">{data.twitter_quest.title}</p>
                    {/* <p className="font-semibold text-sm pb-4">Click <span className="text-sky-500">Tweet It!</span> button below to share this to twitter and <span className="text-sky-500">Tag 3 friends</span> to get rewarded with BOOM tokens. <br></br>Your post will be verified in the next 24 hours and rewards will be disbursed.</p> */}
                    <p className="font-semibold text-sm pb-4">{data.twitter_quest.pop_up_text}</p>
                    {/* <div className="gradient-bg rounded-2xl p-1">
                        <div className="bg-white rounded-2xl"> */}
                    {/* <div className="mx-4 px-2 cursor-default font-semibold text-black pt-5" id="post">
                        I joined the BOOM Gaming Guilds and I received 100 BOOM tokens for doing quests in $ICP games!<br></br>
                        <p className="text-blue-600">👉 guilds.boomdao.xyz/ 👈</p>
                        <p>Sign up now to earn tokens & memecoins!🏆</p>
                        <p className="text-blue-600">#BOOMGUILD</p>
                        ID : {(session?.address)}
                    </div> */}
                    <button id="button1" className="bg-sky-400 text-white font-semibold py-2 px-3 rounded-xl mb-4 mt-2" onClick={() => {
                        let address = session?.address;
                        let url = data.twitter_quest.link;
                        window.open(url, "_blank");
                    }}>{data.twitter_quest.button_placeholder}</button>
                    {/* </div>
                    </div> */}
                </div> : <></>
            }
        </>
    );
};

export default TwitterPost;
