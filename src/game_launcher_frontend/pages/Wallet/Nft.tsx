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
import { useDisburseNft, useDissolveNft, useGetUserNftsInfo, useIcrcTransfer, useStakeNft } from "@/api/profile";
import Space from "@/components/ui/Space";
import H1 from "@/components/ui/H1";
import SubHeading from "@/components/ui/SubHeading";
import Divider from "@/components/ui/Divider";
import { ErrorResult, LoadingResult, NoDataResult } from "@/components/Results";
import Pagination from "@/components/Pagination";
import toast from "react-hot-toast";
import { useGetUserProfileDetail } from "@/api/profile";
import { useAuthContext } from "@/context/authContext";

const Nft = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { session } = useAuthContext();

    const { data, isLoading, isError } = useGetUserNftsInfo();
    const { mutate: mutateStake, isLoading: isStaking } = useStakeNft();
    const { mutate: mutateDissolve, isLoading: isDissolving } = useDissolveNft();
    const { mutate: mutateDisburse, isLoading: isDisbursing } = useDisburseNft();

    const onTransferClick = (canister: string, tokenid: string) => {
        navigate(navPaths.nftTransfer + `/${canister}` + `/${tokenid}`);
    };

    const onDepositClick = (principal: string) => {
        toast.custom((t) => (
            <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                <div className="w-2/3 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
                    <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <div className="mt-5 mb-5 text-lg px-10">
                            <b>To deposit NFTs, please transfer them to the below Principal ID : </b>
                            <p className="">{principal}</p>
                        </div>
                        <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                    </div>
                </div>
            </div>
        ));
    };

    const onStakeClick = (canister: string, index: Number, id: string) => {
        toast.custom((t) => (
            <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                <div className="w-2/3 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
                    <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <div className="mt-5 mb-5 text-lg px-10">
                            <b>After staking an NFT for a quest, if you wish to unstake the NFT it will take 24 hours to dissolve and be ready to disburse. The NFT must finish dissolving before it can be withdrawn to the wallet.</b>
                            <Button onClick={() => {
                                toast.remove();
                                mutateStake({ collectionCanisterId: canister, index: index, id: id })
                            }} className="m-auto !mt-4">PROCEED</Button>
                        </div>
                        <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                    </div>
                </div>
            </div>
        ));
    };

    const onDisburseClick = (time : string) => {
        toast.custom((t) => (
            <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                <div className="w-2/3 rounded-3xl mb-7 p-0.5 gradient-bg mt-48 inline-block">
                    <div className="h-full w-full dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                        <div className="mt-5 mb-5 text-lg px-10">
                            <p>You will have to wait for <span className="gradient-text font-bold">{time}</span> to be able to withdraw/disburse your NFT back to your BGG account as NFT must finish dissolve delay of 24 hours before it can be withdrawn to the wallet.</p>
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
                <Button className="h-10 mt-6 mb-10" size="big" rightArrow={true} onClick={() => onDepositClick(session?.address || "")}>DEPOSIT NFT</Button>
                {isLoading ? (
                    <LoadingResult>{t("wallet.tab_2.nfts_loading")}</LoadingResult>
                ) : isError ? (
                    <ErrorResult>{t("error")}</ErrorResult>
                ) :
                    data.length ? (
                        <>
                            <div className="w-full">
                                {data.map(({ name, logo, balance, canister, url, stakedNfts, unstakedNfts, dissolvedNfts, principal }) => (
                                    <div key={canister}>
                                        <div className="flex mb-4">
                                            <img src={logo} className="w-16 h-16 m-2" />
                                            <p className="text-3xl ml-2 mt-6 font-semibold">{name}</p>
                                        </div>
                                        <div>
                                            {unstakedNfts.length ? <div className="grid grid-cols-6 gap-0">
                                                {unstakedNfts.map((id) => (
                                                    <div className="">
                                                        <img key={canister + id[0]} onClick={() => onTransferClick(canister, id[0])} className="w-40 h-40 object-cover mb-5 cursor-pointer" src={"https://" + canister + ".raw.icp0.io/?type=thumbnail&tokenid=" + id[0]} />
                                                        <Button className="h-10 mb-4" onClick={() => { onStakeClick(canister, id[1], id[0]) }} isLoading={isStaking} rightArrow={true}>STAKE NFT</Button>
                                                    </div>
                                                ))}
                                            </div> : <></>
                                            }
                                        </div>

                                        <div>
                                            {stakedNfts.length ? <div className="grid grid-cols-6 gap-0">
                                                {stakedNfts.map((id) => (
                                                    <div>
                                                        <img key={canister + id[0]} onClick={() => onTransferClick(canister, id[0])} className="w-40 h-40 object-cover mb-5 cursor-pointer" src={"https://" + canister + ".raw.icp0.io/?type=thumbnail&tokenid=" + id[0]} />
                                                        <Button className="h-10 mb-4" onClick={() => { mutateDissolve({ collectionCanisterId: canister, index: id[1] }) }} isLoading={isDissolving}>DISSOLVE NFT</Button>
                                                    </div>
                                                ))}
                                            </div> : <></>
                                            }
                                        </div>

                                        <div>
                                            {dissolvedNfts.length ? <div className="grid grid-cols-6 gap-0">
                                                {dissolvedNfts.map((id) => (
                                                    <div>
                                                        <img key={canister + id[0]} onClick={() => onTransferClick(canister, id[0])} className="w-40 h-40 object-cover mb-5 cursor-pointer" src={"https://" + canister + ".raw.icp0.io/?type=thumbnail&tokenid=" + id[0]} />
                                                        <Button className="h-10 mb-4" onClick={() => {
                                                            if (id[2] == "0") {
                                                                mutateDisburse({ collectionCanisterId: canister, index: id[1] })
                                                            } else {
                                                                onDisburseClick(id[2]);
                                                            }
                                                        }} isLoading={isDisbursing}>DISBURSE NFT</Button>
                                                    </div>
                                                ))}
                                            </div> : <></>
                                            }
                                        </div>
                                        {
                                            (!stakedNfts.length && !unstakedNfts.length && !dissolvedNfts.length) ? <div className="mb-10"><NoDataResult>{t("wallet.tab_2.no_nfts")}</NoDataResult></div> : <></>
                                        }
                                    </div>
                                ))}
                            </div>
                        </>
                    ) : (
                        <></>
                    )}
            </div>
        </>
    );
}

export default Nft;
