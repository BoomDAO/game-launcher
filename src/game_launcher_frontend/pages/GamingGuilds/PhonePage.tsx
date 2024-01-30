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
import { useSubmitPhone } from "@/api/guilds";


const scheme = z.object({
    phone: z.string().min(1, "Phone Number is required."),
});

type Data = z.infer<typeof scheme>;

const PhonePage = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();

    const {
        control: submitPhoneControl,
        handleSubmit: handleSubmitPhone,
        reset: resetAdd,
    } = useForm<Data>({
        defaultValues: {
            phone: "",
        },
        resolver: zodResolver(scheme),
    });

    const { data: result = "", mutate: submitPhone, isLoading: isLoadingSubmitPhone } = useSubmitPhone();

    const onSubmitPhone = (values: Data) => {
        submitPhone(
            { ...values },
            {
                onSuccess: () => {
                    resetAdd()
                    navigate((navPaths.gaming_guilds_phone_verification) + "/" + values.phone);
                },
                onError: () => {
                    console.log("error");
                }
            },
        );
    };
    
    return (
        <div>
            <p className="mb-5">This status makes you eligible to participate in Gaming Guilds quests which requires Phone Badge.</p>
            <Form className="w-6/12 m-auto items-center" onSubmit={handleSubmitPhone(onSubmitPhone)}>
                <FormTextInput
                    className="dark:border-gray-600"
                    control={submitPhoneControl}
                    name="phone"
                    placeholder={t("verification.input_placeholder_phone",)}
                />

                <Button size="big" rightArrow isLoading={isLoadingSubmitPhone}>
                    {t("verification.button_phone")}
                </Button>
            </Form>
        </div>
    );
}

export default PhonePage;
