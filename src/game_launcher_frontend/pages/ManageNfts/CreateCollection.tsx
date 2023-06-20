import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useCreateCollection } from "@/api/minting_deployer";
import Form from "@/components/form/Form";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Space from "@/components/ui/Space";

const scheme = z.object({
  name: z.string().min(1, { message: "Name is required." }),
  description: z.string().min(1, { message: "Description is required." }),
});

type Data = z.infer<typeof scheme>;

const CreateCollection = () => {
  const { t } = useTranslation();

  const { control, handleSubmit } = useForm<Data>({
    defaultValues: {
      name: "",
      description: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate, isLoading } = useCreateCollection();

  const onSubmit = (values: Data) => mutate(values);

  return (
    <>
      <Space size="medium" />
      <H1>{t("manage_nfts.create.title")}</H1>
      <Space size="medium" />

      <Form onSubmit={handleSubmit(onSubmit)}>
        <FormTextInput
          placeholder={t("manage_nfts.input_name")}
          control={control}
          name="name"
        />

        <FormTextArea
          placeholder={t("manage_nfts.input_description")}
          control={control}
          name="description"
        />

        <Button rightArrow size="big" isLoading={isLoading}>
          {t("manage_nfts.create.button")}
        </Button>
      </Form>
    </>
  );
};

export default CreateCollection;
