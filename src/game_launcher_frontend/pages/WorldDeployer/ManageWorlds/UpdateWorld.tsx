import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useCreateWorldData,
  useCreateWorldUpload,
  useUpdateWorldDetails,
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
import SubHeading from "@/components/ui/SubHeading";
import { useParams } from "react-router-dom";

const scheme = z
  .object({
    cover: z.string().min(1, { message: "Cover image is required." })
  })
  .extend(worldDataScheme);

type Data = z.infer<typeof scheme>;

const UpdateWorld = () => {
  const { canisterId } = useParams();
  const { t } = useTranslation();

  const { control, handleSubmit, watch } = useForm<Data>({
    defaultValues: {
      name: "",
      cover: "",
    },
    resolver: zodResolver(scheme),
  });

  const cover = watch("cover");

  const { mutate: details, isLoading: isLoading } = useUpdateWorldDetails();

  const onSubmit = (values: Data) =>
    details(
      { name: values.name, canisterId: canisterId, cover: values.cover },
      {
        onSuccess: () => {
        },
      },
    );

  return (
    <>
      <SubHeading>{t("world_deployer.manage_worlds.tabs.item_5.subtitle")}</SubHeading>
      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex w-full flex-col gap-4 md:flex-row">
          <FormTextInput
            placeholder={t("world_deployer.create_world.input_name")}
            control={control}
            name="name"
          />
          <div className="flex w-full flex-col gap-6">
            <FormUploadButton
              buttonText={t("world_deployer.create_world.button_cover_upload")}
              placeholder={t("world_deployer.create_world.placeholder_cover_upload")}
              control={control}
              name="cover"
            />
            {cover && <img src={cover} alt="cover" className="w-full" />}
          </div>
        </div>

        <Button
          rightArrow
          isLoading={isLoading}
          size="big"
        >
          {t("world_deployer.manage_worlds.tabs.item_5.button_placeholder")}
        </Button>
      </Form>
    </>
  );
};

export default UpdateWorld;
