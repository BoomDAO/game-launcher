import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";
import { useImportConfigsData, useImportUsersData } from "@/api/world_deployer";

const scheme = z.object({
  ofCanisterId: z.string().min(1, "Canister Id is required."),
});

type Data = z.infer<typeof scheme>;

const ImportUser = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const {
    control: addOfCanisterIdControl,
    handleSubmit: handleImportConfigs,
    reset: resetAdd,
  } = useForm<Data>({
    defaultValues: {
      ofCanisterId: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate: addOfCanisterId, isLoading: isLoadingOfCanisterId } = useImportConfigsData();

  const onImportConfigs = (values: Data) =>
    addOfCanisterId(
      { ...values, canisterId },
      {
        onSuccess: () => resetAdd(),
      },
    );

  return (
    <div>
      <SubHeading>{t("world_deployer.manage_worlds.tabs.item_2.import_config.title")}</SubHeading>
      <Space/>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <Form onSubmit={handleImportConfigs(onImportConfigs)}>
          <FormTextInput
            control={addOfCanisterIdControl}
            name="ofCanisterId"
            placeholder={t(
              "world_deployer.manage_worlds.tabs.item_2.import_config.input_placeholder",
            )}
            hint={{
              body: t("world_deployer.manage_worlds.tabs.item_2.import_config.title"),
            }}
          />

          <Button size="big" rightArrow isLoading={isLoadingOfCanisterId}>
            {t("world_deployer.manage_worlds.tabs.item_2.import_config.button_text")}
          </Button>
        </Form>
      </div>
    </div>
  );
};

export default ImportUser;
