import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useBurnNft } from "@/api/minting_deployer";
import Form from "@/components/form/Form";
import FormNumberInput from "@/components/form/FormNumberInput";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  index: z.string().min(1, "Index is required."),
});

type Data = z.infer<typeof scheme>;

const BurnNft = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { control, handleSubmit } = useForm<Data>({
    defaultValues: {
      index: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate, isLoading } = useBurnNft();

  const onSubmit = (values: Data) => mutate({ ...values, canisterId });

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.burn.title")}</SubHeading>
      <Space />

      <Form onSubmit={handleSubmit(onSubmit)}>
        <FormNumberInput
          control={control}
          name="index"
          placeholder={t("manage_nfts.update.burn.input_placeholder")}
          min={0}
        />

        <Button size="big" rightArrow isLoading={isLoading}>
          {t("manage_nfts.update.burn.button")}
        </Button>
      </Form>
    </div>
  );
};

export default BurnNft;
