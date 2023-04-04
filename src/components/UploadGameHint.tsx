import { useTranslation } from "react-i18next";

const UploadGameHint = () => {
  const { t } = useTranslation();

  return (
    <div className="space-y-4">
      <div>
        <h6 className="text-lg font-semibold">
          {t("upload_games.hint.browser.title")}
        </h6>
        <ul className="my-1 space-y-4">
          <li>{t("upload_games.hint.browser.list_item_1")}</li>
          <li>{t("upload_games.hint.browser.list_item_2")}</li>
          <li>{t("upload_games.hint.browser.list_item_3")}</li>
        </ul>
      </div>

      <div>
        <h6 className="text-lg font-semibold">
          {t("upload_games.hint.mobile_pc.title")}
        </h6>
        <p className="mt-1">{t("upload_games.hint.mobile_pc.text")}</p>
      </div>
    </div>
  );
};

export default UploadGameHint;
