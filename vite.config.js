import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

const port = 3001;

/** @type {import('vite').UserConfig} */
export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  server: {
    port,
  },
  preview: {
    port,
  },
});
