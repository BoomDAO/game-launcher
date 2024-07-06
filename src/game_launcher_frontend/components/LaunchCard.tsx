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
import { useGetParticipationDetails } from "@/api/launchpad";
import { LaunchCardProps } from "@/types";

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

    const handleCardOnClick = () => {
        if (!canisterId) {
            navigate(navPaths.launchpad + "/" + id);
        }
    }

    const handleParticipate = () => {
        if (session.session) {
            navigate(navPaths.launchpad_participate + "/" + canisterId);
        } else {
            setIsOpenNavSidebar(true);
        }
    }

    const { data, isLoading } = useGetParticipationDetails(canisterId);

    return (
        <Center>
            {
                (swap.status) ? <div className={
                    cx(
                        "flex w-full bg-dark  dark:bg-white rounded-xl",
                        (!canisterId) ? "cursor-pointer" : ""
                    )
                } onClick={handleCardOnClick}>
                    <div className="w-7/12 p-2 relative">
                        <img src={project.bannerUrl} className="h-80 w-full object-cover rounded-xl" />
                        <div className="absolute bottom-5 text-white">
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
                                        <img className="w-10" src={token.logoUrl} />
                                        <p className="pt-2 pl-2 font-semibold">{token.symbol}</p>
                                    </div>
                                </div>
                                <div>
                                    <p className="font-light">TOTAL RAISED</p>
                                    <div className="flex">
                                        <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-12" />
                                        <p className="pt-1.5 pl-1 font-semibold">{swap.raisedToken} {swap.swapType}</p>
                                    </div>
                                </div>
                            </div>
                            <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div>
                            <div className="flex">
                                {
                                    (canisterId) ? <div className="w-1/2">
                                        <button className="w-11/12 gradient-bg-blue rounded mt-2 text-sm py-2 font-semibold text-white " onClick={handleParticipate}>PARTICIPATE</button>
                                        <p className="dark:text-black text-white text-xs mt-1 font-light">Minimum {swap.minParticipantToken} {swap.swapType} required to Participate. </p>
                                    </div> : <></>
                                }
                                {
                                    (isLoading) ? <Loader className="w-10"></Loader> :
                                        (data != "0" && canisterId) ?
                                            <div className={cx("dark:text-black text-white text-xs mt-3 pl-2 font-light", (canisterId) ? "border-l-2" : "")}>
                                                <p>YOU HAVE ALREADY CONTRIBUTED</p>
                                                <div className="flex">
                                                    <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-10 mt-0.5" />
                                                    <p className="pt-1.5 font-semibold text-sm">{data} {swap.swapType}</p>
                                                </div>
                                            </div> : <></>
                                }
                            </div>
                            {
                                (canisterId) ? <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div> : <></>
                            }
                            <div className="pt-2">
                                <div className="flex text-white dark:text-black justify-between font-light text-sm">
                                    <div>
                                        <p>{swap.raisedToken} / {swap.maxToken} {swap.swapType}</p>
                                    </div>
                                    <div>
                                        PROGRESS : {(100 * Number(swap.raisedToken) / Number(swap.maxToken))}%
                                    </div>
                                </div>
                                <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-1 relative">
                                    <div className="flex cursor-pointer text-sm z-10 absolute pl-5"></div>
                                    <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(swap.raisedToken) / Number(swap.maxToken)) >= 100) ? 100 : (100 * Number(swap.raisedToken) / Number(swap.maxToken))}%` }}></div>
                                </div>
                                <div className="text-white dark:text-black float-right font-light text-sm mt-1">
                                    <p>PARTICIPANTS : {swap.participants}</p>
                                </div>
                            </div>
                            <div className="h-0.5 bg-white dark:bg-gray-300 mt-10"></div>
                            {
                                (swap.status) ? <div className="flex text-white dark:text-black w-full mt-2">
                                    <p className="font-light w-1/4">ENDS IN  </p>
                                    <FormattedDate days={swap.endTimestamp.days} hrs={swap.endTimestamp.hrs} mins={swap.endTimestamp.mins} />
                                </div> : <div className="text-white dark:text-black mt-2 w-full">
                                    {(swap.result) ? <p>STATUS : FUNDED</p> : <p>STATUS : FAILED</p>}
                                </div>
                            }
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
                            <img src={project.bannerUrl} className="h-60 w-full object-cover rounded-xl" />
                            <div className="absolute bottom-4 text-white">
                                <p className="font-bold text-4xl px-5 pb-1">{project.name}</p>
                                <p className="w-9/12 px-5 text-xs">{project.description}</p>
                            </div>
                        </div>
                        <div className="w-5/12">
                            {
                                (canisterId == undefined) ? <img className="w-4 float-right m-2" src="./arrow.svg" /> : <></>
                            }
                            <div className="p-5 mt-4">
                                <div className="flex text-white dark:text-black justify-between">
                                    <div>
                                        <p className="font-light">TOKEN</p>
                                        <div className="flex">
                                            <img className="w-10" src={token.logoUrl} />
                                            <p className="pt-2 pl-2 font-semibold">{token.symbol}</p>
                                        </div>
                                    </div>
                                    <div>
                                        <p className="font-light">TOTAL RAISED</p>
                                        <div className="flex">
                                            <img src={(swap.swapType == "ICP") ? "/ICP.svg" : "/BOOM.svg"} className="w-10" />
                                            <p className="pt-1.5 pl-1 font-semibold">{swap.raisedToken} {swap.swapType}</p>
                                        </div>
                                    </div>
                                </div>
                                <div className="h-0.5 bg-white dark:bg-gray-300 mt-2"></div>
                                <div className="pt-2">
                                    <div className="flex text-white dark:text-black justify-between font-light text-sm">
                                        <div>
                                            <p>{swap.raisedToken} / {swap.maxToken} {swap.swapType}</p>
                                        </div>
                                        <div>
                                            PROGRESS : {(100 * Number(swap.raisedToken) / Number(swap.maxToken))}%
                                        </div>
                                    </div>
                                    <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-1 relative">
                                        <div className="flex cursor-pointer text-sm z-10 absolute pl-5"></div>
                                        <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(swap.raisedToken) / Number(swap.maxToken)) >= 100) ? 100 : (100 * Number(swap.raisedToken) / Number(swap.maxToken))}%` }}></div>
                                    </div>
                                    <div className="text-white dark:text-black float-right font-light text-sm mt-1">
                                        <p>PARTICIPANTS : {swap.participants}</p>
                                    </div>
                                </div>
                                <div className="h-0.5 bg-white dark:bg-gray-300 mt-10"></div>
                                {
                                    (swap.status) ? <div className="text-white dark:text-black w-full mt-2">
                                        <p>ENDS IN : <FormattedDate days={swap.endTimestamp.days} hrs={swap.endTimestamp.hrs} mins={swap.endTimestamp.mins} /></p>
                                    </div> : <div className="text-white dark:text-black mt-2 w-full font-light">
                                        {(swap.result) ? <p>STATUS : FUNDED</p> : <p>STATUS : FAILED</p>}
                                    </div>
                                }
                            </div>
                        </div>
                    </div>
            }
        </Center>
    );
};

export default LaunchCard;
