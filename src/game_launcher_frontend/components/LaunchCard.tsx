import React from "react";
import { useTranslation } from "react-i18next";
import { NoSymbolIcon } from "@heroicons/react/20/solid";
import Center from "./ui/Center";
import Divider from "./ui/Divider";
import Loader from "./ui/Loader";
import Button from "./ui/Button";
import { useNavigate } from "react-router-dom";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import toast from "react-hot-toast";
import { cx } from "@/utils";

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
}

interface CardProps {
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
}: CardProps) => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const session = useAuthContext();
    const { setIsOpenNavSidebar } = useGlobalContext();
    
    return (
        <Center>
        </Center>
    );
};

export default LaunchCard;
