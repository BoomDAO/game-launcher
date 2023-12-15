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


const scheme = z.object({
    email: z.string().min(1, "Email is required."),
});

type Data = z.infer<typeof scheme>;

const EmailPage = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();

    const {
        control: submitEmailControl,
        handleSubmit: handleSubmitEmail,
        reset: resetAdd,
    } = useForm<Data>({
        defaultValues: {
            email: "",
        },
        resolver: zodResolver(scheme),
    });

    const { data: result = "", mutate: submitEmail, isLoading: isLoadingSubmitEmail } = useSubmitEmail();

    const onSubmitEmail = (values: Data) => {
        submitEmail(
            { ...values },
            {
                onSuccess: () => {
                    resetAdd()
                    navigate((navPaths.gaming_guilds_verification) + "/" + values.email);
                },
                onError: () => {
                    console.log("error");
                }
            },
        );
    };
    
    return (
        <div>
            <p className="mb-5">If you registered to be a DAO member on the BOOM DAO website before the SNS, you are eligible to
                verify the same email that you used to sign up to receive the OG Badge in the BOOM Gaming Guild.
                <br></br>
                <br></br>
                This status makes you eligible to participate in airdrop-related quests to receive rewards.</p>
            <Form className="w-6/12 m-auto items-center" onSubmit={handleSubmitEmail(onSubmitEmail)}>
                <FormTextInput
                    className="dark:border-gray-600"
                    control={submitEmailControl}
                    name="email"
                    placeholder={t("verification.input_placeholder",)}
                />

                <Button size="big" rightArrow isLoading={isLoadingSubmitEmail}>
                    {t("verification.button")}
                </Button>
            </Form>
        </div>
    );
}

export default EmailPage;
