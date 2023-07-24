import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useCreateWorldData,
  useCreateWorldUpload,
} from "@/api/world_deployer";
import { PreparingForUpload, UploadResult } from "@/components/Results";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormNumberInput from "@/components/form/FormNumberInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { worldDataScheme } from "@/shared";

const scheme = z
  .object({
    cover: z.string().min(1, { message: "Cover image is required." })
  })
  .extend(worldDataScheme);

type Data = z.infer<typeof scheme>;

const CreateWorld = () => {
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
      cover: "",
    },
    resolver: zodResolver(scheme),
  });

  const cover = watch("cover");

  const {
    mutateAsync: mutateData,
    isLoading: isDataLoading,
    isError: isDataError,
    isSuccess: isDataSuccess,
    error: dataError,
  } = useCreateWorldData();

  const {
    mutateAsync: onUploadWorld,
    isLoading: isUploadLoading,
    error: uploadError,
  } = useCreateWorldUpload();

  React.useEffect(() => {
    const err = uploadError as { canister_id?: string };

    if (err?.canister_id) {
      setCanisterId(err.canister_id);
    }
  }, [uploadError]);

  const onUpload = async (values: Data) => {
    isPreparingUpload(false);

    await onUploadWorld({
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
      <H1>{t("world_deployer.create_world.title")}</H1>
      <Space size="medium" />

      <Form onSubmit={onSubmit}>
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormTextInput
            placeholder={t("world_deployer.create_world.input_name")}
            control={control}
            name="name"
            disabled={!!canisterId}
          />
          <div className="flex w-full flex-col gap-6">
            <FormUploadButton
              buttonText={t("world_deployer.create_world.button_cover_upload")}
              placeholder={t("world_deployer.create_world.placeholder_cover_upload")}
              control={control}
              setDisableSubmit={setDisableSubmit}
              name="cover"
              disabled={!!canisterId}
            />
            {cover && <img src={cover} alt="cover" className="w-full" />}
          </div>
        </div>

        <Button
          rightArrow
          isLoading={isDataLoading}
          size="big"
          disabled={isUploadLoading || disableSubmit}
        >
          {t("world_deployer.create_world.create_button")}
        </Button>
      </Form>
    </>
  );
};

export default CreateWorld;
