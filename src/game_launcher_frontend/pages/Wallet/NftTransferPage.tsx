import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { useNftTransfer } from "@/api/profile";
import Loader from "@/components/ui/Loader";
import { useAuthContext } from "@/context/authContext";

const scheme = z.object({
    principal: z.string().min(1, "Principal is required.")
});
type Data = z.infer<typeof scheme>;

const NftTransferPage = () => {
    const { t } = useTranslation();
    const { canisterId, tokenid } = useParams();
    const { control, handleSubmit } = useForm<Data>({
        defaultValues: {
            principal: "",
        },
        resolver: zodResolver(scheme),
    });

    const { mutate: details, isLoading: isNftTransferLoading } = useNftTransfer();

    const onSubmit = (values: Data) =>
        details(
            { principal: values.principal, canisterId: canisterId, tokenid: tokenid },
            {
                onSuccess: () => {
                },
            },
        );

    return (
        <>
            <p className="text-2xl pb-4 font-semibold">Transfer NFT</p>
            <div className="mt-2 mb-2 text-lg px-10">
                <Form onSubmit={handleSubmit(onSubmit)} className="items-center">
                    <FormTextInput
                        className="dark:border-gray-600"
                        control={control}
                        name="principal"
                        placeholder="To Principal"
                        min={0}
                    />
                    <Button size="big" isLoading={isNftTransferLoading}>
                        Transfer
                    </Button>
                </Form>
            </div>
        </>
    );
}

export default NftTransferPage;
