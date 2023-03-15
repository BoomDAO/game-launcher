import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink } from "react-router-dom";
import { useAuth } from "@/context/authContext";
import { useTheme } from "@/context/themeContext";
import Button from "./Button";
import SideBar from "./SideBar";
import ThemeSwitcher from "./ThemeSwitcher";

const Navigation = () => {
  const [openSideBar, setOpenSideBar] = React.useState(false);
  const { t } = useTranslation();
  const { session } = useAuth();
  const { theme } = useTheme();

  const principal = "r44we3-pqaasd-asfasfa-asfasf-safas".slice(0, 10);

  const paths = [
    {
      name: t("browse_games"),
      path: "/",
    },
    {
      name: t("upload_games"),
      path: "/upload-games",
    },
    {
      name: t("manage_NFTs"),
      path: "/manage-nfts",
    },
    {
      name: t("manage_payments"),
      path: "/manage-payments",
    },
  ];

  console.log("theme", theme);

  return (
    <div className="flex items-center justify-between pb-8">
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
              {t("login")}
            </Button>
          )}
        </div>
      </div>

      <SideBar open={openSideBar} setOpen={setOpenSideBar}></SideBar>
    </div>
  );
};

export default Navigation;
