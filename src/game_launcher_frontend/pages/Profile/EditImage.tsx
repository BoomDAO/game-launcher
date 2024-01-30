import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import Form from "@/components/form/Form";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import SubHeading from "@/components/ui/SubHeading";
import { useParams } from "react-router-dom";
import { useUpdateProfileImage } from "@/api/profile";

const scheme = z
  .object({
    image: z.string().min(1, { message: "Image is required." })
  });

type Data = z.infer<typeof scheme>;

const EditImage = () => {
  const { canisterId } = useParams();
  const { t } = useTranslation();

  const { control, handleSubmit, watch } = useForm<Data>({
    defaultValues: {
      image: "",
    },
    resolver: zodResolver(scheme),
  });
  const image = watch("image");
  const { mutate: details, isLoading: isLoading } = useUpdateProfileImage();

  const onSubmit = (values: Data) =>
    details(
      { image: values.image },
      {
        onSuccess: () => {
        },
      },
    );

  return (
    <>
      <SubHeading>{t("profile.edit.tab_1.subtitle")}</SubHeading>
      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex w-1/2 flex-col gap-4 md:flex-row">
          <div className="flex w-full flex-col gap-6">
            <FormUploadButton
              buttonText={t("profile.edit.tab_1.select_button")}
              placeholder={t("profile.edit.tab_1.input_placeholder")}
              control={control}
              name="image"
            />
            {image && <img src={image} alt="image" className="w-full" />}
          </div>
        </div>

        <Button
          rightArrow
          isLoading={isLoading}
          size="big"
        >
          {t("profile.edit.tab_1.upload_button")}
        </Button>
      </Form>
    </>
  );
};

export default EditImage;
