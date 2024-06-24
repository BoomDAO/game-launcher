import React from "react";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import { useTranslation } from "react-i18next";
import { z } from "zod";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { getTokenSymbol } from "@/api/profile";
import Loader from "@/components/ui/Loader";
import { useAuthContext } from "@/context/authContext";
import { ledger_canisterId, useICRCLedgerClient } from "@/hooks";
import { useParticipateICPTransfer } from "@/api/launchpad";

const scheme = z.object({
    amount: z.string().min(1, "Amount is required.")
});
type Data = z.infer<typeof scheme>;

const ParticipateTransfer = () => {
    const { t } = useTranslation();
    const { canisterId } = useParams();
    const { session } = useAuthContext();
    let [transferAmount, setTransferAmount] = React.useState("");
    let [isTransferAmountLoading, setIsTransferAmountLoading] = React.useState(false);

    const { control, handleSubmit } = useForm<Data>({
        defaultValues: {
            amount: "",
        },
        resolver: zodResolver(scheme),
    });
    React.useEffect(() => {
        (async () => {
            if (canisterId != undefined) {
                setIsTransferAmountLoading(true);
                const { actor, methods } = await useICRCLedgerClient(ledger_canisterId);
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

    const { mutate: details, isLoading: isIcrcTransferLoading } = useParticipateICPTransfer();

    const onSubmit = (values: Data) =>
        details(
            { canisterId: canisterId, amount: values.amount },
            {
                onSuccess: () => {
                },
            },
        );
    
    const onMaxClick = () => {
        let inputBox = document.getElementById("amount");
        if(inputBox) {
            inputBox.value = (transferAmount).split(".")[0];
        }
    }

    return (
        <>
            <p className="text-2xl pb-4 font-semibold">Participate</p>
            <div className="w-full">
                <div className="text-left pl-10 pb-5 mt-3 text-xl flex">Your Balance : {
                    isTransferAmountLoading ? <Loader className="w-6 h-6 ml-2"></Loader> : <p className="ml-2">{transferAmount}</p>
                }</div>
                <div className="flex px-10 justify-between">
                    <p>Amount</p>
                    <button onClick={onMaxClick}>MAX</button>
                </div>
                <div className="mt-2 mb-2 text-lg px-10">
                    <Form onSubmit={handleSubmit(onSubmit)} className="items-center">
                        <FormTextInput
                            className="dark:border-gray-600 rounded-xl"
                            control={control}
                            name="amount"
                            placeholder="Amount"
                            min={0}
                            id="amount"
                            value={undefined}
                        />
                        <p className="w-full mt-0 pt-0 text-left text-sm">Transaction Fee (billed to source) <br></br> 0.0001 ICP</p>
                        <Button className="rounded-xl" size="big" isLoading={isIcrcTransferLoading}>
                            Continue
                        </Button>
                    </Form>
                </div>
            </div>
        </>
    );
}

export default ParticipateTransfer;
