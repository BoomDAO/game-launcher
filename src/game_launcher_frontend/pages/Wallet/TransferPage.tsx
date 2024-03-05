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
import Loader from "@/components/ui/Loader";
import { useAuthContext } from "@/context/authContext";
import { useICRCLedgerClient } from "@/hooks";

const scheme = z.object({
    principal: z.string().min(1, "Principal is required."),
    amount: z.string().min(1, "Amount is required.")
});
type Data = z.infer<typeof scheme>;

const TransferPage = () => {
    const { t } = useTranslation();
    const { canisterId } = useParams();
    const { session } = useAuthContext();
    let [symbol, setSymbol] = React.useState(getTokenSymbol(canisterId));
    let [transferAmount, setTransferAmount] = React.useState("");
    let [isTransferAmountLoading, setIsTransferAmountLoading] = React.useState(false);

    const { control, handleSubmit } = useForm<Data>({
        defaultValues: {
            principal: "",
            amount: "",
        },
        resolver: zodResolver(scheme),
    });
    React.useEffect(() => {
        (async () => {
            if (canisterId != undefined) {
                setIsTransferAmountLoading(true);
                const { actor, methods } = await useICRCLedgerClient(canisterId ? canisterId : "");
                let balance = await actor[methods.icrc1_balance_of]({
                    owner: session?.identity?.getPrincipal(),
                    subaccount: []
                }) as number;
                let fee = await actor[methods.icrc1_fee]() as number;
                let transfer_amount = balance - fee;
                if (transfer_amount < 0) {
                    transfer_amount = 0;
                }
                let res = ((Number(transfer_amount) * 1.0) / 100000000.0).toFixed(8);
                setTransferAmount(res);
                setIsTransferAmountLoading(false);
            }
        })();
        return () => {
        };
    }, [canisterId]);

    const { mutate: details, isLoading: isIcrcTransferLoading } = useIcrcTransfer();

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
                    <Button size="big" isLoading={isIcrcTransferLoading}>
                        Withdraw
                    </Button>
                </Form>
            </div>
            <div className="float-left pl-10 mt-3 text-xl font-semibold flex">Available to Withdraw : {
                isTransferAmountLoading ? <Loader className="w-6 h-6 ml-2"></Loader> : <p className="ml-2">{transferAmount}</p>
            }</div>
        </>
    );
}

export default TransferPage;
