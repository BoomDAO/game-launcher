import { MoonIcon, SunIcon } from "@heroicons/react/20/solid";
import { useTheme } from "@/context/themeContext";

const ThemeSwitcher = () => {
  const { theme, toggleTheme } = useTheme();

  return (
    <div className="cursor-pointer">
      {theme === "light" ? (
        <MoonIcon onClick={toggleTheme} className="h-6 w-6" />
      ) : (
        <SunIcon onClick={toggleTheme} className="h-6 w-6" />
      )}
    </div>
  );
};

export default ThemeSwitcher;
