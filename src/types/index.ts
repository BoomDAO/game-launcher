import { UseMutateAsyncFunction } from "@tanstack/react-query";
import { GameFile } from "@/utils";

export interface Game {
  url: string;
  name: string;
  canister_id: string;
  description: string;
  platform: string;
  cover: string;
}

export interface CreateGame
  extends Pick<Game, "name" | "description" | "cover" | "platform"> {
  game: GameFile[];
}

export interface UpdateGameData
  extends Pick<Game, "canister_id" | "name" | "description"> {}

export interface UpdateGameCover extends Pick<Game, "canister_id"> {
  cover: string;
}

export interface UpdateGameFiles extends Pick<Game, "canister_id"> {
  game: GameFile[];
}

export interface UpdateGameSubmit {
  values: UpdateGameData & UpdateGameCover & UpdateGameFiles;
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
    UpdateGameFiles,
    unknown
  >;
}
