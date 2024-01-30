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
import { useGetWalletInfo, useIcrcTransfer } from "@/api/profile";
import Space from "@/components/ui/Space";
import H1 from "@/components/ui/H1";
import SubHeading from "@/components/ui/SubHeading";
import Divider from "@/components/ui/Divider";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Pagination from "@/components/Pagination";
import toast from "react-hot-toast";
import { useGetUserProfileDetail } from "@/api/profile";

const Wallet = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();


    const { data: userProfile } = useGetUserProfileDetail();
    const { data, isLoading, isError } = useGetWalletInfo();

    const onTransferClick = (ledger: string, principal: string) => {
        navigate(navPaths.transfer + `/${ledger}`);
    };

    const onDepositClick = (address: string, principal: string) => {
        toast.custom((t) => (
            <div className="w-2/3 rounded-3xl mb-7 p-0.5 gradient-bg mt-40 backdrop-blur-sm">
                <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                    <div className="mt-5 mb-5 text-lg px-10">
                        <p>To deposit tokens, please transfer them to the below</p>
                        <b className="">Principal ID</b>
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
            <Space />
            <div className="gradient-text">
                <SubHeading>Hello {userProfile?.username}, Here are your Tokens!</SubHeading>
            </div>
            <Space />
            <div className="w-full flex justify-between">
                <p className="w-1/4 text-2xl">Token</p>
                <p className="w-1/4 text-2xl">Symbol</p>
                <p className="w-1/4 text-2xl">Balance</p>
                <p className="w-1/4 text-2xl">Actions</p>
            </div>
            <Space/>
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("wallet.tokens_loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    data.tokens.length ? (
                        <>
                            <div className="w-full">
                                {data.tokens.map(({ name, symbol, logo, balance, fee, ledger }) => (
                                    <div key={symbol}>
                                        <div className="flex justify-around my-4 text-lg">
                                            <div className="flex w-1/4">
                                                <img src={logo} className="h-14 w-14" />
                                                <p className="pl-2 pt-4 font-light">{name}</p>
                                            </div>
                                            <p className="w-1/4 pl-1 pt-4 font-light">{symbol}</p>
                                            <p className="w-1/4 pl-1 pt-4 font-light">{balance}</p>
                                            <div className="flex w-1/4">
                                                <Button className="mr-2 h-10 mt-2" onClick={() => onTransferClick(ledger, data.principal)}>
                                                    {t("wallet.token_transfer_button_placeholder")}
                                                </Button>
                                                <Button className="h-10 mt-2" onClick={() => { onDepositClick(data.address, data.principal); }}>
                                                    {t("wallet.token_receiver_button_placeholder")}
                                                </Button>
                                            </div>
                                        </div>
                                        <div className="w-full h-px gradient-bg opacity-25"></div>
                                    </div>
                                ))}
                            </div>
                        </>
                    ) : (
                        <NoDataResult>{t("wallet.no_tokens")}</NoDataResult>
                    )}
            </div>
        </>
    );
}

export default Wallet;
