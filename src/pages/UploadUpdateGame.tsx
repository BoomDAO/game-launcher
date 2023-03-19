import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Button from "@/components/Button";
import Form from "@/components/Form";
import H1 from "@/components/H1";
import Input from "@/components/Input";
import Space from "@/components/Space";
import TextArea from "@/components/TextArea";
import UploadButton from "@/components/UploadButton";

const UploadUpdateGame = () => {
  const { canisterId } = useParams();
  const { t } = useTranslation();

  const newGame = canisterId === "new";
  const heading = newGame ? t("upload_new_game") : t("manage_game");

  return (
    <div>
      <Space size="medium" />
      <H1>{heading}</H1>
      <Space size="medium" />

      <Form>
        <Input placeholder={t("game_name")} />
        <TextArea placeholder={t("game_description")} className="" />
        <div className="flex w-full items-center gap-4">
          <UploadButton
            buttonText={t("choose_img")}
            placeholder={t("cover_image_file")}
          />
          <UploadButton
            buttonText={t("choose_file")}
            placeholder={t("your_game_file")}
          />
        </div>

        <div>
          <Button rightArrow size="big" className="">
            {t("upload_game")}
          </Button>
        </div>
      </Form>
    </div>
  );
};

export default UploadUpdateGame;
