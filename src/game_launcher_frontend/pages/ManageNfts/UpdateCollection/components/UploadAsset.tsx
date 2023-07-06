import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMint, useAssetUpload } from "@/api/minting_deployer";
import Form from "@/components/form/Form";
import FormCheckbox from "@/components/form/FormCheckbox";
import FormNumberInput from "@/components/form/FormNumberInput";
import FormTextArea from "@/components/form/FormTextArea";
import FormTextInput from "@/components/form/FormTextInput";
import FormUploadButton from "@/components/form/FormUploadButton";
import Button from "@/components/ui/Button";
import Space from "@/components/ui/Space";
import SubHeading from "@/components/ui/SubHeading";
import Divider from "@/components/ui/Divider";

const scheme = z.object({
    nft: z.string().min(1, "Image is required."),
    assetId: z.string().min(1, "Asset Id is required."),
});

type Data = z.infer<typeof scheme>;

const UploadAsset = () => {
    const { canisterId } = useParams();

    const { t } = useTranslation();

    const { control, handleSubmit, watch, reset } = useForm<Data>({
        defaultValues: {
            nft: "",
            assetId: "",
        },
        resolver: zodResolver(scheme),
    });

    const nft = watch("nft");

    const { mutate, isLoading } = useAssetUpload();

    const onSubmit = (values: Data) =>
        mutate(
            { ...values, canisterId },
            {
                onSuccess: () => reset(),
            },
        );

    return (
        <div>
            <SubHeading>{t("manage_nfts.update.assets.upload.title")}</SubHeading>
            <Space />
            <Form onSubmit={handleSubmit(onSubmit)}>
                <div className="flex flex-col gap-6 md:flex-row">
                    <FormTextInput
                        control={control}
                        name="assetId"
                        placeholder={t(
                            "manage_nfts.update.assets.upload.assetId_input_placeholder",
                        )}
                        hint={{
                            body: t("manage_nfts.update.assets.upload.assetId_input_helper"),
                        }}
                    />
                    <FormUploadButton
                        buttonText={t("manage_nfts.update.assets.upload.upload_button")}
                        placeholder={t("manage_nfts.update.assets.upload.upload_placeholder")}
                        control={control}
                        name="nft"
                        hint={{
                            body: t("manage_nfts.update.assets.upload.input_helper_upload_asset"),
                        }}
                    />
                    {nft && <img src={nft} alt="cover" className="h-full w-[200px]" />}
                </div>

                <Button size="big" rightArrow isLoading={isLoading}>
                    {t("manage_nfts.update.assets.upload.button")}
                </Button>
            </Form>
        </div>
    );
};

export default UploadAsset;
