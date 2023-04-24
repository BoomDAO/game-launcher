import { z } from "zod";
import { SelectOption } from "@/components/ui/Select";
import { Platform } from "@/types";

export const serverErrorMsg = "Something went wrong.";

export const navPaths = {
  home: "/",
  upload_games: "/upload-games",
  upload_games_new: "/upload-games/create-game",
  manage_nfts: "/manage-nfts",
  manage_nfts_new: "/manage-nfts/create-collection",
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
    label: "Windows",
    value: "Windows",
  },
];

export const gameDataScheme = {
  name: z.string().min(1, { message: "Name is required." }),
  description: z.string().min(1, { message: "Description is required." }),
  platform: z.custom<Platform>(),
};
