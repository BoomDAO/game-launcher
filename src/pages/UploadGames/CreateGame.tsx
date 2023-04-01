import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useCreateGameData,
  useCreateGameFiles,
  useCreateGameSubmit,
} from "@/api/deployer";
import { PreparingForUpload, UploadResult } from "@/components/Results";
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
    game: z.any().array().nonempty({
      message: "No files uploaded.",
    }),
  })
  .extend(gameDataScheme);

type Form = z.infer<typeof scheme>;

const CreateGame = () => {
  const [disableSubmit, setDisableSubmit] = React.useState(false);
  const [showPrepare, setShowPrepare] = React.useState(false);

  const [canisterId, setCanisterId] = React.useState<string>();
  const { t } = useTranslation();

  const { control, handleSubmit, watch } = useForm<Form>({
    defaultValues: {
      name: "",
      description: "",
      platform: "Browser",
      cover: "",
      game: [],
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
  } = useCreateGameData();

  const {
    mutateAsync: mutateFiles,
    isLoading: isFilesLoading,
    isError: isFilesError,
    isSuccess: isFilesSuccess,
    error: filesError,
  } = useCreateGameFiles();

  const { mutateAsync: onSubmitGame, isLoading: isSubmitLoading } =
    useCreateGameSubmit();

  const onSubmit = async (values: Form) => {
    setShowPrepare(false);
    setDisableSubmit(false);

    const canister_id = await onSubmitGame({
      values,
      mutateData,
      mutateFiles,
      canisterId,
    });

    canister_id && setCanisterId(canister_id);
  };

  return (
    <>
      <Space size="medium" />
      <H1>{t("upload_games.new.title")}</H1>
      <Space size="medium" />

      <Form
        onSubmit={async (e) => {
          e.preventDefault();
          setShowPrepare(true);
          setDisableSubmit(true);

          await new Promise((resolve) => {
            setTimeout(() => resolve(handleSubmit(onSubmit)(e)), 500);
          });

          setShowPrepare(false);
          setDisableSubmit(false);
        }}
      >
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormSelect data={platform_types} control={control} name="platform" />

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
            uploadType="folder"
            setDisableSubmit={setDisableSubmit}
            control={control}
            name="game"
          />
        </div>

        <div className="flex flex-col gap-2">
          <PreparingForUpload show={showPrepare} />

          <UploadResult
            isLoading={{
              display: isDataLoading,
              children: "Creating game data...",
            }}
            isError={{
              display: isDataError,
              children:
                "There was some error while creating data. Please try again!",
              error: dataError,
            }}
            isSuccess={{
              display: isDataSuccess,
              children: "Data were saved.",
            }}
          />

          <UploadResult
            isLoading={{
              display: isFilesLoading,
              children: "Uploading game files... Please wait till finish.",
            }}
            isError={{
              display: isFilesError,
              children:
                "There was some error while updating files, but canister with data was created. Please try again!",
              error: filesError,
            }}
            isSuccess={{
              display: isFilesSuccess,
              children: "Files were created.",
            }}
          />
        </div>

        <Button
          rightArrow
          size="big"
          disabled={isSubmitLoading || disableSubmit}
        >
          {t("upload_games.new.button")}
        </Button>
      </Form>
    </>
  );
};

export default CreateGame;
