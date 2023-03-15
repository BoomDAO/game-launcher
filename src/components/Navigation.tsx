import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink } from "react-router-dom";
import { useAuth } from "@/context/authContext";
import Button from "./Button";
import SideBar from "./SideBar";

const Navigation = () => {
  const [openSideBar, setOpenSideBar] = React.useState(false);
  const { t } = useTranslation();
  const { session } = useAuth();

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

  return (
    <div className="flex items-center justify-between">
      <img src="/logo.png" width={164} alt="logo" />

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

      <SideBar open={openSideBar} setOpen={setOpenSideBar}></SideBar>
    </div>
  );
};

export default Navigation;
