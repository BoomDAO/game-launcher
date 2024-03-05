import { useTranslation } from "react-i18next";
import Divider from "./ui/Divider";

const Footer = () => {
  const { t } = useTranslation();

  return (
    <>
      <Divider className="mb-6" />
      <div className="flex flex-col-reverse justify-between gap-2 text-sm md:flex-row">
        <p>{t("footer.copyright")}</p>
        <div className="flex items-center gap-4">
          <p className="gradient-text text-lg font-semibold">
            {t("footer.follow")}:
          </p>
          <div className="flex gap-3">
            <a href="https://twitter.com/boomdaosns" target="_blank">
              <img
                src="/twitter.svg"
                alt="twitter"
                className="cursor-pointer"
              />
            </a>
            <a href="https://github.com/BoomDAO" target="_blank">
              <img style={{ width: 24 }} src="/github.svg" alt="medium" className="cursor-pointer" />
            </a>
            <a href="https://discord.com/invite/fPVqZkQ6x2" target="_blank">
              <img style={{ width: 24 }} src="/discord.svg" alt="medium" className="cursor-pointer" />
            </a>
          </div>
        </div>
      </div>
    </>
  );
};

export default Footer;
