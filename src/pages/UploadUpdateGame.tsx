import React from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import Form from "@/components/Form";
import H1 from "@/components/H1";
import Input from "@/components/Input";
import Space from "@/components/Space";
import TextArea from "@/components/TextArea";

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
      </Form>
    </div>
  );
};

export default UploadUpdateGame;
