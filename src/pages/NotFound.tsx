import { useTranslation } from "react-i18next";
import { NavLink } from "react-router-dom";
import Button from "@/components/Button";

const NotFound = () => {
  const { t } = useTranslation();

  return (
    <div className="text-center">
      <p className="gradient-text text-3xl font-semibold">404</p>
      <h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-5xl">
        {t("404.heading")}
      </h1>
      <p className="mt-6 leading-7">{t("404.message")}</p>
      <div className="mt-10 flex items-center justify-center">
        <NavLink to="/">
          <Button>{t("404.home_button")}</Button>
        </NavLink>
      </div>
    </div>
  );
};

export default NotFound;
