import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useGetAssetEncoding} from "@/api/minting_deployer";
import { ErrorResult } from "@/components/Results";
import Form from "@/components/form/Form";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";
import FormTextInput from "@/components/form/FormTextInput";

const scheme = z.object({
  assetId: z.string().min(1, "Asset Id is required."),
});

type Data = z.infer<typeof scheme>;

const ViewAsset = () => {
  const { canisterId } = useParams();

  const { t } = useTranslation();

  const { control, handleSubmit } = useForm<Data>({
    defaultValues: {
      assetId: "",
    },
    resolver: zodResolver(scheme),
  });

  const { mutate, data, isLoading, isError } = useGetAssetEncoding();

  const onSubmit = (values: Data) => mutate({ ...values, canisterId });

  return (
    <div>
      <SubHeading>{t("manage_nfts.update.assets.asset.title")}</SubHeading>
      <Space />

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <Form onSubmit={handleSubmit(onSubmit)}>
          <FormTextInput
            control={control}
            name="assetId"
            placeholder={t("manage_nfts.update.assets.asset.input_placeholder")}
            min={0}
          />

          <Button size="big" rightArrow isLoading={isLoading}>
            {t("manage_nfts.update.assets.asset.button")}
          </Button>
        </Form>

        {data === "" || isError ? (
          <ErrorResult>{t("manage_nfts.update.assets.asset.error")}</ErrorResult>
        ) : (
          <div className="flex flex-col gap-4 border-none">
            {(data != "" && isLoading == false)?(
              <img
                src={data}
                width={200}
                height={200}
                className="object-contain border-none"
              />
            ) : (<></>)}
          </div>
        )}
      </div>
    </div>
  );
};

export default ViewAsset;
