import React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { navPaths } from "@/shared";
import DialogProvider from "@/components/DialogProvider";
import GamingGuilds from ".";
import {
    OpenDialogType,
    StateTypes
} from "../../types/dialogTypes";
import EmailOtpPage from "./EmailOtpPage";


const VerifyOtpPage = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();

    const open: OpenDialogType = ({
        component,
        title,
        okCallback,
        cancelCallback,
        width,
        okText,
        cancelText
    }) => {
        setState({
            component,
            title,
            okCallback,
            cancelCallback,
            width,
            okText,
            cancelText,
            isOpen: true,
            value: {
                openDialog: open,
                closeDialog: close
            }
        });
    };

    const close = (): void => {
        setState({ isOpen: false });
        navigate(navPaths.home);
    };

    const [state, setState] = React.useState<StateTypes>({
        component: <EmailOtpPage/>,
        isOpen: true,
        title: "Verify Email to Receive Airdrop Badge",
        okText: "Ok",
        cancelText: "Cancel",
        width: "md",
        okCallback: close,
        cancelCallback: close,
        value: {
            openDialog: open,
            closeDialog: () => { }
        }
    });

    return (
        <>
            <DialogProvider state={state}>
                <GamingGuilds />
            </DialogProvider>
        </>
    );
}

export default VerifyOtpPage;
