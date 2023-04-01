import React from "react";
import { MoonIcon, SunIcon } from "@heroicons/react/20/solid";
import { useTheme } from "@/context/themeContext";
import { cx } from "@/utils";

const ThemeSwitcher = ({
  className,
  ...rest
}: React.HTMLAttributes<HTMLDivElement>) => {
  const { theme, toggleTheme } = useTheme();

  return (
    <div className={cx("cursor-pointer", className)} {...rest}>
      {theme === "light" ? (
        <MoonIcon onClick={toggleTheme} className="h-6 w-6" />
      ) : (
        <SunIcon onClick={toggleTheme} className="h-6 w-6" />
      )}
    </div>
  );
};

export default ThemeSwitcher;
