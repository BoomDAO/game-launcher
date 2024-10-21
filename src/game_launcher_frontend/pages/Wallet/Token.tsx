import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { navPaths } from "@/shared";
import { useDisburseBoomStakes, useDissolveBoomStakes, useGetBoomStakeInfo, useGetTokensInfo } from "@/api/profile";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import toast from "react-hot-toast";
import { useAuthContext } from "@/context/authContext";
import { AccountIdentifier } from "@dfinity/ledger-icp";
import { Principal } from "@dfinity/principal";
import { useGetStakingTexts } from "@/api/common";

const Token = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { session } = useAuthContext();

    const { data, isLoading, isError } = useGetTokensInfo();
    const { data: userStakeData, isLoading: isStakeLoading } = useGetBoomStakeInfo();
    const { data: stakingText } = useGetStakingTexts();

    const { mutate: mutateDissolve, isLoading: isDissolveLoading } = useDissolveBoomStakes();
    const { mutate: mutateDisburse, isLoading: isDisburseLoading } = useDisburseBoomStakes();

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

    const onDissolveClick = () => {
        toast.custom((t) => (
            <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                <div className="w-2/3 rounded-3xl p-0.5 gradient-bg mt-48 inline-block">
                    <div className="h-full w-auto dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <div className="px-4 font-semibold">{stakingText.staking.dissolve_warning}</div>
                        <Button isLoading={isDissolveLoading} className="mx-auto mb-2 mt-3" onClick={() => mutateDissolve()}>PROCEED</Button>
                        <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                    </div>
                </div>
            </div>
        ));
    };

    const onStakingClick = (ledger: string, principal: string) => {
        navigate(navPaths.stake + `/${ledger}`);
    };

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
                                                                (userStakeData?.amount == 0n && userStakeData?.dissolvedAt == 0n && userStakeData?.stakedAt == 0n) ?
                                                                    <Button disabled className="mr-2 h-10 mt-2">
                                                                        Dissolve
                                                                    </Button> : (userStakeData?.dissolvedAt == 0n && userStakeData?.stakedAt != 0n) ?
                                                                        <Button className="text-xs mr-2 h-10 mt-2" onClick={() => { onDissolveClick() }}>
                                                                            Dissolve {(userStakeData?.amount == 10000000000n) ? "ELITE" : "PRO"}
                                                                        </Button> :
                                                                        <Button isLoading={isDisburseLoading} className="mr-2 h-10 mt-2" onClick={() => { mutateDisburse() }}>
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
