import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { Cog8ToothIcon } from "@heroicons/react/20/solid";
import { useParams } from "react-router-dom";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";
import SubHeading from "@/components/ui/SubHeading";

const Configure = () => {
    const [pageNumber, setPageNumber] = React.useState(1);
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { canisterId } = useParams();


    return (
        <>

            <SubHeading>What is a World?</SubHeading>
            <br></br>

            A World is the "server backend" of a game, housing the smart contract logic that validates player actions and regulates game rules. Worlds are composable by nature, so anyone can copy, mod or extend a World canister, opening up new avenues for network effects and coordination.
            
            <SubHeading>How do I configure my World?</SubHeading>
            <br></br>
            When you deploy a World on the Game Launcher, you can configure it with Actions and Entities that define the rules and objects of the World. You can learn more about Actions and Entities in the tech <a className="underline text-yellow-300" href="https://docs.boomdao.xyz/world-template/configs">Docs Here</a>.
            <br></br>
            <br></br>
            When you click on the "Configure World" button below, it will take you to the Candid frontend of your World. From here, you can configure the EntityConfigs that exist in your World like items, buffs, stats, characters etc. And also configure the ActionConfigs that exist in your World like completing a quest, running a race, buying an item etc.
            <br></br>
            <br></br>
            By configuring Actions and Entities, you are configuring the things that exist in your World and the rules governing how players are allowed to interact with these things.
            <Button
                size="big"
                rightArrow
                onClick={() =>
                    window.open(`${navPaths.boomdao_candid_url}?id=${canisterId}`, "_blank")
                }
            >
                {t("world_deployer.manage_worlds.tabs.item_1.button_text")}
            </Button>
        </>
    );
};

export default Configure;
