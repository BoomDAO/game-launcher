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
import { useVerifyEmail } from "@/api/guilds";


const scheme = z.object({
    email: z.string().min(1, "Email is required."),
    otp: z.string().min(1, "OTP is required."),
});
type Data = z.infer<typeof scheme>;

const EmailOtpPage = () => {
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

    const { data: result, mutate: verifyEmail, isLoading: isLoadingVerifyEmail } = useVerifyEmail();

    const onVerifyEmail = (values: Data) => {
        verifyEmail(
            { ...values },
            {
                onSuccess: () => {
                    resetAdd();
                    navigate(navPaths.home);
                },
                onError: () => {
                    
                }
            },
        );
    };
    
    return (
        <div>
            <Form className="w-6/12 m-auto items-center" onSubmit={handleVerifyEmail(onVerifyEmail)}>
                <FormTextInput
                    className="dark:border-gray-600"
                    control={verifyEmailControl}
                    name="otp"
                    placeholder={t("verification.otp_input")}
                />
                <Button rightArrow size="big" isLoading={isLoadingVerifyEmail}>{t("verification.otp_button")}</Button>
            </Form>
        </div>
    );
}

export default EmailOtpPage;
