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
import DialogProvider from "@/components/DialogProvider";
import GamingGuilds from ".";
import {
    DialogWidthType,
    DialogPropTypes,
    OpenDialogType,
    EmptyFunctionType,
    StateTypes
} from "../../types/dialogTypes";
import { useVerifyEmail } from "@/api/guilds";

const scheme = z.object({
    email: z.string().min(1, "Email is required."),
    otp: z.string().min(1, "OTP is required."),
});
type Data = z.infer<typeof scheme>;

const VerifyOtpPage = () => {
    const { email } = useParams();
    const { t } = useTranslation();
    const navigate = useNavigate();

    const {
        control: verifyEmailControl,
        handleSubmit: handleVerifyEmail,
        reset: resetAdd,
    } = useForm<Data>({
        defaultValues: {
            email: email,
            otp: "",
        },
        resolver: zodResolver(scheme),
    });

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
        navigate(navPaths.gaming_guilds);
    };

    const { data: result = "", mutate: verifyEmail, isLoading: isLoadingVerifyEmail } = useVerifyEmail();

    const onVerifyEmail = (values: Data) => {
        verifyEmail(
            { ...values },
            {
                onSuccess: () => {
                    resetAdd();
                    close();
                    navigate(navPaths.gaming_guilds);
                    location.reload();
                },
                onError: () => {
                    document.getElementById("button").className = "gradient-bg gap-2 px-12 py-4 text-base md:text-lg flex w-fit items-center rounded-primary uppercase text-white";
                }
            },
        );
    };

    const [state, setState] = React.useState<StateTypes>({
        component: <div>
            <Form className="w-6/12 m-auto items-center" onSubmit={handleVerifyEmail(onVerifyEmail)}>
                <FormTextInput
                    className="dark:border-gray-600"
                    control={verifyEmailControl}
                    name="otp"
                    placeholder={t("verification.otp_input",)}
                />
                <button id="button"
                    className="gradient-bg gap-2 px-12 py-4 text-base md:text-lg flex w-fit items-center rounded-primary uppercase text-white"
                    onClick={
                        () => {
                            document.getElementById("button").className = "hidden"
                        }
                    }
                >{t("verification.otp_button")}</button>
            </Form>
        </div>,
        isOpen: true,
        title: "Verify Email to Receive OG Badge",
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
