import { useTranslation } from "react-i18next";
import { useAuth } from "@/context/authContext";
import Button from "./ui/Button";

const LoginButton = () => {
  const { t } = useTranslation();
  const { login } = useAuth();

  return <Button onClick={login}>{t("button_login")}</Button>;
};

export default LoginButton;
