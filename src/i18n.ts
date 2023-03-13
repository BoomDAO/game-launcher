import { initReactI18next } from "react-i18next";
import i18next from "i18next";
import common from "./locale/en/common.json";

const defaultNS = "common";

const resources = {
  en: {
    common,
  },
};

declare module "i18next" {
  interface CustomTypeOptions {
    defaultNS: typeof defaultNS;
    resources: (typeof resources)["en"];
  }
}

i18next.use(initReactI18next).init({
  resources,
  defaultNS,
  lng: "en",
  fallbackLng: "en",
});

export default i18next;
