/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        blacktext: "#090909",
        white: "#ffffff",
        leftGradient: "#FEA002",
        rightGradient: "#E73BCF",
        light: "#F6F6F6",
        dark: "#33343F",
      },
      fontFamily: {
        poppins: ["Poppins", "sans-serif"],
      },
    },
  },
  plugins: [],
};
