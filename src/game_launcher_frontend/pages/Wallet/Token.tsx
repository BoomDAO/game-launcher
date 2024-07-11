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
import { useDisburseBoomStakes, useDissolveBoomStakes, useGetBoomStakeInfo, useGetTokensInfo } from "@/api/profile";
import Space from "@/components/ui/Space";
import H1 from "@/components/ui/H1";
import SubHeading from "@/components/ui/SubHeading";
import Divider from "@/components/ui/Divider";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Pagination from "@/components/Pagination";
import toast from "react-hot-toast";
import { useGetUserProfileDetail } from "@/api/profile";
import { useAuthContext } from "@/context/authContext";
import { AccountIdentifier } from "@dfinity/ledger-icp";
import { Principal } from "@dfinity/principal";
import Loader from "@/components/ui/Loader";

const Token = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { session } = useAuthContext();

    const { data, isLoading, isError } = useGetTokensInfo();
    const { data: userStakeData, isLoading: isStakeLoading } = useGetBoomStakeInfo();

    const { mutate : mutateDissolve, isLoading : isDissolveLoading } = useDissolveBoomStakes();
    const { mutate : mutateDisburse, isLoading : isDisburseLoading } = useDisburseBoomStakes();

    const onTransferClick = (ledger: string, principal: string) => {
        navigate(navPaths.transfer + `/${ledger}`);
    };

    const onDepositClick = (principal: string) => {
        toast.custom((t) => (
            <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                <div className="w-2/3 rounded-3xl p-0.5 gradient-bg mt-48 inline-block">
                    <div className="h-full w-auto dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <div className="mt-5 mb-5 text-lg px-10">
                            <b>Principal ID : </b>
                            <p className="">{principal}</p>
                        </div>
                        <div className="mt-5 mb-5 text-lg px-10">
                            <b>Account Identifier : </b>
                            <p className="">{String(AccountIdentifier.fromPrincipal({ principal: Principal.fromText(principal), subAccount: undefined }).toHex())}</p>
                        </div>
                        <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                    </div>
                </div>
            </div>
        ));
    };

    const onStakingClick = (ledger: string, principal: string) => {
        navigate(navPaths.stake + `/${ledger}`);
    };

    // const onDisburseClick = (time : string) => {
    //     toast.custom((t) => (
    //         <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
    //             <div className="w-2/3 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
    //                 <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
    //                     <div className="mt-5 mb-5 text-lg px-10">
    //                         <p>You will have to wait for <span className="gradient-text font-bold">{time}</span> to be able to withdraw/disburse your $BOOM back to your BGG account as tokens must finish dissolve delay of respective tiers before it can be withdrawn to the wallet.</p>
    //                     </div>
    //                     <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
    //                 </div>
    //             </div>
    //         </div>
    //     ));
    // };

    return (
        <>
            <Button className="h-10 mt-6 mb-10" size="big" rightArrow={true} onClick={() => onDepositClick(session?.address || "")}>DEPOSIT TOKENS</Button>
            <div className="w-full flex justify-between">
                <p className="w-1/4 text-2xl">Token</p>
                <p className="w-1/4 text-2xl">Symbol</p>
                <p className="w-1/4 text-2xl">Balance</p>
                <p className="w-1/4 text-2xl">Withdraw</p>
                <p className="w-1/4 text-2xl">Stake</p>
            </div>
            <div className="">
                {isLoading ? (
                    <LoadingResult>{t("wallet.tab_1.tokens_loading")}</LoadingResult>
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
                                                    {t("wallet.tab_1.token_transfer_button_placeholder")}
                                                </Button>
                                            </div>
                                            <div className="flex w-1/4">
                                                {
                                                    (symbol == "BOOM") ?
                                                        <div className="flex">
                                                            <Button className="mr-2 h-10 mt-2" onClick={() => onStakingClick(ledger, data.principal)}>
                                                                {t("wallet.tab_1.token_staking_button_placeholder")}
                                                            </Button>
                                                            {
                                                                (userStakeData?.dissolvedAt == 0n) ? <Button isLoading={isDissolveLoading} className="mr-2 h-10 mt-2" onClick={() => {mutateDissolve()}}>
                                                                    Dissolve 
                                                                </Button> : <Button isLoading={isDisburseLoading} className="mr-2 h-10 mt-2" onClick={() => {mutateDisburse()}}>
                                                                    Disburse
                                                                </Button>
                                                            }
                                                        </div> :
                                                        <Button disabled className="mr-2 h-10 mt-2">
                                                            NA
                                                        </Button>
                                                }

                                            </div>
                                        </div>
                                        <div className="w-full h-px gradient-bg opacity-25"></div>
                                    </div>
                                ))}
                            </div>
                        </>
                    ) : (
                        <NoDataResult>{t("wallet.tab_1.no_tokens")}</NoDataResult>
                    )}
            </div>
        </>
    );
}

export default Token;
