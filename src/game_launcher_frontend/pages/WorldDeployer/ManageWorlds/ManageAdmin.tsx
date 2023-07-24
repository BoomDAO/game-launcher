import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAddAdmin, useRemoveAdmin } from "@/api/world_deployer";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  principal: z.string().min(1, "Principal is required."),
});

type Data = z.infer<typeof scheme>;

const ManageAdmin = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const {
    control: addAdminControl,
    handleSubmit: handleAddAdmin,
    reset: resetAdd,
  } = useForm<Data>({
    defaultValues: {
      principal: "",
    },
    resolver: zodResolver(scheme),
  });

  const {
    control: removeAdminControll,
    handleSubmit: handleRemoveAdmin,
    reset: resetRemove,
  } = useForm<Data>({
    defaultValues: {
      principal: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate: addAdmin, isLoading: isLoadingAddAdmin } = useAddAdmin();
  const { mutate: removeAdmin, isLoading: isLoadingRemoveAdmin } =
    useRemoveAdmin();

  const onAddAdmin = (values: Data) =>
    addAdmin(
      { ...values, canisterId },
      {
        onSuccess: () => resetAdd(),
      },
    );

  const onRemoveAdmin = (values: Data) =>
    removeAdmin(
      { ...values, canisterId },
      {
        onSuccess: () => resetRemove(),
      },
    );

  return (
    <div>
      <SubHeading>{t("world_deployer.admin.title")}</SubHeading>
      <Space />

      <div className="flex w-full flex-col gap-12 md:flex-row">
        <Form onSubmit={handleAddAdmin(onAddAdmin)}>
          <FormTextInput
            control={addAdminControl}
            name="principal"
            placeholder={t("world_deployer.admin.add.input_placeholder")}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoadingAddAdmin}>
            {t("world_deployer.admin.add.button")}
          </Button>
        </Form>

        <Form onSubmit={handleRemoveAdmin(onRemoveAdmin)}>
          <FormTextInput
            control={removeAdminControll}
            name="principal"
            placeholder={t("world_deployer.admin.remove.input_placeholder")}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoadingRemoveAdmin}>
            {t("world_deployer.admin.remove.button")}
          </Button>
        </Form>
      </div>
    </div>
  );
};

export default ManageAdmin;
