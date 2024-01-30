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
import { useVerifyEmail, useVerifyPhone } from "@/api/guilds";

const scheme = z.object({
    phone: z.string().min(1, "Phone is required."),
    otp: z.string().min(1, "OTP is required."),
});
type Data = z.infer<typeof scheme>;

const VerifyPhoneOtpPage = () => {
    const { phone } = useParams();
    const { t } = useTranslation();
    const navigate = useNavigate();

    const {
        control: verifyPhoneControl,
        handleSubmit: handleVerifyPhone,
        reset: resetAdd,
    } = useForm<Data>({
        defaultValues: {
            phone: phone,
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

    const { data: result = "", mutate: verifyPhone, isLoading: isLoadingVerifyPhone } = useVerifyPhone();

    const onVerifyPhone = (values: Data) => {
        verifyPhone(
            { ...values },
            {
                onSuccess: () => {
                    resetAdd();
                    close();
                    navigate(navPaths.gaming_guilds);
                    location.reload();
                },
                onError: () => { }
            },
        );
    };

    const [state, setState] = React.useState<StateTypes>({
        component: <div>
            <Form className="w-6/12 m-auto items-center" onSubmit={handleVerifyPhone(onVerifyPhone)}>
                <FormTextInput
                    className="dark:border-gray-600"
                    control={verifyPhoneControl}
                    name="otp"
                    placeholder={t("verification.otp_input_sms",)}
                />
                <Button size="big" className="cursor-pointer" rightArrow isLoading={isLoadingVerifyPhone}>
                    {t("verification.otp_button")}
                </Button>
            </Form>
        </div>,
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
