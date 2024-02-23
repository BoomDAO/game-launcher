import React from "react";
import { useTranslation } from "react-i18next";
import { NavLink, useNavigate } from "react-router-dom";
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
import DialogProvider from "@/components/DialogProvider";
import { useGetUserProfileDetail } from "@/api/profile";
import Loader from "./ui/Loader";

const TopBar = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

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
      name: t("navigation.gaming_guilds"),
      path: navPaths.gaming_guilds
    }
  ];

  const dev_tools = [
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

  const [selectedOption, setSelectedOption] = React.useState<string | null>(null);
  const [isDropdownOpen, setIsDropdownOpen] = React.useState(false);

  const { data: userProfile, isLoading } = useGetUserProfileDetail();

  const handleOptionClickLoggedIn = () => {
    setIsDropdownOpen(false);
  };

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
                  <div className="hidden space-x-4 text-base uppercase md:flex">
                    {(session) ? (
                      paths.map(({ name, path }) => (
                        <NavLink
                          key={name}
                          className={({ isActive }) =>
                            isActive ? "gradient-text" : ""
                          }
                          to={path}
                          onClick={() => { setIsDropdownOpen(false); setSelectedOption("DEV TOOLS"); }}
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
                          onClick={() => { setIsOpenNavSidebar(true); setIsDropdownOpen(false); setSelectedOption("Dev Tools"); }}
                        >
                          {name}
                        </NavLink>
                      ))
                    )
                    }
                  </div>
                  <div
                    className="cursor-pointer relative"
                    onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                  >
                    {selectedOption || 'DEV TOOLS'}

                    {isDropdownOpen && (<dialog open className="whitespace-nowrap mt-5 dark:bg-white bg-black text-white dark:text-black" onMouseLeave={() => setIsDropdownOpen(false)}>
                      <div className="grid">
                        {(session) ? (dev_tools.map(({ name, path }) => (
                          <NavLink
                            key={name}
                            className="hover:gradient-text my-2"
                            to={path}
                            onClick={() => handleOptionClickLoggedIn}
                          >
                            {name}
                          </NavLink>
                        ))) :
                          (dev_tools.map(({ name, path }) => (
                            <NavLink
                              key={name}
                              to={path}
                              onClick={() => setIsOpenNavSidebar(true)}
                            >
                              {name}
                            </NavLink>
                          )))}
                      </div>
                    </dialog>)}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-4">
                  <div className="max-w-[240px] rounded-primary dark:border-gray-700 border-2 border-gray-300">
                    {(session == null) ? (
                      <Button
                        rightArrow
                        onClick={() => setIsOpenNavSidebar(true)}
                      >
                        {t("navigation.login")}
                      </Button>
                    ) : isLoading ? (
                      <Loader className="h-5 w-5"></Loader>
                    ) : (
                      <div
                        onClick={() => setIsOpenNavSidebar(true)}
                        className="cursor-pointer text-xs py-1 px-2"
                      >
                        <div className="flex">
                          <img src={userProfile?.image} className="w-10 rounded-3xl" />
                          <div className="pl-1 pt-1">
                            <p className="gradient-text font-semibold">{userProfile?.username}</p>
                            <div className="flex pt-1">
                              <img src="/xpicon.png" className="w-4" />
                              <p className="text-black dark:text-white">{userProfile?.xp}</p>
                            </div>
                          </div>
                        </div>
                      </div>
                    )
                    }
                  </div>
                </div>

                <ThemeSwitcher className="text-black dark:text-white" />

                <SideBar open={isOpenNavSidebar} setOpen={setIsOpenNavSidebar}>
                  <div className="w-full p-6 text-center">
                    {session ? (
                      <div>
                        <p className="font-semibold">Principal:</p>
                        <div>{session.address}</div>
                        <div className="space-y-4 mt-24 ml-24">
                          <Button size="big" onClick={() => { navigate((navPaths.profile_picture)); setIsOpenNavSidebar(false); }}>
                            {t("navigation.profile")}
                          </Button>
                          <Button size="big" onClick={() => { navigate((navPaths.wallet_tokens)); setIsOpenNavSidebar(false); window.location.reload(); }}>
                            {t("navigation.wallet")}
                          </Button>
                          <Button size="big" onClick={() => { logout(); navigate((navPaths.home)); }}>
                            {t("navigation.logout")}
                          </Button>
                        </div>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        <Button onClick={login} className="ml-28 mt-56">{t("navigation.login")}</Button>
                        <div className="space-y-1">
                          <p>Login to the Game Launcher to Curate, Play and Earn!</p>
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
