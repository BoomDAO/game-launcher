import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAddController, useRemoveController } from "@/api/world_deployer";
import Form from "@/components/form/Form";
import FormTextInput from "@/components/form/FormTextInput";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  principal: z.string().min(1, "Principal is required."),
});

type Data = z.infer<typeof scheme>;

const ManageController = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const {
    control: addControllerControl,
    handleSubmit: handleAddController,
    reset: resetAdd,
  } = useForm<Data>({
    defaultValues: {
      principal: "",
    },
    resolver: zodResolver(scheme),
  });

  const {
    control: removeControllerControll,
    handleSubmit: handleRemoveController,
    reset: resetRemove,
  } = useForm<Data>({
    defaultValues: {
      principal: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate: addController, isLoading: isLoadingAddController } =
    useAddController();
  const { mutate: removeController, isLoading: isLoadingRemoveController } =
    useRemoveController();

  const onAddController = (values: Data) =>
    addController(
      { ...values, canisterId },
      {
        onSuccess: () => resetAdd(),
      },
    );
  const onRemoveController = (values: Data) =>
    removeController(
      { ...values, canisterId },
      {
        onSuccess: () => resetRemove(),
      },
    );

  return (
    <div>
      <SubHeading>{t("world_deployer.controller.title")}</SubHeading>
      <Space />

      <div className="flex w-full flex-col gap-12 md:flex-row">
        <Form onSubmit={handleAddController(onAddController)}>
          <FormTextInput
            control={addControllerControl}
            name="principal"
            placeholder={t(
              "world_deployer.controller.add.input_placeholder",
            )}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoadingAddController}>
            {t("world_deployer.controller.add.button")}
          </Button>
        </Form>

        <Form onSubmit={handleRemoveController(onRemoveController)}>
          <FormTextInput
            control={removeControllerControll}
            name="principal"
            placeholder={t(
              "world_deployer.controller.remove.input_placeholder",
            )}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoadingRemoveController}>
            {t("world_deployer.controller.remove.button")}
          </Button>
        </Form>
      </div>
    </div>
  );
};

export default ManageController;
