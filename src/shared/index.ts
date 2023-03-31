import { z } from "zod";
import { SelectOption } from "@/components/ui/Select";

export const navPaths = {
  home: "/",
  upload_games: "/upload-games",
  manage_nfts: "/manage-nfts",
  manage_payments: "/manage-payments",
};

export const platform_types: SelectOption[] = [
  {
    label: "Browser",
    value: "Browser",
  },
  {
    label: "Android",
    value: "Android",
  },
  {
    label: "Mac",
    value: "Mac",
  },
  {
    label: "PC",
    value: "PC",
  },
];

export const gameDataScheme = {
  name: z.string().min(1, { message: "Name is required." }),
  description: z.string().min(1, { message: "Description is required." }),
  platform: z.string().min(1, { message: "Platform is required." }),
};
