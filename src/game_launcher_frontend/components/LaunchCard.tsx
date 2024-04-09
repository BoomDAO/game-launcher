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

interface TokenConfigs {
    name: string;
    symbol: string;
    logoUrl: string;
    description: string;
}

interface SwapConfigs {
    raisedIcp: string;
    maxIcp: string;
    minIcp: string;
    minParticipantIcp: string;
    maxParticipantIcp: string;
    participants: string;
    endTimestamp: string;
    status: boolean;
    result: boolean;
}

interface ProjectConfigs {
    name: string;
    bannerUrl: string;
    description: string;
    website: string;
    creator: string;
    creatorAbout: string;
    creatorImageUrl: string;
}

interface LaunchCardProps {
    id: string;
    project: ProjectConfigs;
    swap: SwapConfigs;
    token: TokenConfigs;
}

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
        if(!canisterId) {
            navigate(navPaths.launchpad + "/" + id);
        }
    }

    const handleParticipate = () => {
        if(session) {
            navigate(navPaths.launchpad_participate + "/" + canisterId);
        } else {
            setIsOpenNavSidebar(true);
        }
    }

    return (
        <Center>
            {
                (swap.status) ? <div className={
                    cx(
                        "flex w-full bg-dark  dark:bg-white rounded-xl",
                        (!canisterId) ? "cursor-pointer" : ""
                    )
                } onClick={handleCardOnClick}>
                    <div className="w-1/2 p-2 relative">
                        <img src={project.bannerUrl} className="h-80 w-full object-cover rounded-xl" />
                        <div className="absolute bottom-4 text-white">
                            <p className="font-bold text-3xl px-5">{project.name}</p>
                            <p className="w-full px-5 text-sm">{project.description}</p>
                        </div>
                    </div>
                    <div className={cx(
                        "w-1/2 p-5",
                        (canisterId == undefined)? "mt-10" : "" 
                    )} >
                        <div className="flex text-white dark:text-black justify-between">
                            <div>
                                <p>Token</p>
                                <div className="flex">
                                    <img className="w-10" src={token.logoUrl} />
                                    <p>{token.symbol}</p>
                                </div>
                            </div>
                            <div>
                                <p>Total Raised</p>
                                <div className="flex">
                                    <img src="/icp.svg" className="w-10" />
                                    <p>{swap.raisedIcp} ICP</p>
                                </div>
                            </div>
                        </div>
                        <div className="h-0.5 bg-white dark:bg-black mt-2"></div>
                        {
                            (canisterId) ? <div className="">
                                <Button className="gradient-bg-blue rounded mt-2" onClick={handleParticipate}>PARTICIPATE</Button>
                                <p className="dark:text-black text-white text-xs mt-1">Minimum {swap.minParticipantIcp} ICP required to Participate. </p>
                                <div className="h-0.5 bg-white dark:bg-black mt-2"></div>
                            </div> : <></>
                        }
                        <div className="pt-2">
                            <div className="flex text-white dark:text-black justify-between">
                                <div>
                                    <p>{swap.raisedIcp} / {swap.maxIcp}</p>
                                </div>
                                <div>
                                    Progress : {(100 * Number(swap.raisedIcp) / Number(swap.maxIcp))}%
                                </div>
                            </div>
                            <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-4 relative">
                                <div className="flex cursor-pointer text-sm z-10 absolute pl-5"></div>
                                <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(swap.raisedIcp) / Number(swap.maxIcp)) >= 100) ? 100 : (100 * Number(swap.raisedIcp) / Number(swap.maxIcp))}%` }}></div>
                            </div>
                            <div className="text-white dark:text-black float-right pt-2">
                                <p>Participants : {swap.participants}</p>
                            </div>
                        </div>
                        <div className="h-0.5 bg-white dark:bg-black mt-10"></div>
                        {
                            (swap.status) ? <div className="text-white dark:text-black w-full mt-2">
                                <p>ENDS IN : {swap.endTimestamp}</p>
                            </div> : <div className="text-white dark:text-black mt-2 w-full">
                                {(swap.result) ? <p>STATUS : PASSED</p> : <p>STATUS : FAILED</p>}
                            </div>
                        }
                    </div>
                </div> :
                    <div className="flex w-full bg-dark dark:bg-white rounded-xl">
                        <div className="w-1/2 p-2 relative">
                            <img src={project.bannerUrl} className="h-60 w-full object-cover rounded-xl" />
                            <div className="absolute bottom-4 text-white">
                                <p className="font-bold text-3xl px-5">{project.name}</p>
                                <p className="w-full px-5 text-sm">{project.description}</p>
                            </div>
                        </div>
                        <div className="w-1/2 p-5">
                            <div className="flex text-white dark:text-black justify-between">
                                <div>
                                    <p>Token</p>
                                    <div className="flex">
                                        <img className="w-10" src={token.logoUrl} />
                                        <p>{token.symbol}</p>
                                    </div>
                                </div>
                                <div>
                                    <p>Total Raised</p>
                                    <div className="flex">
                                        <img src="/icp.svg" className="w-10" />
                                        <p>{swap.raisedIcp} ICP</p>
                                    </div>
                                </div>
                            </div>
                            <div className="h-0.5 bg-white dark:bg-black mt-2"></div>
                            <div className="pt-2">
                                <div className="flex text-white dark:text-black justify-between">
                                    <div>
                                        <p>{swap.raisedIcp} / {swap.maxIcp}</p>
                                    </div>
                                    <div>
                                        Progress : {(100 * Number(swap.raisedIcp) / Number(swap.maxIcp))}%
                                    </div>
                                </div>
                                <div className="flex w-full h-4 bg-gray-300/50 rounded-3xl mt-4 relative">
                                    <div className="flex cursor-pointer text-sm z-10 absolute pl-5"></div>
                                    <div className="yellow-gradient-bg h-4 rounded-3xl absolute z-5" style={{ width: `${((100 * Number(swap.raisedIcp) / Number(swap.maxIcp)) >= 100) ? 100 : (100 * Number(swap.raisedIcp) / Number(swap.maxIcp))}%` }}></div>
                                </div>
                                <div className="text-white dark:text-black float-right pt-2">
                                    <p>Participants : {swap.participants}</p>
                                </div>
                            </div>
                            <div className="h-0.5 bg-white dark:bg-black mt-10"></div>
                            {
                                (swap.status) ? <div className="text-white dark:text-black w-full mt-2">
                                    <p>ENDS IN : {swap.endTimestamp}</p>
                                </div> : <div className="text-white dark:text-black mt-2 w-full">
                                    {(swap.result) ? <p>STATUS : PASSED</p> : <p>STATUS : FAILED</p>}
                                </div>
                            }
                        </div>
                    </div>
            }
        </Center>
    );
};

export default LaunchCard;
