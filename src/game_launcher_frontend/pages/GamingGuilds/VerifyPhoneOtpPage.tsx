import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import Loader from "@/components/ui/Loader";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { navPaths } from "@/shared";
import DialogProvider from "@/components/DialogProvider";
import GamingGuilds from ".";
import {
    OpenDialogType,
    StateTypes
} from "../../types/dialogTypes";
import PhoneOtpPage from "./PhoneOtpPage";

const VerifyPhoneOtpPage = () => {
    
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
        component: <PhoneOtpPage/>,
        isOpen: true,
        title: "Verify OTP to Receive Phone Badge",
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

export default VerifyPhoneOtpPage;
