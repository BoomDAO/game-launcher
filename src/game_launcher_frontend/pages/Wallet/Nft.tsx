import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { navPaths } from "@/shared";
import { useSubmitEmail } from "@/api/guilds";
import Tokens from "../../locale/en/Tokens.json";
import { useGetUserNftsInfo, useIcrcTransfer } from "@/api/profile";
import Space from "@/components/ui/Space";
import H1 from "@/components/ui/H1";
import SubHeading from "@/components/ui/SubHeading";
import Divider from "@/components/ui/Divider";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Pagination from "@/components/Pagination";
import toast from "react-hot-toast";
import { useGetUserProfileDetail } from "@/api/profile";

const Nft = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [display, setDisplay] = React.useState(false);

    const { data, isLoading, isError } = useGetUserNftsInfo();

    const onTransferClick = (canister: string, tokenid: string) => {
        navigate(navPaths.nftTransfer + `/${canister}` + `/${tokenid}`);
    };

    const onDepositClick = (principal: string) => {
        toast.custom((t) => (
            <div className="w-2/3 rounded-3xl mb-7 p-0.5 gradient-bg mt-40 backdrop-blur-xl">
                <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                    <div className="mt-5 mb-5 text-lg px-10">
                        <b>To deposit NFTs, please transfer them to the below Principal ID : </b>
                        <p className="">{principal}</p>
                    </div>
                    <Button onClick={() => toast.remove()} className="float-right mb-3">Close</Button>
                </div>
            </div>
        ), {
            position: 'top-center'
        });
    };

    return (
        <>
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("wallet.tab_2.nfts_loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    data.length ? (
                        <>
                            <div className="w-full">
                                {data.map(({ name, logo, balance, canister, url, nfts, principal }) => (
                                    <div key={canister}>
                                        <div className="flex mb-4">
                                            <img src={logo} className="w-16 h-16 m-2" />
                                            <p className="text-3xl ml-2 mt-6 font-semibold">{name}</p>
                                            <Button className="h-10 mt-6 ml-6" onClick={() => setDisplay(!display)}>VIEW</Button>
                                            <Button className="h-10 mt-6 ml-6" onClick={() => onDepositClick(principal)}>DEPOSIT</Button>
                                        </div>
                                        <div>
                                            {display ? <div className="grid grid-cols-6 gap-0">
                                                {nfts.map((id) => (
                                                    <img key={id} onClick={() => onTransferClick(canister, id)} className="w-40 h-40 object-cover mb-5 cursor-pointer" src={"https://" + canister + ".raw.icp0.io/?type=thumbnail&tokenid=" + id} />
                                                ))}
                                            </div> : <></>}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </>
                    ) : (
                        <NoDataResult>{t("wallet.tab_2.no_nfts")}</NoDataResult>
                    )}
            </div>
        </>
    );
}

export default Nft;
