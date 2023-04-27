import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAirdrop } from "@/api/minting_deployer";
import Form from "@/components/form/Form";
import FormCheckbox from "@/components/form/FormCheckbox";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  collectionId: z.string().min(1, "Collection  is required."),
  metadata: z.string().min(1, "Metadata are required."),
  nft: z.string().min(1, "Image is required."),
  burnTime: z.string(),
  prevent: z.boolean(),
});

type Data = z.infer<typeof scheme>;

const Airdrop = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { control, handleSubmit, watch, reset } = useForm<Data>({
    defaultValues: {
      collectionId: "",
      metadata: "",
      nft: "",
      burnTime: "",
      prevent: false,
    },
    resolver: zodResolver(scheme),
  });

  const nft = watch("nft");

  const { mutate, isLoading } = useAirdrop();

  const onSubmit = (values: Data) =>
    mutate(
      { ...values, canisterId },
      {
        onSuccess: () => reset(),
      },
    );

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.airdrop.title")}</SubHeading>
      <Space />

      <Form onSubmit={handleSubmit(onSubmit)}>
        <FormCheckbox
          control={control}
          name="prevent"
          label={t("manage_nfts.update.airdrop.checkbox_prevent")}
          id="prevent"
        />

        <div className="flex flex-col gap-6 md:flex-row">
          <FormTextInput
            control={control}
            name="collectionId"
            placeholder={t(
              "manage_nfts.update.airdrop.input_placeholder_canister",
            )}
          />
          <FormTextInput
            control={control}
            name="burnTime"
            placeholder={t("manage_nfts.update.airdrop.input_placeholder_burn")}
          />
        </div>

        <FormTextArea
          control={control}
          name="metadata"
          placeholder={t("manage_nfts.update.airdrop.textarea_metadata")}
        />

        <div className="grid grid-cols-1 justify-items-center md:grid-cols-2">
          <FormUploadButton
            buttonText={t("manage_nfts.update.airdrop.upload_button")}
            placeholder={t("manage_nfts.update.airdrop.upload_placeholder")}
            control={control}
            name="nft"
          />
          {nft && <img src={nft} alt="cover" className="h-full w-[200px]" />}
        </div>

        <Button size="big" rightArrow isLoading={isLoading}>
          {t("manage_nfts.update.airdrop.button")}
        </Button>
      </Form>
    </div>
  );
};

export default Airdrop;
