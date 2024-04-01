import { bigint, z } from "zod";
import { SelectOption } from "@/components/ui/Select";
import { Platform } from "@/types";

export const serverErrorMsg = "Something went wrong.";

export const navPaths = {
  home: "/",
  upload_games: "/upload-games",
  upload_games_new: "/upload-games/create-game",
  manage_nfts: "/manage-nfts",
  all_nfts: "manage-nfts/all-nfts",
  manage_nfts_new: "/manage-nfts/create-collection",
  token_deployer: "/token-deployer",
  deploy_new_token: "/token-deployer/deploy-token",
  token: "/token-deployer/token",
  world_deployer: "/world-deployer",
  create_new_world: "/world-deployer/create-world",
  boomdao_candid_url: "https://5pati-hyaaa-aaaal-qb3yq-cai.raw.icp0.io/",
  manage_worlds: "/world-deployer/manage-worlds",
  gaming_guilds_email_verification: "/verify-email",
  gaming_guilds_phone_verification: "/verify-phone",
  profile_picture: "/profile/picture",
  profile_username: "/profile/username",
  wallet_tokens: "/wallet/tokens",
  wallet_nfts: "/wallet/nfts",
  transfer: "/wallet/transfer",
  nftTransfer: "/wallet/transfer/nft",
  twitterPost: "gaming-guilds/onboarding-quests/twitter-post",
  browse_games: "/all-games"
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

export const visibility_types: SelectOption[] = [
  {
    label: "Public",
    value: "public",
  },
  {
    label: "Private",
    value: "private",
  },
  {
    label: "Coming Soon!",
    value: "soon"
  }
];

export const gameDataScheme = {
  name: z.string().min(1, { message: "Name is required." }),
  description: z.string().min(1, { message: "Description is required." }),
  platform: z.custom<Platform>(),
  visibility: z.string().min(1, { message: "Visibility is required" })
};

export const tokenDataScheme = {
  name: z.string().min(1, { message: "Name is required." }),
  symbol: z.string().min(1, {message: "Symbol is required."}),
  description: z.string().min(1, { message: "Description is required." }),
  amount: z.string().min(1, {message: "Amount is required."}),
  logo: z.string().min(1, {message: "Logo is required."}),
  fee: z.string().min(1, {message: "Tx Fee is required."}),
};

export const worldDataScheme = {
  name: z.string().min(1, { message: "Name is required." }),
  cover: z.string().min(1, {message: "Cover is required."}),
}
