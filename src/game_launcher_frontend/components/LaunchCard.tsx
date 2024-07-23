import React from "react";
import { useTranslation } from "react-i18next";
import { NoSymbolIcon } from "@heroicons/react/20/solid";
import Center from "./ui/Center";
import Divider from "./ui/Divider";
import Loader from "./ui/Loader";
import Button from "./ui/Button";
import { useNavigate, useParams } from "react-router-dom";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import toast from "react-hot-toast";
import { cx } from "@/utils";
import { navPaths } from "@/shared";
import FormattedDate from "./FormattedDate";
import { useGetParticipationDetails, useGetParticipationEligibility, useGetWhitelistDetails } from "@/api/launchpad";
import { LaunchCardProps } from "@/types";
import { boom_ledger_canisterId } from "@/hooks";
import { useGetBoomStakeTier } from "@/api/profile";
import axios from 'axios';
import ENV from "../../../env.json"
import defaultTexts from "../api/defaultTexts.json";

type Texts = typeof defaultTexts;
const IPSTACK_API_KEY = ENV.IPSTACK_API_KEY;

const LaunchCard = ({
    id,
    project,
    swap,
    token
}: LaunchCardProps) => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const session = useAuthContext();
    const { setIsOpenNavSidebar } = useGlobalContext();
    const { canisterId } = useParams();

    const [isGeoInfoLoading, setGeoInfoLoading] = React.useState(false);

    const handleCardOnClick = () => {
        if (!canisterId) {
            navigate(navPaths.launchpad + "/" + id);
        }
    }

    const { data, isLoading } = useGetParticipationDetails(canisterId || "");
    // const { data: userStakeTier, isLoading: isStakingTierLoading } = useGetBoomStakeTier();
    const { data: whitelistDetails, isLoading: isWhitelistDetailsLoading } = useGetWhitelistDetails();
    const { data: eligibility, isLoading: isEligibilityLoading } = useGetParticipationEligibility();

    const handleParticipate = async () => {
        if (session.session) {
            setGeoInfoLoading(true);
            let isUserBlocked = false;
            const github = "https://raw.githubusercontent.com/BoomDAO/gaming-guild-content/main";
            const info = await fetch(`${github}/texts.json`);
            const texts = (await info.json()) as Texts;
            const blocked_country_codes: string[] = [];
            texts.blocked_country_info.codes.map((t) => {
                blocked_country_codes.push(t);
            });
            const geo_blocking_info = texts.blocked_country_info.geo_blocking_info;
            const response = await axios.get(ENV.FETCH_GEO_INFO_URL);
            let user_country_code = response.data.country_code;
            for (let i = 0; i < blocked_country_codes.length; i += 1) {
                if (user_country_code == blocked_country_codes[i]) {
                    isUserBlocked = true;
                    break;
                }
            };
            setGeoInfoLoading(false);
            if (isUserBlocked) {
                toast.custom((t) => (
                    <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                        <div className="w-2/3 rounded-3xl p-0.5 gradient-bg mt-48 inline-block">
                            <div className="h-full w-auto dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                                <div className="text-base py-8 px-8">{geo_blocking_info}</div>
                                <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                            </div>
                        </div>
                    </div>
                ));
                return;
            } else {
                if (eligibility) {
                    navigate(navPaths.launchpad_participate + "/" + data?.[1] + "/" + canisterId);
                } else {
                    toast.custom((t) => (
                        <div className="w-full h-screen bg-black/50 text-center p-0 m-0">
                            <div className="w-2/3 rounded-3xl p-0.5 gradient-bg mt-48 inline-block">
                                <div className="h-full w-auto dark:bg-white bg-dark rounded-3xl p-4 dark:text-black text-white text-center">
                                    <div className="text-base py-8 px-8">Please wait for the Public Sale to open. Otherwise you can get early access to token sales by staking BOOM tokens in the Launchpad wallet to join a BOOM Staking Membership.</div>
                                    <Button onClick={() => toast.remove()} className="ml-auto">Close</Button>
                                </div>
                            </div>
                        </div>
                    ));
                }
            }
        } else {
            setIsOpenNavSidebar(true);
        }
    }

    return (
        <Center>
            {
                (swap.status == "Active") ? <div className={
                    cx(
                        "flex w-full bg-dark  dark:bg-white rounded-xl",
                        (!canisterId) ? "cursor-pointer" : ""
                    )
                } onClick={handleCardOnClick}>
                    <div className="w-7/12 p-2 relative">
                        <img src={project.bannerUrl} className="h-96 w-full object-cover rounded-xl" />
                        <div className="absolute bottom-5 text-white">
                            {
                                (!isWhitelistDetailsLoading && whitelistDetails?.elite) ? <div className="w-5/12 flex bg-sky-500 rounded-xl py-0.5 mb-2 ml-4">
                                    <img src="/live.svg" className="w-2 ml-2" />
                                    <p className="font-semibold text-white text-sm pl-2">LIVE : ELITE STAKER</p>
                                </div> : <></>
                            }
                            {
                                (!isWhitelistDetailsLoading && whitelistDetails?.pro) ? <div className="w-5/12 flex bg-sky-500 rounded-xl py-0.5 mb-2 ml-4">
                                    <img src="/live.svg" className="w-2 ml-2" />
                                    <p className="font-semibold text-white text-sm pl-2">LIVE : PRO STAKER</p>
                                </div> : <></>
                            }
                            {
                                (!isWhitelistDetailsLoading && whitelistDetails?.public) ? <div className="w-5/12 flex bg-sky-500 rounded-xl py-0.5 mb-32 ml-4">
                                    <img src="/live.svg" className="w-2 ml-2" />
                                    <p className="font-semibold text-white text-sm pl-2">LIVE : PUBLIC</p>
                                </div> : <></>
                            }
                            <p className="font-bold text-6xl px-5 pb-1">{project.name}</p>
                            <p className="w-9/12 px-5 text-xs">{project.description}</p>
                        </div>
                    </div>
                    <div className="w-5/12">
                        {
                            (canisterId == undefined) ? <img className="w-4 float-right m-2" src="./arrow.svg" /> : <></>
                        }
                        <div className={cx(
                            "p-5",
                            (canisterId == undefined) ? "mt-10" : ""
                        )} >
                            <div className="flex text-white dark:text-black justify-between">
                                <div>
                                    <p className="font-light">TOKEN</p>
                                    <div className="flex">
                                        <img className="w-10 h-10 rounded-primary border-2" src={token.logoUrl} />
                                        <p className="pt-2 pl-2 font-semibold">{token.symbol}</p>
                                    </div>
                                </div>
                                <div>
                                    <p className="font-light">TOTAL RAISED</p>
                                    <div className="flex">
                                        <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-10 h-10 rounded-primary border-2" />
                                        <p className="pt-2 pl-1 font-semibold">{swap.raisedToken} {swap.swapType}</p>
                                    </div>
                                </div>
                            </div>
                            <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div>
                            <div className="flex">
                                {
                                    (canisterId) ? <div className="w-1/2">
                                        {
                                            (!isGeoInfoLoading && !isEligibilityLoading) ? <button className="w-11/12 gradient-bg-blue rounded mt-2 text-sm py-2 font-semibold text-white " onClick={handleParticipate}>PARTICIPATE</button> : <Loader className="w-10 mt-2 ml-20 mb-4"></Loader>
                                        }
                                        <p className="dark:text-black text-white text-xs mt-1 font-light">Minimum {swap.minParticipantToken} {swap.swapType} required to Participate. </p>
                                    </div> : <></>
                                }
                                {
                                    (isLoading) ? <Loader className="w-10"></Loader> :
                                        (data?.[0] != "0" && canisterId) ?
                                            <div className={cx("dark:text-black text-white text-xs mt-3 pl-2 font-light", (canisterId) ? "border-l-2" : "")}>
                                                <p>YOU HAVE ALREADY CONTRIBUTED</p>
                                                <div className="flex">
                                                    <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-8 mt-0.5" />
                                                    <p className="pt-2.5 font-semibold text-sm pl-2">{data?.[0]} {swap.swapType}</p>
                                                </div>
                                                <p className="mt-1">LIMIT PER USER : {swap.maxParticipantToken} {swap.swapType}</p>
                                            </div> : <></>
                                }
                            </div>
                            {
                                (canisterId) ? <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div> : <></>
                            }
                            <div className="pt-2">
                                <div className="flex text-white dark:text-black justify-between font-light text-sm">
                                    <div>
                                        PROGRESS : {swap.raisedToken} {swap.swapType}
                                    </div>
                                    <div className="">
                                        <p>PARTICIPANTS : {swap.participants}</p>
                                    </div>
                                </div>
                                <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-4 relative">
                                    <div style={{ marginLeft: `${(BigInt(swap.minToken) * 100n) / BigInt(swap.maxToken)}%` }} className="absolute z-30 -mt-4">
                                        <img src="/blue-marker.svg" className="w-4" />
                                    </div>
                                    <div className="flex cursor-pointer text-sm z-20 absolute pl-5"></div>
                                    <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-10" style={{ width: `${((100 * Number(swap.raisedToken) / Number(swap.maxToken)) >= 100) ? 100 : (100 * Number(swap.raisedToken) / Number(swap.maxToken))}%` }}></div>
                                </div>
                                <div className="flex text-white dark:text-black justify-between font-light text-xs pt-2">
                                    <div>
                                        MIN : {swap.minToken} {swap.swapType}
                                    </div>
                                    <div>
                                        MAX : {swap.maxToken} {swap.swapType}
                                    </div>
                                </div>
                            </div>
                            <div className="h-0.5 bg-white dark:bg-gray-300 mt-4"></div>
                            {
                                (swap.status == "Active") ? <div className="flex text-white dark:text-black w-full mt-2">
                                    <p className="font-light w-1/4">ENDS IN  </p>
                                    <FormattedDate days={swap.endTimestamp.days} hrs={swap.endTimestamp.hrs} mins={swap.endTimestamp.mins} />
                                </div> : <div className="text-white dark:text-black mt-2 w-full">
                                    {(swap.result) ? <p>STATUS : FUNDED</p> : <p>STATUS : FAILED</p>}
                                </div>
                            }
                            <div className="flex pt-2">
                                <div className="dark:text-black text-white text-xxs pt-1.5">SALE OPENS 6 HOUR EARLY FOR ELITE STAKERS AND 3 HOUR EARLY FOR PRO STAKERS.</div>
                                <Button size="small" className="ml-4" onClick={(e) => {
                                    if (session.session) {
                                        navigate(navPaths.stake + "/" + boom_ledger_canisterId);
                                        e.stopPropagation();
                                    } else {
                                        setIsOpenNavSidebar(true);
                                    }
                                }}>STAKE</Button>
                            </div>
                        </div>
                    </div>
                </div> :
                    (swap.status == "Inactive") ?
                        <div className={
                            cx(
                                "flex w-full bg-dark  dark:bg-white rounded-xl",
                                (!canisterId) ? "cursor-pointer" : ""
                            )
                        } onClick={handleCardOnClick}>
                            <div className="w-7/12 p-2 relative">
                                <img src={project.bannerUrl} className="h-64 w-full object-cover rounded-xl" />
                                <div className="absolute bottom-4 text-white">
                                    <p className="font-bold text-4xl px-5 pb-1">{project.name}</p>
                                    <p className="w-9/12 px-5 text-xs">{project.description}</p>
                                </div>
                            </div>
                            <div className="w-5/12">
                                {
                                    (canisterId == undefined) ? <img className="w-4 float-right m-2" src="./arrow.svg" /> : <></>
                                }
                                <div className="p-5">
                                    <div className="flex text-white dark:text-black justify-between">
                                        <div>
                                            <p className="font-light">TOKEN</p>
                                            <div className="flex">
                                                <img className="w-10 h-10 rounded-primary border-2" src={token.logoUrl} />
                                                <p className="pt-2 pl-2 font-semibold">{token.symbol}</p>
                                            </div>
                                        </div>
                                        <div>
                                            <p className="font-light">TOTAL RAISED</p>
                                            <div className="flex">
                                                <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-10 h-10 rounded-primary border-2" />
                                                <p className="pt-1.5 pl-1 font-semibold">{swap.raisedToken} {swap.swapType}</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div>
                                    <div className="pt-2">
                                        <div className="flex text-white dark:text-black justify-between font-light text-sm">
                                            <div>
                                                PROGRESS : {swap.raisedToken} {swap.swapType}
                                            </div>
                                            <div className="">
                                                <p>PARTICIPANTS : {swap.participants}</p>
                                            </div>
                                        </div>
                                        <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-2.5 relative">
                                            <div style={{ marginLeft: `${(BigInt(swap.minToken) * 100n) / BigInt(swap.maxToken)}%` }} className="absolute z-30 -mt-4">
                                                <img src="/blue-marker.svg" className="w-4" />
                                            </div>
                                            <div className="flex cursor-pointer text-sm z-20 absolute pl-5"></div>
                                            <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-10" style={{ width: `${((100 * Number(swap.raisedToken) / Number(swap.maxToken)) >= 100) ? 100 : (100 * Number(swap.raisedToken) / Number(swap.maxToken))}%` }}></div>
                                        </div>
                                        <div className="flex text-white dark:text-black justify-between font-light text-xs pt-2">
                                            <div>
                                                MIN : {swap.minToken} {swap.swapType}
                                            </div>
                                            <div>
                                                MAX : {swap.maxToken} {swap.swapType}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="h-0.5 bg-white dark:bg-gray-300 mt-4"></div>
                                    {
                                        (swap.status == "Inactive") ? <div className="text-white dark:text-black mt-2 w-full font-light">
                                            {(swap.result) ? <p>STATUS : FUNDED</p> : <p>STATUS : FAILED</p>}
                                        </div> : <></>
                                    }
                                    <div className="flex pt-2">
                                        <div className="dark:text-black text-white text-xxs pt-1.5">SALE OPENS 6 HOUR EARLY FOR ELITE STAKERS AND 3 HOUR EARLY FOR PRO STAKERS.</div>
                                        <Button size="small" className="ml-4" onClick={(e) => {
                                            if (session.session) {
                                                navigate(navPaths.stake + "/" + boom_ledger_canisterId);
                                                e.stopPropagation();
                                            } else {
                                                setIsOpenNavSidebar(true);
                                            }
                                        }}>STAKE</Button>
                                    </div>
                                </div>
                            </div>
                        </div> :
                        <div className={
                            cx(
                                "flex w-full bg-dark  dark:bg-white rounded-xl",
                                (!canisterId) ? "cursor-pointer" : ""
                            )
                        } onClick={handleCardOnClick}>
                            <div className="w-7/12 p-2 relative">
                                <img src={project.bannerUrl} className="h-96 w-full object-cover rounded-xl" />
                            </div>
                            <div className="w-5/12">
                                {
                                    (canisterId == undefined) ? <img className="w-4 float-right m-2" src="./arrow.svg" /> : <></>
                                }
                                <div className={cx(
                                    "p-5 mt-10"
                                )} >
                                    <div className="flex text-white dark:text-black justify-between">
                                        <div>
                                            <p className="font-light">TOKEN</p>
                                            <div className="flex">
                                                <img className="w-10 h-10 rounded-primary border-2" src={token.logoUrl} />
                                                <p className="pt-2 pl-2 font-semibold">{token.symbol}</p>
                                            </div>
                                        </div>
                                        <div>
                                            <p className="font-light">TOTAL RAISED</p>
                                            <div className="flex">
                                                <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-10 h-10 rounded-primary border-2" />
                                                <p className="pt-2 pl-1 font-semibold">{swap.raisedToken} {swap.swapType}</p>
                                            </div>
                                        </div>
                                    </div>
                                    {
                                        (canisterId) ? <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div> : <></>
                                    }
                                    <div className="pt-2">
                                        <div className="flex text-white dark:text-black justify-between font-light text-sm">
                                            <div>
                                                PROGRESS : {swap.raisedToken} {swap.swapType}
                                            </div>
                                            <div className="">
                                                <p>PARTICIPANTS : {swap.participants}</p>
                                            </div>
                                        </div>
                                        <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-4 relative">
                                            <div style={{ marginLeft: `${(BigInt(swap.minToken) * 100n) / BigInt(swap.maxToken)}%` }} className="absolute z-30 -mt-4">
                                                <img src="/blue-marker.svg" className="w-4" />
                                            </div>
                                            <div className="flex cursor-pointer text-sm z-20 absolute pl-5"></div>
                                            <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-10" style={{ width: `${((100 * Number(swap.raisedToken) / Number(swap.maxToken)) >= 100) ? 100 : (100 * Number(swap.raisedToken) / Number(swap.maxToken))}%` }}></div>
                                        </div>
                                        <div className="flex text-white dark:text-black justify-between font-light text-xs pt-2">
                                            <div>
                                                MIN : {swap.minToken} {swap.swapType}
                                            </div>
                                            <div>
                                                MAX : {swap.maxToken} {swap.swapType}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="h-0.5 bg-white dark:bg-gray-300 mt-4"></div>
                                    {
                                        (swap.status == "Upcoming") ? <div className="flex text-white dark:text-black w-full mt-2">
                                            <p className="font-light w-1/4">STARTS IN  </p>
                                            <FormattedDate days={swap.endTimestamp.days} hrs={swap.endTimestamp.hrs} mins={swap.endTimestamp.mins} />
                                        </div> : <></>
                                    }
                                    <div className="flex pt-2">
                                        <div className="dark:text-black text-white text-xxs pt-1.5">SALE OPENS 6 HOUR EARLY FOR ELITE STAKERS AND 3 HOUR EARLY FOR PRO STAKERS.</div>
                                        <Button size="small" className="ml-4" onClick={(e) => {
                                            if (session.session) {
                                                navigate(navPaths.stake + "/" + boom_ledger_canisterId);
                                                e.stopPropagation();
                                            } else {
                                                setIsOpenNavSidebar(true);
                                            }
                                        }}>STAKE</Button>
                                    </div>
                                </div>
                            </div>
                        </div>
            }
        </Center>
    );
};

export default LaunchCard;
