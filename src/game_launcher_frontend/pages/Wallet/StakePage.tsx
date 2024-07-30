import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { getTokenSymbol } from "@/api/profile";
import Loader from "@/components/ui/Loader";
import { useAuthContext } from "@/context/authContext";
import { useBoomLedgerClient, useGamingGuildsClient, useICRCLedgerClient } from "@/hooks";
import { useEliteStakeBoomTokens, useProStakeBoomTokens } from "@/api/profile";
import { useGetStakingTexts } from "@/api/common";
import Hint from "@/components/ui/Hint";
import toast from "react-hot-toast";
import { AccountIdentifier } from "@dfinity/ledger-icp";
import { Principal } from "@dfinity/principal";

const StakePage = () => {
    const { t } = useTranslation();
    const { canisterId } = useParams();
    const { session } = useAuthContext();
    let [transferAmount, setTransferAmount] = React.useState("");
    let [isTransferAmountLoading, setIsTransferAmountLoading] = React.useState(false);
    let [userStake, setUserStake] = React.useState("");
    let [info, setInfo] = React.useState(false);

    const { mutate: proMutate, isLoading: isProStakeBoomLoading } = useProStakeBoomTokens();
    const { mutate: eliteMutate, isLoading: isEliteStakeBoomLoading } = useEliteStakeBoomTokens();

    React.useEffect(() => {
        (async () => {
            if (canisterId != undefined) {
                setIsTransferAmountLoading(true);
                const { actor, methods } = await useBoomLedgerClient();
                const guild = await useGamingGuildsClient();
                let balance = await actor[methods.icrc1_balance_of]({
                    owner: session?.identity?.getPrincipal(),
                    subaccount: []
                }) as number;
                let stake = await guild.actor[guild.methods.getUserBoomStakeTier](session?.address) as {
                    ok: undefined | string,
                    err: undefined | string
                };
                let fee = await actor[methods.icrc1_fee]() as number;
                let transfer_amount = balance - fee;
                if (transfer_amount < 0) {
                    transfer_amount = 0;
                }
                let res = ((Number(transfer_amount) * 1.0) / 100000000.0).toFixed(8);
                setTransferAmount(res);
                if (stake.ok != undefined) {
                    setUserStake(stake.ok);
                }
                setIsTransferAmountLoading(false);
            }
        })();
        return () => {
        };
    }, [canisterId, userStake, transferAmount, isEliteStakeBoomLoading, isProStakeBoomLoading]);

    const onDepositClick = (principal: string) => {
        toast.custom((t) => (
            <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                <div className="w-2/3 rounded-3xl p-0.5 gradient-bg mt-48 inline-block">
                    <div className="h-full w-auto dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <div className="mt-5 mb-5 text-lg px-10">
                            <b>Principal ID : </b>
                            <p className="">{principal}</p>
                        </div>
                        <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                    </div>
                </div>
            </div>
        ));
    };

    return (
        <>
            <div className="">
                <div className="text-center font-bold pb-4 text-lg">Stake BOOM tokens for Early Sale Access</div>
                <div className="flex pl-2 pb-2">
                    <div className="flex pt-1.5">Available $BOOM to Stake : {
                        isTransferAmountLoading ? <Loader className="w-6 h-6 ml-2"></Loader> : <p className="ml-2">{transferAmount}</p>
                    }</div>
                    <Button className="text-white ml-4 " size="small" onClick={() => { onDepositClick(session?.address || "") }}>DEPOSIT BOOM</Button>
                </div>
                {
                    (isTransferAmountLoading) ? <Loader className="w-8"></Loader> :
                        (userStake != "") ? <div className="flex gradient-text">
                            <img src="/congo.svg" className="w-6" />
                            <p className="pl-2">Hey! you are <b>{userStake} BOOM Staker</b>.</p>
                            {(userStake == "PRO") ? <p>You can always upgrade to ELITE tier by clicking on Upgrade button below.</p> : <></>}
                        </div> : <></>
                }
                <div className="flex pt-4 pb-2 justify-around">
                    <div className="w-5/12 border-2 text-center rounded-3xl text-white bg-blue-400 border-blue-500">
                        <img className="w-20 mx-auto mt-8 mb-4" src="/boom-logo.png" />
                        <div className="font-bold text-lg text-blue-600">ELITE BOOM STAKER</div>
                        <div className="w-auto inline-block mt-8">
                            <div className="flex">
                                <div className="flex font-semibold text-base">STAKE : </div>
                                <div className="pl-1">100 BOOM Tokens</div>
                            </div>
                            <div className="flex">
                                <div className="flex font-semibold text-base">
                                    <p>DELAY</p>
                                    <div className="-translate-y-0.5"><Hint right>{t("wallet.tab_1.staking.delay_info_button")}</Hint></div>
                                </div>
                                <div className="pl-1">: 24 HOURS</div>
                            </div>
                            <div className="flex">
                                <div className="flex font-semibold text-base">BENEFITS : </div>
                                <div className="pl-1 text-left">
                                    <div>1st Priority Whitelist <br /> for Token Launches</div>
                                </div>
                            </div>
                        </div>
                        {
                            (isTransferAmountLoading) ? <Loader className="w-8 mx-auto my-4"></Loader> :
                                (userStake != "ELITE" && userStake == "PRO") ? <Button className="w-auto mx-auto my-4" isLoading={isEliteStakeBoomLoading} onClick={() => { eliteMutate({ balance: BigInt(Math.floor(parseFloat(transferAmount)) * 100000000) }) }} >UPGRADE</Button> :
                                    (userStake != "ELITE") ? <Button className="w-auto mx-auto my-4" isLoading={isEliteStakeBoomLoading} onClick={() => { eliteMutate({ balance: BigInt(Math.floor(parseFloat(transferAmount)) * 100000000) }) }} >STAKE</Button> :
                                        <Button className="w-auto mx-auto my-4" disabled isLoading={isEliteStakeBoomLoading}>STAKE</Button>
                        }
                    </div>
                    <div className="w-5/12 border-2 text-center rounded-3xl text-white bg-emerald-600 border-green-700">
                        <img className="w-20 mx-auto mt-8 mb-4" src="/boom-logo.png" />
                        <div className="font-bold text-lg text-emerald-800">PRO BOOM STAKER</div>
                        <div className="w-auto inline-block mt-8">
                            <div className="flex">
                                <div className="flex font-semibold text-base">STAKE : </div>
                                <div className="pl-1">50 BOOM Tokens</div>
                            </div>
                            <div className="flex">
                                <div className="flex font-semibold text-base">
                                    <p>DELAY</p>
                                    <div className="-translate-y-0.5"><Hint>{t("wallet.tab_1.staking.delay_info_button")}</Hint></div>
                                </div>
                                <div className="pl-1">: 24 HOURS</div>
                            </div>
                            <div className="flex">
                                <div className="flex font-semibold text-base">BENEFITS : </div>
                                <div className="pl-1 text-left">
                                    <div>2nd Priority Whitelist <br /> for Token Launches</div>
                                </div>
                            </div>
                        </div>
                        {
                            (isTransferAmountLoading) ? <Loader className="w-8 mx-auto my-4"></Loader> :
                                (userStake != "") ? <Button className="w-auto mx-auto my-4" disabled isLoading={isProStakeBoomLoading} onClick={() => { proMutate({ balance: BigInt(Math.floor(parseFloat(transferAmount)) * 100000000) }) }}>STAKE</Button> :
                                    <Button className="w-auto mx-auto my-4" isLoading={isProStakeBoomLoading} onClick={() => { proMutate({ balance: BigInt(Math.floor(parseFloat(transferAmount)) * 100000000) }) }}>STAKE</Button>
                        }
                    </div>
                </div>
            </div>
        </>
    );
}

export default StakePage;
