import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useGetGame,
  useUpdateGameCover,
  useUpdateGameData,
  useUpdateGameFiles,
  useUpdateGameSubmit,
} from "@/api/deployer";
import {
  ErrorResult,
  LoadingResult,
  PreparingForUpload,
  UploadResult,
} from "@/components/Results";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { gameDataScheme, platform_types } from "@/shared";
import { GameFile } from "@/utils";

const scheme = z
  .object({
    cover: z.string(),
    game: z.custom<GameFile>().array(),
  })
  .extend(gameDataScheme);

type Form = z.infer<typeof scheme>;

const UpdateGame = () => {
  const [showPrepare, setShowPrepare] = React.useState(false);
  const [disableSubmit, setDisableSubmit] = React.useState(false);

  const { t } = useTranslation();
  const { canisterId } = useParams();

  const { data, isLoading: isLoadingGame, isError } = useGetGame(canisterId);

  const { control, handleSubmit, watch, reset } = useForm<Form>({
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

  React.useEffect(() => {
    if (!data) return;
    reset({
      name: data.name,
      description: data.description,
      platform: data.platform,
    });
  }, [data]);

  const {
    mutateAsync: mutateData,
    isLoading: isDataLoading,
    isError: isDataError,
    isSuccess: isDataSuccess,
    error: dataError,
  } = useUpdateGameData();
  const {
    mutateAsync: mutateCover,
    isLoading: isCoverLoading,
    isError: isCoverError,
    isSuccess: isCoverSuccess,
    error: coverError,
  } = useUpdateGameCover();
  const {
    mutateAsync: mutateFiles,
    isLoading: isFilesLoading,
    isError: isFilesError,
    isSuccess: isFilesSuccess,
    error: filesError,
  } = useUpdateGameFiles();

  const { mutate: onSubmitGame, isLoading: isSubmitLoading } =
    useUpdateGameSubmit();

  const onSubmit = async (values: Form) =>
    onSubmitGame({
      values: { canister_id: canisterId!, ...values },
      mutateData,
      mutateCover,
      mutateFiles,
    });

  return (
    <>
      <Space size="medium" />
      <H1>{t("upload_games.update.title")}</H1>
      <Space size="medium" />

      {isLoadingGame ? (
        <LoadingResult>{t("upload_games.update.loading")}</LoadingResult>
      ) : isError ? (
        <ErrorResult>{t("upload_games.update.error")}</ErrorResult>
      ) : (
        <Form
          onSubmit={async (e) => {
            e.preventDefault();
            setDisableSubmit(true);
            setShowPrepare(true);
            await new Promise((resolve) =>
              setTimeout(() => resolve(handleSubmit(onSubmit)(e)), 500),
            );
            setShowPrepare(false);
            setDisableSubmit(false);
          }}
        >
          <div className="flex w-full flex-col gap-4 md:flex-row">
            <FormSelect
              data={platform_types}
              control={control}
              name="platform"
            />

            <FormTextInput
              placeholder={t("upload_games.input_name")}
              control={control}
              name="name"
            />
          </div>

          <FormTextArea
            placeholder={t("upload_games.input_description")}
            control={control}
            name="description"
          />

          <div className="flex w-full flex-col gap-4 lg:flex-row">
            <div className="flex w-full flex-col gap-6">
              <FormUploadButton
                buttonText={t("upload_games.button_cover_upload")}
                placeholder={t("upload_games.placeholder_cover_upload")}
                setDisableSubmit={setDisableSubmit}
                control={control}
                name="cover"
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
            {showPrepare && <PreparingForUpload />}

            <UploadResult
              isLoading={{
                display: isDataLoading,
                children: "Uploading game data...",
              }}
              isError={{
                display: isDataError,
                children: "There was some error while updating data.",
                error: dataError,
              }}
              isSuccess={{
                display: isDataSuccess,
                children: "Data were updated.",
              }}
            />

            <UploadResult
              isLoading={{
                display: isCoverLoading,
                children: "Uploading game cover...",
              }}
              isError={{
                display: isCoverError,
                children: "There was some error while updating cover.",
                error: coverError,
              }}
              isSuccess={{
                display: isCoverSuccess,
                children: "Cover were updated",
              }}
            />

            <UploadResult
              isLoading={{
                display: isFilesLoading,
                children: "Uploading game files... Please wait till finish.",
              }}
              isError={{
                display: isFilesError,
                children: "There was some error while updating files.",
                error: filesError,
              }}
              isSuccess={{
                display: isFilesSuccess,
                children: "Files were updated",
              }}
            />
          </div>

          <Button
            rightArrow
            size="big"
            disabled={isSubmitLoading || disableSubmit}
          >
            {t("upload_games.update.button")}
          </Button>
        </Form>
      )}
    </>
  );
};

export default UpdateGame;
