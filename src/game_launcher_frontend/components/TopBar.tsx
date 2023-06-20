import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink } from "react-router-dom";
import { Disclosure } from "@headlessui/react";
import { Bars3Icon, XMarkIcon } from "@heroicons/react/24/solid";
import { useScrollPosition } from "@todayweb/hooks";
import { useAuthContext } from "@/context/authContext";
import { useGlobalContext } from "@/context/globalContext";
import { useThemeContext } from "@/context/themeContext";
import { navPaths } from "@/shared";
import { cx } from "@/utils";
import SideBar from "./SideBar";
import ThemeSwitcher from "./ThemeSwitcher";
import Button from "./ui/Button";

const TopBar = () => {
  const { t } = useTranslation();

  const { isOpenNavSidebar, setIsOpenNavSidebar } = useGlobalContext();
  const { session, login, logout } = useAuthContext();
  const { theme } = useThemeContext();

  const scrollY = useScrollPosition();

  const openOrNotTop = (open: boolean) => scrollY > 0 || open;

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
      name: t("navigation.world_deployer"),
      path: navPaths.world_deployer
    },
    {
      name: t("navigation.manage_NFTs"),
      path: navPaths.manage_nfts,
    },
    {
      name: t("navigation.token_deployer"),
      path: navPaths.token_deployer,
    }
  ];

  return (
    <Disclosure as="nav">
      {({ open, close }) => (
        <div
          className={cx(
            "fixed top-0 z-50 w-full",
            openOrNotTop(open) &&
            "bg-white bg-opacity-95 shadow-sm dark:bg-dark dark:bg-opacity-95",
          )}
        >
          <div className="mx-auto w-full max-w-screen-xl px-8 py-4">
            <div className="flex items-center justify-between">
              <div className="relative mb-2 flex-shrink-0">
                <img
                  src={`/logo-${theme}.svg`}
                  width={164}
                  alt="logo"
                  className="hidden md:flex"
                />
                <img
                  src={`/logo.svg`}
                  width={42}
                  alt="logo"
                  className="md:hidden"
                />
              </div>
              <div className="hidden sm:ml-6 md:block">
                <div className="flex items-center gap-6">
                  <div className="hidden space-x-4 text-sm uppercase md:flex">
                    {(session) ? (
                      paths.map(({ name, path }) => (
                        <NavLink
                          key={name}
                          className={({ isActive }) =>
                            isActive ? "gradient-text" : ""
                          }
                          to={path}
                        >
                          {name}
                        </NavLink>
                      ))
                    ) : (
                      paths.map(({ name, path }) => (
                        <NavLink
                          key={name}
                          className={({ isActive }) =>
                            isActive ? "gradient-text" : ""
                          }
                          to={path}
                          onClick={() => setIsOpenNavSidebar(true)}
                        >
                          {name}
                        </NavLink>
                      ))
                    )
                    }
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-4">
                  <div className="max-w-[120px]">
                    {session ? (
                      <div
                        onClick={() => setIsOpenNavSidebar(true)}
                        className="gradient-text cursor-pointer"
                      >{`${principal}...`}</div>
                    ) : (
                      <Button
                        rightArrow
                        onClick={() => setIsOpenNavSidebar(true)}
                      >
                        {t("navigation.login")}
                      </Button>
                    )}
                  </div>
                </div>

                <ThemeSwitcher className="text-black dark:text-white" />

                <SideBar open={isOpenNavSidebar} setOpen={setIsOpenNavSidebar}>
                  <div className="p-6">
                    {session ? (
                      <div className="space-y-4">
                        <Button onClick={logout}>
                          {t("navigation.logout")}
                        </Button>
                        <div className="space-y-1">
                          <p className="font-semibold">Principal:</p>
                          <div>{session.address}</div>
                        </div>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        <Button onClick={login}>{t("navigation.login")}</Button>
                        <div className="space-y-1">
                          <p>Login to upload and manage games.</p>
                        </div>
                      </div>
                    )}
                  </div>
                </SideBar>

                {session && (
                  <div className="-mr-2 flex gap-4 md:hidden">
                    <Disclosure.Button
                      className={cx(
                        "inline-flex items-center justify-center rounded-md p-2 text-black focus:outline-none focus:ring-0",
                        "text-black dark:text-white",
                      )}
                    >
                      <span className="sr-only">Open main menu</span>
                      {open ? (
                        <XMarkIcon
                          className="block h-6 w-6"
                          aria-hidden="true"
                        />
                      ) : (
                        <Bars3Icon
                          className="block h-6 w-6"
                          aria-hidden="true"
                        />
                      )}
                    </Disclosure.Button>
                  </div>
                )}
              </div>
            </div>
          </div>

          <Disclosure.Panel className="w-full max-w-screen-xl px-8 py-2 md:hidden">
            <div className="flex flex-col space-y-2 pt-2 pb-3 text-lg">
              {session &&
                paths.map(({ name, path }) => (
                  <Disclosure.Button key={name} as={"div"}>
                    <NavLink
                      key={name}
                      className={({ isActive }) =>
                        isActive
                          ? "gradient-text"
                          : "text-black dark:text-white"
                      }
                      to={path}
                      onClick={() => close()}
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
  );
};

export default TopBar;
