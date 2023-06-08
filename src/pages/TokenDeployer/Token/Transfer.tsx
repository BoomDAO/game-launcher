import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import Form from "@/components/form/Form";
import FormCheckbox from "@/components/form/FormCheckbox";
import FormNumberInput from "@/components/form/FormNumberInput";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";
import { useTokenTransfer } from "@/api/token_deployer";

const scheme = z.object({
  principal: z.string().min(1, "TransferTo is required."),
  amount: z.string().min(1, "Amount is required."),
});

type Data = z.infer<typeof scheme>;

const Transfer = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { control, handleSubmit, reset } = useForm<Data>({
    defaultValues: {
      principal: "",
      amount: ""
    },
    resolver: zodResolver(scheme),
  });

  const { mutate, isLoading, isError } = useTokenTransfer((canisterId != undefined)? canisterId : "");

  const onSubmit = (values: Data) =>
    mutate(
      { ...values},
      {
        onSuccess: () => reset(),
      },
    );

  return (
    <div>
      <SubHeading>{t("token_deployer.token.transfer.title")}</SubHeading>
      <Space/>
      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex flex-col gap-6 md:flex-row">
          <FormTextInput
            control={control}
            name="principal"
            placeholder={t(
              "token_deployer.token.transfer.transfer_to",
            )}
            hint={{
              body: t("token_deployer.token.transfer.input_helper_transfer_to"),
            }}
          />
          <FormNumberInput
            control={control}
            name="amount"
            min={0}
            placeholder={t("token_deployer.token.transfer.transfer_amount")}
          />
        </div>
        <Button size="big" isLoading={isLoading}>
          {t("token_deployer.token.transfer.transfer_button")}
        </Button>
      </Form>
    </div>
  );
};

export default Transfer;
