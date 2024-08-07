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
import { useAuthContext } from "@/context/authContext";

const GameIframe = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { session } = useAuthContext();
    const { canisterId } = useParams();

    const iframeContainer = document.getElementById("iframeContainer");
    const gameUrl = "https://" + canisterId + ".raw.icp0.io";

    window.addEventListener("message", (event) => {
        console.log("identity request");
        console.log(session?.identity);
        console.log(JSON.stringify(session?.identity));
        var iframe = document.getElementById('iframe') as HTMLIFrameElement;
        if (event.data === "identity_request") {
            console.log("identity requested");
            iframe.contentWindow?.postMessage(JSON.stringify(session?.identity), gameUrl);
        }
    });

    return (
        <div id="iframeContainer" className="w-full h-full">
            <iframe src={gameUrl} style={{ width: "100%", height: "91.5vh", padding: "0" }} id="iframe"></iframe>
        </div>
    );
}

export default GameIframe;
