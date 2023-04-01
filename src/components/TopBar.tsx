import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink } from "react-router-dom";
import { Disclosure } from "@headlessui/react";
import { Bars3Icon, XMarkIcon } from "@heroicons/react/24/solid";
import { useScrollPosition } from "@todayweb/hooks";
import { useAuth } from "@/context/authContext";
import { useTheme } from "@/context/themeContext";
import { navPaths } from "@/shared";
import { cx } from "@/utils";
import SideBar from "./SideBar";
import ThemeSwitcher from "./ThemeSwitcher";
import Button from "./ui/Button";

const TopBar = () => {
  const [openSideBar, setOpenSideBar] = React.useState(false);
  const { t } = useTranslation();
  const { session, login, logout } = useAuth();
  const { theme } = useTheme();

  const scrollY = useScrollPosition();

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
    <Disclosure as="nav">
      {({ open }) => (
        <div
          className={cx(
            "fixed top-0 z-50 w-full transition-all duration-100 ease-in",
            (scrollY > 0 || open) && "bg-white shadow",
          )}
        >
          <div className="mx-auto w-full max-w-screen-xl px-8 py-4">
            <div className="flex items-center justify-between">
              <div className="relative mb-2 flex-shrink-0 cursor-pointer">
                <img src={`/logo-${theme}.png`} width={164} alt="logo" />
              </div>
              <div className="hidden sm:ml-6 md:block">
                <div className="flex items-center gap-6">
                  <div className="hidden space-x-4 text-sm uppercase md:flex">
                    {paths.map(({ name, path }) => (
                      <NavLink
                        key={name}
                        className={({ isActive }) =>
                          isActive ? "gradient-text" : ""
                        }
                        to={path}
                      >
                        {name}
                      </NavLink>
                    ))}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-4">
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

                <ThemeSwitcher />

                <SideBar open={openSideBar} setOpen={setOpenSideBar}>
                  <div className="p-6">
                    {session ? (
                      <Button onClick={logout}>{t("navigation.logout")}</Button>
                    ) : (
                      <Button onClick={login}>{t("navigation.login")}</Button>
                    )}
                  </div>
                </SideBar>

                <div className="-mr-2 flex gap-4 md:hidden">
                  <Disclosure.Button className="inline-flex items-center justify-center rounded-md p-2 text-gray-600 focus:outline-none focus:ring-0">
                    <span className="sr-only">Open main menu</span>
                    {open ? (
                      <XMarkIcon className="block h-6 w-6" aria-hidden="true" />
                    ) : (
                      <Bars3Icon className="block h-6 w-6" aria-hidden="true" />
                    )}
                  </Disclosure.Button>
                </div>
              </div>
            </div>
          </div>

          <Disclosure.Panel className="w-full max-w-screen-xl px-8 py-2 md:hidden">
            <div className="flex flex-col space-y-2 pt-2 pb-3 text-lg">
              {paths.map(({ name, path }) => (
                <Disclosure.Button key={name} as={"div"}>
                  <NavLink
                    key={name}
                    className={({ isActive }) =>
                      isActive ? "gradient-text" : ""
                    }
                    to={path}
                  >
                    {name}
                  </NavLink>
                </Disclosure.Button>
              ))}
            </div>
          </Disclosure.Panel>
        </div>
      )}
    </Disclosure>

    //   <img src={`/logo-${theme}.png`} width={164} alt="logo" />

    //   {session && <Navigation />}

    //   <div className="flex items-center gap-4">
    //     <ThemeSwitcher />

    //     <div className="max-w-[120px]">
    //       {session ? (
    //         <div
    //           onClick={() => setOpenSideBar(true)}
    //           className="gradient-text cursor-pointer"
    //         >{`${principal}...`}</div>
    //       ) : (
    //         <Button rightArrow onClick={() => setOpenSideBar(true)}>
    //           {t("navigation.login")}
    //         </Button>
    //       )}
    //     </div>
    //   </div>

    //   <SideBar open={openSideBar} setOpen={setOpenSideBar}>
    //     <div className="p-6">
    //       {session ? (
    //         <Button onClick={logout}>{t("navigation.logout")}</Button>
    //       ) : (
    //         <Button onClick={login}>{t("navigation.login")}</Button>
    //       )}
    //     </div>
    //   </SideBar>
    // </div>
  );
};

export default TopBar;
