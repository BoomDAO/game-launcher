import { UseMutateAsyncFunction } from "@tanstack/react-query";

export type Platform = "Browser" | "Android" | "Windows";

export type Base64 = string | ArrayBuffer;

export interface GameFile {
  fileArr: number[][];
  fileName: string;
  fileType: string;
}

type GameFiles = GameFile[];

export interface Game {
  url: string;
  name: string;
  canister_id: string;
  description: string;
  platform: Platform;
  cover: string;
  verified: boolean;
  visibility: boolean
}

export interface GameVisibility {
  visibility: string;
};

export interface Collection {
  name: string;
  canister_id: string;
}

export interface CreateCollection {
  name: string;
  description: string;
}

export interface CreateWorldData
  extends Pick<WorldData, "name" | "cover"> { }


export interface CreateTokenData
  extends Pick<TokenData, "name" | "symbol" | "description" | "logo" | "decimals" | "fee" | "amount"> { }

export interface CreateTokenTransfer
  extends Pick<TokenTransferArgs, "principal" | "amount"> { }

export interface CreateTokenApprove
  extends Pick<TokenApproveArgs, "spender" | "amount"> { }

export interface CreateTokenTransferFrom
  extends Pick<TokenTransferFromArgs, "from" | "to" | "amount"> { }

export interface CreateGameData
  extends Pick<Game, "name" | "description" | "cover" | "platform"> { }

export interface UploadGameFileData
  extends Pick<Game, "canister_id" | "name" | "description" | "platform"> { }

export interface CreateGameFiles extends UploadGameFileData {
  files: GameFile[];
}

export interface CreateWorldSubmit {
  values: CreateWorldData;
  mutateData: UseMutateAsyncFunction<string, unknown, CreateWorldData, unknown>;
  canisterId?: string;
}

export interface CreateTokenTransferSubmit {
  values: CreateTokenTransfer;
  mutateData: UseMutateAsyncFunction<string, unknown, CreateTokenTransfer, unknown>;
  canisterId?: string;
}

export interface CreateTokenSubmit {
  values: CreateTokenData;
  mutateData: UseMutateAsyncFunction<string, unknown, CreateTokenData, unknown>;
  canisterId?: string;
}

export interface CreateGameSubmit {
  values: CreateGameData & { files: GameFiles };
  mutateData: UseMutateAsyncFunction<string, unknown, CreateGameData, unknown>;
  mutateFiles: UseMutateAsyncFunction<
    string,
    unknown,
    CreateGameFiles,
    unknown
  >;
  canisterId?: string;
}

export interface UpdateGameData
  extends Pick<Game, "canister_id" | "name" | "description" | "platform"> { }

export interface UpdateGameVisibility
  extends Pick<GameVisibility, "visibility"> { }

export interface UpdateGameCover extends Pick<Game, "canister_id"> {
  cover: string;
}

export interface UpdateGameSubmit {
  values: UpdateGameData & UpdateGameCover & CreateGameFiles;
  mutateData: UseMutateAsyncFunction<string, unknown, UpdateGameData, unknown>;
  mutateCover: UseMutateAsyncFunction<
    string,
    unknown,
    UpdateGameCover,
    unknown
  >;
  mutateFiles: UseMutateAsyncFunction<
    string,
    unknown,
    CreateGameFiles,
    unknown
  >;
}

export interface Airdrop {
  canisterId?: string;
  collectionId: string;
  prevent: boolean;
  metadata: string;
  nft: string;
  burnTime: string;
}

export interface Mint {
  mintForAddress: string;
  canisterId?: string;
  principals: string;
  metadata: string;
  nft: string;
  burnTime: string;
}

export interface Token {
  name: string;
  symbol: string;
  description: string;
  canister: string;
  cover: string;
}

export interface TokenData {
  name: string;
  symbol: string;
  description: string;
  logo: string;
  decimals: string;
  fee: string;
  amount: string;
};

export interface TokenTransferArgs {
  principal: string;
  amount: string;
}

export interface TokenApproveArgs {
  spender: string;
  amount: string;
}

export interface TokenTransferFromArgs {
  from: string;
  to: string;
  amount: string;
}

export interface World {
  name: string;
  cover: string;
  canister: string;
}

export interface WorldData {
  name: string;
  cover: string;
}


