import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Button from "@/components/Button";
import Form from "@/components/Form";
import H1 from "@/components/H1";
import Input from "@/components/Input";
import Select, { SelectOption } from "@/components/Select";
import Space from "@/components/Space";
import TextArea from "@/components/TextArea";
import UploadButton from "@/components/UploadButton";

const game_types: SelectOption[] = [
  {
    label: "Browser",
    value: 1,
  },
  {
    label: "Android",
    value: 2,
  },
  {
    label: "Mac",
    value: 3,
  },
  {
    label: "PC",
    value: 4,
  },
];

const UploadUpdateGame = () => {
  const { canisterId } = useParams();
  const { t } = useTranslation();

  const newGame = canisterId === "new";
  const heading = newGame ? t("upload_new_game") : t("manage_game");
  const button_text = newGame ? t("upload_game") : t("update_game");

  return (
    <>
      <Space size="medium" />
      <H1>{heading}</H1>
      <Space size="medium" />

      <Form>
        <div className="flex w-full items-center gap-4">
          <Select data={game_types} />
          <Input placeholder={t("game_name")} />
        </div>
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
            {button_text}
          </Button>
        </div>
      </Form>
    </>
  );
};

export default UploadUpdateGame;
