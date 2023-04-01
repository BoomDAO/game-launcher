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
import { ErrorResult, LoadingResult, UploadResult } from "@/components/Results";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { gameDataScheme, navPaths, platform_types } from "@/shared";
import { GameFile } from "@/utils";

const scheme = z
  .object({
    cover: z.string(),
    game: z.custom<GameFile>().array(),
  })
  .extend(gameDataScheme);

type Form = z.infer<typeof scheme>;

const UpdateGame = () => {
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
  } = useUpdateGameData();
  const {
    mutateAsync: mutateCover,
    isLoading: isCoverLoading,
    isError: isCoverError,
    isSuccess: isCoverSuccess,
  } = useUpdateGameCover();
  const {
    mutateAsync: mutateFiles,
    isLoading: isFilesLoading,
    isError: isFilesError,
    isSuccess: isFilesSuccess,
  } = useUpdateGameFiles();

  const { mutate: onSubmitGame } = useUpdateGameSubmit();

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
        <Form onSubmit={handleSubmit(onSubmit)}>
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
                control={control}
                name="cover"
              />
              {cover && <img src={cover} alt="cover" className="w-full" />}
            </div>

            <FormUploadButton
              buttonText={t("upload_games.button_game_upload")}
              placeholder={t("upload_games.placeholder_game_upload")}
              uploadType="folder"
              control={control}
              name="game"
            />
          </div>

          <div className="flex flex-col gap-2">
            <UploadResult
              isLoading={{
                display: isDataLoading,
                text: "Uploading game data...",
              }}
              isError={{
                display: isDataError,
                text: "There was some error while updating data.",
              }}
              isSuccess={{ display: isDataSuccess, text: "Data were updated." }}
            />

            <UploadResult
              isLoading={{
                display: isCoverLoading,
                text: "Uploading game cover...",
              }}
              isError={{
                display: isCoverError,
                text: "There was some error while updating cover.",
              }}
              isSuccess={{
                display: isCoverSuccess,
                text: "Cover were updated",
              }}
            />

            <UploadResult
              isLoading={{
                display: isFilesLoading,
                text: "Uploading game files... Please wait till finish.",
              }}
              isError={{
                display: isFilesError,
                text: "There was some error while updating files.",
              }}
              isSuccess={{
                display: isFilesSuccess,
                text: "Files were updated",
              }}
            />
          </div>

          <Button
            rightArrow
            size="big"
            disabled={isDataLoading || isCoverLoading || isFilesLoading}
          >
            {t("upload_games.update.button")}
          </Button>
        </Form>
      )}
    </>
  );
};

export default UpdateGame;
