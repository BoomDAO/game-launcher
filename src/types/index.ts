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
}

export interface Collection {
  name: string;
  canister_id: string;
}

export interface CreateCollection {
  name: string;
  description: string;
}

export interface CreateGameData
  extends Pick<Game, "name" | "description" | "cover" | "platform"> {}

export interface UploadGameFileData
  extends Pick<Game, "canister_id" | "name" | "description" | "platform"> {}

export interface CreateGameFiles extends UploadGameFileData {
  files: GameFile[];
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
  extends Pick<Game, "canister_id" | "name" | "description" | "platform"> {}

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
  address: boolean;
  metadata: string;
  nft: string;
  burnTime: string;
}
