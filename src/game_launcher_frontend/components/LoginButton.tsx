import { useTranslation } from "react-i18next";
import { useAuthContext } from "@/context/authContext";
import Button from "./ui/Button";

const LoginButton = () => {
  const { t } = useTranslation();
  const { login } = useAuthContext();

  return <Button onClick={login}>{t("button_login")}</Button>;
};

export default LoginButton;
