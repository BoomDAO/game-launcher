import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAddAdmin, useAddTrustedOrigin, useRemoveAdmin, useRemoveTrustedOrigin } from "@/api/world_deployer";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  url: z.string().min(1, "Url is required."),
});

type Data = z.infer<typeof scheme>;

const TrustedOrigins = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const {
    control: addUrlControl,
    handleSubmit: handleAddUrl,
    reset: resetAdd,
  } = useForm<Data>({
    defaultValues: {
      url: "",
    },
    resolver: zodResolver(scheme),
  });

  const {
    control: removeUrlControll,
    handleSubmit: handleRemoveUrl,
    reset: resetRemove,
  } = useForm<Data>({
    defaultValues: {
      url: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate: addUrl, isLoading: isLoadingAddUrl } = useAddTrustedOrigin();
  const { mutate: removeUrl, isLoading: isLoadingRemoveUrl } =
    useRemoveTrustedOrigin();

  const onAddUrl = (values: Data) =>
    addUrl(
      { ...values, canisterId },
      {
        onSuccess: () => resetAdd(),
      },
    );

  const onRemoveUrl = (values: Data) =>
    removeUrl(
      { ...values, canisterId },
      {
        onSuccess: () => resetRemove(),
      },
    );

  return (
    <div>
      <SubHeading>{t("world_deployer.manage_worlds.tabs.item_4.manage.title")}</SubHeading>
      <Space />

      <div className="flex w-full flex-col gap-12 md:flex-row">
        <Form onSubmit={handleAddUrl(onAddUrl)}>
          <FormTextInput
            control={addUrlControl}
            name="url"
            placeholder={t("world_deployer.manage_worlds.tabs.item_4.manage.add_placeholder")}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoadingAddUrl}>
            {t("world_deployer.manage_worlds.tabs.item_4.manage.add_button")}
          </Button>
        </Form>

        <Form onSubmit={handleRemoveUrl(onRemoveUrl)}>
          <FormTextInput
            control={removeUrlControll}
            name="url"
            placeholder={t("world_deployer.manage_worlds.tabs.item_4.manage.remove_placeholder")}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoadingRemoveUrl}>
            {t("world_deployer.manage_worlds.tabs.item_4.manage.remove_button")}
          </Button>
        </Form>
      </div>
    </div>
  );
};

export default TrustedOrigins;
