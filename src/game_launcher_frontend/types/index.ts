import { UseMutateAsyncFunction } from "@tanstack/react-query";

export type Platform = "Browser" | "Android" | "Windows";

export type Base64 = string | ArrayBuffer;

export type GameFile = File

export interface GameDistributedFile {
  fileArr: number[][];
  fileName: string;
  fileType: string;
}

export interface CreateChunkType {
  chunk_id: number;
}

type GameFiles = File[];

export interface Game {
  url: string;
  name: string;
  canister_id: string;
  description: string;
  platform: Platform;
  cover: string;
  verified: boolean;
  visibility: string;
}

export interface GameVisibility {
  visibility: string;
};

export interface GameRelease {
  released: string;
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

export interface UpgradeWorldData
  extends Pick<WorldWasm, "file"> { }


export interface CreateTokenData
  extends Pick<TokenData, "name" | "symbol" | "description" | "logo" | "decimals" | "fee" | "amount"> { }

export interface CreateTokenTransfer
  extends Pick<TokenTransferArgs, "principal" | "amount"> { }

export interface CreateTokenApprove
  extends Pick<TokenApproveArgs, "spender" | "amount"> { }

export interface CreateTokenTransferFrom
  extends Pick<TokenTransferFromArgs, "from" | "to" | "amount"> { }

export interface CreateGameData
  extends Pick<Game, "name" | "description" | "cover" | "platform" | "visibility"> { }

export interface UploadGameFileData
  extends Pick<Game, "canister_id" | "name" | "description" | "platform" | "visibility"> { }

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

export interface AssetUpload {
  canisterId?: string;
  nft: string;
  assetId: string;
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

export interface WorldWasm {
  file: number[]
}


// Gaming Guilds Interfaces
export interface GuildConfig {
  cid: string;
  fields: [{
    fieldName: string;
    fieldValue: string;
  }];
}

export interface GuildCard {
  aid: string;
  title: string;
  image: string;
  rewards: { name: string; imageUrl: string; value: string; }[];
  countCompleted: string;
  gameUrl: string;
  mustHave: { name: string; imageUrl: string; quantity: string; }[];
  expiration: string;
  type: "Completed" | "Incomplete" | "Claimed";
}

export interface Member {
  imageUrl: string;
  username: string;
  guilds: string;
  joinDate: string;
}

export interface MembersInfo {
  members: Member[];
  totalMembers: string;
}

export interface Field {
  fieldName: string;
  fieldValue: string;
};

export interface StableEntity {
  wid: string;
  eid: string;
  fields: [Field];
};

export interface Action {
  aid: string;
  callerAction: {
    actionConstraint: {
      timeConstraint: {
        intervalDuration: bigint;
        actionsPerInterval: bigint;
        actionExpirationTimestamp: bigint[];
      }[];
      entityConstraint: {
        wid: string[];
        eid: string;
        entityConstraintType: {
          greaterThanEqualToNumber: {
            fieldName: string;
            value: Number;
          };
        };
      }[];
    }[];
    actionResult: {
      outcomes: {
        possibleOutcomes: {
          weight: Number;
          option: {
            transferIcrc: {
              quantity: Number;
              canister: string;
            };
            mintNft: {
              canister: string;
              assetId: string;
              metadata: string;
            };
            updateEntity: {
              wid: string[];
              eid: string;
              updates: {
                incrementNumber: {
                  fieldName: Text;
                  fieldValue: { number: Number; };
                };
              }[];
            };
          };
        }[];
      }[];
    };
  }[];
};

export interface ActionReturn {
  callerPrincipalId: string;
  targetPrincipalId: string[];
  worldPrincipalId: string;
  callerOutcomes: {
    weight: Number;
    option: {
      transferIcrc: {
        quantity: Number;
        canister: string;
      };
      mintNft: {
        canister: string;
        assetId: string;
        metadata: string;
      };
      updateEntity: {
        wid: string[];
        eid: string;
        updates: {
          incrementNumber: {
            fieldName: Text;
            fieldValue: { number: Number; };
          };
        }[];
      };
    };
  }[]
  targetOutcomes: {
    weight: Number;
    option: {
      transferIcrc: {
        quantity: Number;
        canister: string;
      };
      mintNft: {
        canister: string;
        assetId: string;
        metadata: string;
      };
      updateEntity: {
        wid: string[];
        eid: string;
        updates: {
          incrementNumber: {
            fieldName: Text;
            fieldValue: { number: Number; };
          };
        }[];
      };
    };
  }[];
  worldOutcomes: {
    weight: Number;
    option: {
      transferIcrc: {
        quantity: Number;
        canister: string;
      };
      mintNft: {
        canister: string;
        assetId: string;
        metadata: string;
      };
      updateEntity: {
        wid: string[];
        eid: string;
        updates: {
          incrementNumber: {
            fieldName: Text;
            fieldValue: { number: Number; };
          };
        }[];
      };
    };
  }[];
};

