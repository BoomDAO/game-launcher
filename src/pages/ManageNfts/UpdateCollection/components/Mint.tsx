import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMint } from "@/api/minting_deployer";
import Form from "@/components/form/Form";
import FormCheckbox from "@/components/form/FormCheckbox";
import FormNumberInput from "@/components/form/FormNumberInput";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  mintForAddress: z.string().min(1, "Collection  is required."),
  principals: z.string().min(1, "List of addresses or principals is required."),
  metadata: z.string().min(1, "Metadata are required."),
  nft: z.string().min(1, "Image is required."),
  burnTime: z.string(),
  address: z.boolean(),
});

type Data = z.infer<typeof scheme>;

const Mint = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { control, handleSubmit, watch, reset } = useForm<Data>({
    defaultValues: {
      mintForAddress: "",
      metadata: "",
      nft: "",
      burnTime: "",
      principals: "",
      address: false,
    },
    resolver: zodResolver(scheme),
  });

  const nft = watch("nft");

  const { mutate, isLoading } = useMint();

  const onSubmit = (values: Data) =>
    mutate(
      { ...values, canisterId },
      {
        onSuccess: () => reset(),
      },
    );

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.mint.title")}</SubHeading>
      <Space />

      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex flex-col gap-6 md:flex-row">
          <FormNumberInput
            control={control}
            name="mintForAddress"
            placeholder={t(
              "manage_nfts.update.mint.input_placeholder_mint_number",
            )}
          />
          <FormNumberInput
            control={control}
            name="burnTime"
            min={0}
            placeholder={t("manage_nfts.update.mint.input_placeholder_burn")}
            hint={{
              body: t("manage_nfts.update.mint.input_helper_burn"),
            }}
          />
        </div>

        <FormTextArea
          control={control}
          name="metadata"
          placeholder={t("manage_nfts.update.mint.textarea_metadata")}
        />

        <FormCheckbox
          control={control}
          name="address"
          label={t("manage_nfts.update.mint.checkbox_addresses")}
          id="address"
        />

        <FormTextArea
          control={control}
          name="principals"
          placeholder={t("manage_nfts.update.mint.textarea_addresses")}
        />

        <div className="grid grid-cols-1 justify-items-center md:grid-cols-2">
          <FormUploadButton
            buttonText={t("manage_nfts.update.mint.upload_button")}
            placeholder={t("manage_nfts.update.mint.upload_placeholder")}
            control={control}
            name="nft"
          />
          {nft && <img src={nft} alt="cover" className="h-full w-[200px]" />}
        </div>

        <Button size="big" rightArrow isLoading={isLoading}>
          {t("manage_nfts.update.mint.button")}
        </Button>
      </Form>
    </div>
  );
};

export default Mint;
