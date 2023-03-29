import React from "react";
import { Controller, useForm } from "react-hook-form";
import toast from "react-hot-toast";
import { useTranslation } from "react-i18next";
import { useNavigate, useNavigation, useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useCreateGame } from "@/api/games";
import Form from "@/components/form/Form";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Select, { SelectOption } from "@/components/ui/Select";
import Space from "@/components/ui/Space";
import UploadButton from "@/components/ui/UploadButton";
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
  platform: z.string(),
  cover: z.string(),
  // platform: z.string().min(1, { message: "Platform is required." }),
  // image: z.string().min(1, { message: "Image is required." }),
});

type Form = z.infer<typeof scheme>;

const UploadUpdateGame = () => {
  const navigate = useNavigate();
  const { canisterId } = useParams();
  const { t } = useTranslation();

  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<Form>({
    defaultValues: {
      name: "",
      description: "",
      platform: "Browser",
      cover: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate, isLoading } = useCreateGame();

  const onSubmit = (values: Form) => {
    console.log(values);
    mutate(values, {
      onError: (err) => {
        toast.error(
          "There was an error while creating new game. Please try again!",
        );
        console.log("err", err);
      },
      onSuccess: (canisterId) => {
        toast.success(`Game with canisterId ${canisterId} was created.`);
        navigate(navPaths.upload_games);
      },
    });
  };

  const newGame = canisterId === "new";
  const heading = newGame ? t("upload_new_game") : t("manage_game");
  const button_text = newGame ? t("upload_game") : t("update_game");

  return (
    <>
      <Space size="medium" />
      <H1>{heading}</H1>
      <Space size="medium" />

      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex w-full items-center gap-4">
          <Select data={game_types} />

          <FormTextInput
            placeholder={t("game_name")}
            control={control}
            name="name"
          />
        </div>

        <FormTextArea
          placeholder={t("game_description")}
          control={control}
          name="description"
        />

        <div className="flex w-full items-center gap-4">
          <UploadButton
            buttonText={t("choose_img")}
            placeholder={t("cover_image_file")}
          />
          <UploadButton
            buttonText={t("choose_file")}
            placeholder={t("your_game_file")}
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
