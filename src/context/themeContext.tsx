import React from "react";

type Theme = "light" | "dark";

interface ThemeContext {
  theme: Theme;
  toggleTheme: () => void;
}

export const ThemeContext = React.createContext({} as ThemeContext);

export const ThemeContextProvider = ({ children }: React.PropsWithChildren) => {
  const [theme, setTheme] = React.useState<Theme>("light");

  React.useEffect(() => {
    const theme = JSON.parse(localStorage.getItem("theme")!);
    // if not theme and user OS is dark mode
    if (
      (!theme && window.matchMedia("(prefers-color-scheme: dark)").matches) ||
      theme === "dark"
    ) {
      setTheme("dark");
      document.documentElement.classList.add("dark");
    } else {
      setTheme("light");
      document.documentElement.classList.remove("dark");
    }
  }, [theme]);

  const toggleTheme = () => {
    if (theme === "light") {
      // when theme is changed, set the localStorage
      localStorage.setItem("theme", JSON.stringify("dark"));
      setTheme("dark");
      document.documentElement.classList.add("dark");
    } else {
      // when theme is changed, set the localStorage
      localStorage.setItem("theme", JSON.stringify("light"));
      setTheme("light");
      document.documentElement.classList.remove("dark");
    }
  };

  const value = {
    theme,
    toggleTheme,
  };

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  );
};

export const useTheme = () => React.useContext(ThemeContext);
