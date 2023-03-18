/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        black: "#090909",
        white: "#F6F6F6",
        leftGradient: "#FEA002",
        rightGradient: "#E73BCF",
        dark: "#33343F",
      },
      fontFamily: {
        poppins: ["Poppins", "sans-serif"],
      },
      borderRadius: {
        primary: "40px",
      },
    },
  },
  plugins: [
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/forms"),
    require("@shrutibalasa/tailwind-grid-auto-fit"),
  ],
};
