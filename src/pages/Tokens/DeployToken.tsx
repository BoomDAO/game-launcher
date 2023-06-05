import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useCreateTokenData,
  useCreateTokenUpload,
} from "@/api/token_deployer";
import { PreparingForUpload, UploadResult } from "@/components/Results";
import UploadGameHint from "@/components/UploadGameHint";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormNumberInput from "@/components/form/FormNumberInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { tokenDataScheme } from "@/shared";

const scheme = z
  .object({
    logo: z.string().min(1, { message: "Logo image is required." })
  })
  .extend(tokenDataScheme);

type Data = z.infer<typeof scheme>;

const DeployToken = () => {
  const [disableSubmit, setDisableSubmit] = React.useState(false);
  const [showPrepare, setShowPrepare] = React.useState(false);
  const [canisterId, setCanisterId] = React.useState<string>();

  const { t } = useTranslation();

  const isPreparingUpload = (val: boolean) => {
    setShowPrepare(val);
    setDisableSubmit(val);
  };

  const { control, handleSubmit, watch } = useForm<Data>({
    defaultValues: {
      name: "",
      description: "",
      symbol: "",
      amount: "",
      logo: "",
      decimals: "",
      fee: "",
    },
    resolver: zodResolver(scheme),
  });

  const logo = watch("logo");

  const {
    mutateAsync: mutateData,
    isLoading: isDataLoading,
    isError: isDataError,
    isSuccess: isDataSuccess,
    error: dataError,
  } = useCreateTokenData();

  const {
    mutateAsync: onUploadToken,
    isLoading: isUploadLoading,
    error: uploadError,
  } = useCreateTokenUpload();

  React.useEffect(() => {
    const err = uploadError as { canister_id?: string };

    if (err?.canister_id) {
      setCanisterId(err.canister_id);
    }
  }, [uploadError]);

  const onUpload = async (values: Data) => {
    isPreparingUpload(false);

    await onUploadToken({
      values,
      mutateData,
      canisterId,
    });
  };

  const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    isPreparingUpload(true);
    await new Promise((resolve) => {
      setTimeout(() => resolve(handleSubmit(onUpload)(e)), 500);
    });
    isPreparingUpload(false);
  };

  return (
    <>
      <Space size="medium" />
      <H1>{t("token_deployer.deploy_token.title")}</H1>
      <Space size="medium" />

      <Form onSubmit={onSubmit}>
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormTextInput
            placeholder={t("token_deployer.input_name")}
            control={control}
            name="name"
            disabled={!!canisterId}
          />
          <FormTextInput
            placeholder={t("token_deployer.input_symbol")}
            control={control}
            name="symbol"
            disabled={!!canisterId}
          />
        </div>
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormTextInput
            placeholder={t("token_deployer.input_amount")}
            control={control}
            name="amount"
            disabled={!!canisterId}
          />
          <FormNumberInput
            placeholder={t("token_deployer.input_decimals")}
            control={control}
            name="decimals"
            disabled={!!canisterId}
            min={0}
          />
        </div>
        <FormTextArea
          placeholder={t("token_deployer.input_description")}
          control={control}
          name="description"
          disabled={!!canisterId}
        />
        <div className="flex w-full flex-col gap-4 lg:flex-row">
          <div className="flex w-full flex-col gap-6">
            <FormUploadButton
              buttonText={t("token_deployer.button_logo_upload")}
              placeholder={t("token_deployer.placeholder_logo_upload")}
              control={control}
              setDisableSubmit={setDisableSubmit}
              name="logo"
              disabled={!!canisterId}
            />
            {logo && <img src={logo} alt="cover" className="w-full" />}
          </div>
          <FormNumberInput
            placeholder={t("token_deployer.input_fee")}
            control={control}
            name="fee"
            disabled={!!canisterId}
            min={0}
          />
        </div>

        <Button
          rightArrow
          size="big"
          disabled={isUploadLoading || disableSubmit}
        >
          {t("token_deployer.deploy_token.deploy_button")}
        </Button>
      </Form>
    </>
  );
};

export default DeployToken;
