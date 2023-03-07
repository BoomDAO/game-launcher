import React from "react";

export const useDarkMode = () => {
  const [theme, setTheme] = React.useState("");

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

  return { theme, toggleTheme };
};
