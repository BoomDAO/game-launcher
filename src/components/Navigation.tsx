import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink } from "react-router-dom";
import { useAuth } from "@/context/authContext";
import { useTheme } from "@/context/themeContext";
import { navPaths } from "@/shared";
import SideBar from "./SideBar";
import ThemeSwitcher from "./ThemeSwitcher";
import Button from "./ui/Button";

const Navigation = () => {
  const [openSideBar, setOpenSideBar] = React.useState(false);
  const { t } = useTranslation();
  const { session, login, logout } = useAuth();
  const { theme } = useTheme();

  const principal = session?.address?.slice(0, 10);

  const paths = [
    {
      name: t("navigation.browse_games"),
      path: navPaths.home,
    },
    {
      name: t("navigation.upload_games"),
      path: navPaths.upload_games,
    },
    {
      name: t("navigation.manage_NFTs"),
      path: navPaths.manage_nfts,
    },
    {
      name: t("navigation.manage_payments"),
      path: navPaths.manage_payments,
    },
  ];

  return (
    <div className="flex items-center justify-between">
      <img src={`/logo-${theme}.png`} width={164} alt="logo" />

      {session && (
        <nav className="space-x-4 text-sm uppercase">
          {paths.map(({ name, path }) => (
            <NavLink
              key={name}
              className={({ isActive }) => (isActive ? "gradient-text" : "")}
              to={path}
            >
              {name}
            </NavLink>
          ))}
        </nav>
      )}

      <div className="flex items-center gap-4">
        <ThemeSwitcher />

        <div className="max-w-[120px]">
          {session ? (
            <div
              onClick={() => setOpenSideBar(true)}
              className="gradient-text cursor-pointer"
            >{`${principal}...`}</div>
          ) : (
            <Button rightArrow onClick={() => setOpenSideBar(true)}>
              {t("navigation.login")}
            </Button>
          )}
        </div>
      </div>

      <SideBar open={openSideBar} setOpen={setOpenSideBar}>
        <div className="p-6">
          {session ? (
            <Button onClick={logout}>{t("navigation.logout")}</Button>
          ) : (
            <Button onClick={login}>{t("navigation.login")}</Button>
          )}
        </div>
      </SideBar>
    </div>
  );
};

export default Navigation;
