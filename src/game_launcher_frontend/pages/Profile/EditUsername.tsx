import React from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import SubHeading from "@/components/ui/SubHeading";
import { useParams } from "react-router-dom";
import { useUpdateProfileUsername } from "@/api/profile";

const scheme = z
  .object({
    username: z.string().min(1, { message: "Username is required." })
  });

type Data = z.infer<typeof scheme>;

const EditUsername = () => {
  const { canisterId } = useParams();
  const { t } = useTranslation();

  const { control, handleSubmit } = useForm<Data>({
    defaultValues: {
      username: "",
    },
    resolver: zodResolver(scheme),
  });
  const { mutate: details, isLoading: isLoading } = useUpdateProfileUsername();

  const onSubmit = (values: Data) =>
    details(
      { username: values.username },
      {
        onSuccess: () => {
        },
      },
    );

  return (
    <>
      <SubHeading>{t("profile.edit.tab_2.subtitle")}</SubHeading>
      <Form onSubmit={handleSubmit(onSubmit)}>
        <div className="flex w-1/2 flex-col gap-4 md:flex-row">
          <div className="flex w-full flex-col gap-6">
            <FormTextInput
              placeholder={t("profile.edit.tab_2.input_placeholder")}
              control={control}
              name="username"
            />
          </div>
        </div>

        <Button
          rightArrow
          isLoading={isLoading}
          size="big"
        >
          {t("profile.edit.tab_2.update_button")}
        </Button>
      </Form>
    </>
  );
};

export default EditUsername;
