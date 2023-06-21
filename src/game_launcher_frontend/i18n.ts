import { initReactI18next } from "react-i18next";
import i18next from "i18next";
import common from "./locale/en/common.json";

export const defaultNS = "common";

export const resources = {
  en: {
    common,
  },
};

i18next.use(initReactI18next).init({
  resources,
  defaultNS,
  lng: "en",
  fallbackLng: "en",
});

export default i18next;
