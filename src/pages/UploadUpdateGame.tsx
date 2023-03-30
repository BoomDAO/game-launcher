import { useForm } from "react-hook-form";
import toast from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useCreateGame } from "@/api/games";
import Form from "@/components/form/Form";
import FormSelect from "@/components/form/FormSelect";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import { SelectOption } from "@/components/ui/Select";
import Space from "@/components/ui/Space";
import { navPaths } from "@/shared";

const game_types: SelectOption[] = [
  {
    label: "Browser",
    value: "Browser",
  },
  {
    label: "Android",
    value: "Android",
  },
  {
    label: "Mac",
    value: "Mac",
  },
  {
    label: "PC",
    value: "PC",
  },
];

const scheme = z.object({
  name: z.string().min(1, { message: "Name is required." }),
  description: z.string().min(1, { message: "Description is required." }),
  cover: z.string().min(1, { message: "Cover image is required." }),
  platform: z.string().min(1, { message: "Platform is required." }),
  game: z.string(),
});

type Form = z.infer<typeof scheme>;

const UploadUpdateGame = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { canisterId } = useParams();

  const newGame = canisterId === "new";

  const { control, handleSubmit, watch } = useForm<Form>({
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

  const { mutateAsync, isLoading } = useCreateGame();

  const onSubmit = async (values: Form) => {
    console.log(values);

    const data = await mutateAsync(values, {
      onError: (err) => {
        toast.error(t("upload_games.error_create"));
        console.log("err", err);
      },
      onSuccess: () => {
        toast.success(`Game was created.`);
        navigate(navPaths.upload_games);
      },
    });

    console.log("data", data);
  };

  const heading = newGame
    ? t("upload_games.new.title")
    : t("upload_games.update.title");
  const button_text = newGame
    ? t("upload_games.new.button")
    : t("upload_games.update.button");

  return (
    <>
      <Space size="medium" />
      <H1>{heading}</H1>
      <Space size="medium" />

      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormSelect data={game_types} control={control} name="platform" />

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

        <Button rightArrow size="big" isLoading={isLoading}>
          {button_text}
        </Button>
      </Form>
    </>
  );
};

export default UploadUpdateGame;
