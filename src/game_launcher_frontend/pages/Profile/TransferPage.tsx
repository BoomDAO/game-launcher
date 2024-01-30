import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { getTokenSymbol, useIcrcTransfer } from "@/api/profile";

const scheme = z.object({
    principal: z.string().min(1, "Principal is required."),
    amount: z.string().min(1, "Amount is required.")
});
type Data = z.infer<typeof scheme>;

const TransferPage = () => {
    const { t } = useTranslation();
    const { canisterId } = useParams();
    let [symbol, setSymbol] = React.useState(getTokenSymbol(canisterId));

    const { control, handleSubmit } = useForm<Data>({
        defaultValues: {
            principal: "",
            amount: "",
        },
        resolver: zodResolver(scheme),
    });

    const { mutate: details, isLoading: isLoading } = useIcrcTransfer();

    const onSubmit = (values: Data) =>
        details(
            { principal: values.principal, canisterId: canisterId, amount: values.amount },
            {
                onSuccess: () => {
                },
            },
        );

    return (
        <>
            <p className="text-2xl pb-4 font-semibold">Withdraw {symbol} Tokens</p>
            <div className="mt-2 mb-2 text-lg px-10">
                <Form onSubmit={handleSubmit(onSubmit)} className="items-center">
                    <FormTextInput
                        className="dark:border-gray-600"
                        control={control}
                        name="principal"
                        placeholder="To Principal"
                        min={0}
                    />
                    <FormTextInput
                        className="dark:border-gray-600"
                        control={control}
                        name="amount"
                        placeholder="Amount"
                        min={0}
                    />
                    <Button size="big" isLoading={isLoading}>
                        Withdraw
                    </Button>
                </Form>
            </div>
        </>
    );
}

export default TransferPage;
