import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useCreateGameData,
  useCreateGameFiles,
  useCreateGameUpload,
} from "@/api/games_deployer";
import { PreparingForUpload, UploadResult } from "@/components/Results";
import UploadGameHint from "@/components/UploadGameHint";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { gameDataScheme, platform_types } from "@/shared";

const scheme = z
  .object({
    cover: z.string().min(1, { message: "Cover image is required." }),
    files: z.any().array().nonempty({
      message: "No files uploaded.",
    }),
  })
  .extend(gameDataScheme);

type Data = z.infer<typeof scheme>;

const CreateGame = () => {
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
      platform: "Browser",
      cover: "",
      files: [],
    },
    resolver: zodResolver(scheme),
  });

  const cover = watch("cover");
  const platform = watch("platform");

  const {
    mutateAsync: mutateData,
    isLoading: isDataLoading,
    isError: isDataError,
    isSuccess: isDataSuccess,
    error: dataError,
  } = useCreateGameData();

  const {
    mutateAsync: mutateFiles,
    isLoading: isFilesLoading,
    isError: isFilesError,
    isSuccess: isFilesSuccess,
    error: filesError,
  } = useCreateGameFiles();

  const {
    mutateAsync: onUploadGame,
    isLoading: isUploadLoading,
    error: uploadError,
  } = useCreateGameUpload();

  React.useEffect(() => {
    const err = uploadError as { canister_id?: string };

    if (err?.canister_id) {
      setCanisterId(err.canister_id);
    }
  }, [uploadError]);

  const onUpload = async (values: Data) => {
    isPreparingUpload(false);

    await onUploadGame({
      values,
      mutateData,
      mutateFiles,
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
      <H1>{t("upload_games.create.title")}</H1>
      <Space size="medium" />

      <Form onSubmit={onSubmit}>
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormSelect
            data={platform_types}
            control={control}
            name="platform"
            disabled={!!canisterId}
          />

          <FormTextInput
            placeholder={t("upload_games.input_name")}
            control={control}
            name="name"
            disabled={!!canisterId}
          />
        </div>

        <FormTextArea
          placeholder={t("upload_games.input_description")}
          control={control}
          name="description"
          disabled={!!canisterId}
        />

        <div className="flex w-full flex-col gap-4 lg:flex-row">
          <div className="flex w-full flex-col gap-6">
            <FormUploadButton
              buttonText={t("upload_games.button_cover_upload")}
              placeholder={t("upload_games.placeholder_cover_upload")}
              control={control}
              setDisableSubmit={setDisableSubmit}
              name="cover"
              disabled={!!canisterId}
            />
            {cover && <img src={cover} alt="cover" className="w-full" />}
          </div>

          <FormUploadButton
            buttonText={t("upload_games.button_game_upload")}
            placeholder={t("upload_games.placeholder_game_upload")}
            uploadType={platform === "Browser" ? "folder" : "zip"}
            setDisableSubmit={setDisableSubmit}
            control={control}
            name="files"
            hint={{
              body: <UploadGameHint />,
            }}
          />
        </div>

        <div className="flex flex-col gap-2">
          <PreparingForUpload show={showPrepare} />

          <UploadResult
            isLoading={{
              display: isDataLoading,
              children: t("upload_games.create.loading_game"),
            }}
            isError={{
              display: isDataError,
              children: t("upload_games.create.error_game"),
              error: dataError,
            }}
            isSuccess={{
              display: isDataSuccess,
              children: t("upload_games.create.success_game"),
            }}
          />

          <UploadResult
            isLoading={{
              display: isFilesLoading,
              children: t("upload_games.create.loading_files"),
            }}
            isError={{
              display: isFilesError,
              children: t("upload_games.create.error_files"),
              error: filesError,
            }}
            isSuccess={{
              display: isFilesSuccess,
              children: t("upload_games.create.success_files"),
            }}
          />
        </div>

        <Button
          rightArrow
          size="big"
          disabled={isUploadLoading || disableSubmit}
        >
          {t("upload_games.create.button")}
        </Button>
      </Form>
    </>
  );
};

export default CreateGame;
