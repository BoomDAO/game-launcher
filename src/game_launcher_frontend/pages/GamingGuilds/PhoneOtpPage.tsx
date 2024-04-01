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
import { useVerifyPhone } from "@/api/guilds";


const scheme = z.object({
    phone: z.string().min(1, "Phone is required."),
    otp: z.string().min(1, "OTP is required."),
});
type Data = z.infer<typeof scheme>;

const PhoneOtpPage = () => {
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

    const { data: result, mutate: verifyPhone, isLoading: isLoadingVerifyOtp } = useVerifyPhone();

    const onVerifyPhone = (values: Data) => {
        verifyPhone(
            { ...values },
            {
                onSuccess: () => {
                    resetAdd();
                    navigate(navPaths.home);
                },
                onError: () => {

                },
            },
        );
    };

    return (
        <div>
            <Form className="w-6/12 m-auto items-center" onSubmit={handleVerifyPhone(onVerifyPhone)}>
                <FormTextInput
                    className="dark:border-gray-600"
                    control={verifyPhoneControl}
                    name="otp"
                    placeholder={t("verification.otp_input_sms")}
                />
                <Button size="big" rightArrow isLoading={isLoadingVerifyOtp}>{t("verification.otp_button")}</Button>
            </Form>
        </div>
    );
}

export default PhoneOtpPage;
