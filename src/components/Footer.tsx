import { useTranslation } from "react-i18next";
import Divider from "./ui/Divider";

const Footer = () => {
  const { t } = useTranslation();

  return (
    <>
      <Divider className="mb-6" />
      <div className="flex justify-between">
        <p>{t("footer.copyright")}</p>
        <div className="flex items-center gap-4">
          <p className="gradient-text text-lg font-semibold">
            {t("footer.follow")}:
          </p>
          <div className="flex gap-3">
            <img src="/twitter.svg" alt="twitter" className="cursor-pointer" />
            <img src="/medium.svg" alt="medium" className="cursor-pointer" />
          </div>
        </div>
      </div>
    </>
  );
};

export default Footer;
