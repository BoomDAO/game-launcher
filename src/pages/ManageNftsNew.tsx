import { useTranslation } from "react-i18next";
import Form from "@/components/form/Form";
import Button from "@/components/ui/Button";
import H1 from "@/components/ui/H1";
import Input from "@/components/ui/Input";
import Space from "@/components/ui/Space";
import TextArea from "@/components/ui/TextArea";
import UploadButton from "@/components/ui/UploadButton";

const ManageNftsNew = () => {
  const { t } = useTranslation();

  return (
    <>
      <Space size="medium" />
      <H1>{t("manage_nfts.title")}</H1>
      <Space size="medium" />

      <Form>
        <div className="flex w-full items-center gap-4">
          <Input placeholder={t("manage_nfts.input_name")} />
          <UploadButton
            buttonText={t("manage_nfts.button_cover_upload")}
            placeholder={t("manage_nfts.placeholder_cover_upload")}
          />
        </div>
        <TextArea
          placeholder={t("manage_nfts.input_description")}
          className=""
        />

        <div>
          <Button rightArrow size="big" className="">
            {t("manage_nfts.new.button")}
          </Button>
        </div>
      </Form>
    </>
  );
};

export default ManageNftsNew;
