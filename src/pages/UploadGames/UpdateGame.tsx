import React from "react";
import { useForm } from "react-hook-form";
import toast from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useGetGame } from "@/api/games";
import { ErrorResult, LoadingResult } from "@/components/Results";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";
import { gameDataScheme, navPaths, platform_types } from "@/shared";

const scheme = z
  .object({
    cover: z.string(),
    game: z.string(),
  })
  .extend(gameDataScheme);

type Form = z.infer<typeof scheme>;

const UploadUpdateGame = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { canisterId } = useParams();

  const { data, isLoading: isLoadingGame, isError } = useGetGame(canisterId);

  const { control, handleSubmit, watch, reset } = useForm<Form>({
    defaultValues: {
      name: "",
      description: "",
      platform: "Browser",
      cover: "",
      game: "",
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

  // const { mutateAsync, isLoading: isUploadGameData } = useCreateGame();

  const onSubmit = async (values: Form) => {
    console.log(values);

    // const data = await mutateAsync(values, {
    //   onError: (err) => {
    //     toast.error(t("upload_games.error_create"));
    //     console.log("err", err);
    //   },
    //   onSuccess: () => {
    //     toast.success(`Game was created.`);
    //     navigate(navPaths.upload_games);
    //   },
    // });

    // console.log("data", data);
  };

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
                imageUpload
                control={control}
                name="cover"
              />
              {cover && <img src={cover} alt="cover" className="w-full" />}
            </div>

            <FormUploadButton
              buttonText={t("upload_games.button_game_upload")}
              placeholder={t("upload_games.placeholder_game_upload")}
              control={control}
              name="game"
            />
          </div>

          <Button rightArrow size="big" isLoading={false}>
            {t("upload_games.update.button")}
          </Button>
        </Form>
      )}
    </>
  );
};

export default UploadUpdateGame;