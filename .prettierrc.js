/** @type {import("prettier").Config} */
const pluginSortImports = require("@trivago/prettier-plugin-sort-imports");
const pluginTailwindcss = require("prettier-plugin-tailwindcss");

const bothParser = {
  ...pluginSortImports.parsers.typescript,
  parse: pluginTailwindcss.parsers.typescript.parse,
};

const mixedPlugin = {
  parsers: {
    typescript: bothParser,
  },
};

module.exports = {
  ...require("@todayweb/prettier"),
  plugins: [mixedPlugin],
  importOrder: [
    "^react",
    "^react/(.*)$",
    "<THIRD_PARTY_MODULES>",
    "^@/(.*)$",
    "^[./]",
  ],
  importOrderSortSpecifiers: true,
};
