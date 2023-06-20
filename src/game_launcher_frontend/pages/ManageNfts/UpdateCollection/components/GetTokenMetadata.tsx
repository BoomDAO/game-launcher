import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useGetTokenMetadata } from "@/api/minting_deployer";
import { ErrorResult } from "@/components/Results";
import Form from "@/components/form/Form";
import FormNumberInput from "@/components/form/FormNumberInput";
import Box from "@/components/ui/Box";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";

const scheme = z.object({
  index: z.string().min(1, "Index is required."),
});

type Data = z.infer<typeof scheme>;

const GetTokenMetadata = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { control, handleSubmit } = useForm<Data>({
    defaultValues: {
      index: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate, data, isLoading, isError } = useGetTokenMetadata();

  const onSubmit = (values: Data) => mutate({ ...values, canisterId });

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.view.token.title")}</SubHeading>
      <Space />

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <Form onSubmit={handleSubmit(onSubmit)}>
          <FormNumberInput
            control={control}
            name="index"
            placeholder={t("manage_nfts.update.view.token.input_placeholder")}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoading}>
            {t("manage_nfts.update.view.token.button")}
          </Button>
        </Form>

        {data?.metadata === "" || isError ? (
          <ErrorResult>{t("manage_nfts.update.view.token.error")}</ErrorResult>
        ) : (
          <div className="flex flex-col gap-4">
            {data?.metadata && <Box>{data.metadata}</Box>}

            {data?.tokenUrl && (
              <img
                src={data.tokenUrl}
                width={200}
                height={200}
                className="object-contain"
              />
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default GetTokenMetadata;
