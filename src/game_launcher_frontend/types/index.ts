import { Principal } from "@dfinity/principal";
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

export interface UserProfile {
  uid: string;
  username: string;
  xp: string;
  image: string;
};

export interface UserCompleteDetail {
  uid: string;
  username: string;
  xp: string;
  image: string;
  twitter: {
    username: string;
    id: string;
  },
  discord: {
    username: string;
  }
};

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
  extends Pick<TokenData, "name" | "symbol" | "description" | "logo" | "fee" | "amount"> { }

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
export interface VerifiedStatus {
  emailVerified: boolean;
  phoneVerified: boolean;
};

export interface GuildConfig {
  cid: string;
  fields: Array<Field>;
}

export interface GuildCard {
  aid: string;
  title: string;
  description: string;
  image: string;
  rewards: { name: string; imageUrl: string; value: string; description: string; }[];
  countCompleted: string;
  gameUrl: string;
  mustHave: { name: string; imageUrl: string; quantity: string; description: string; }[];
  progress: { name: string; imageUrl: string; quantity: string; description: string; }[];
  expiration: string;
  type: "Completed" | "Incomplete" | "Claimed";
  gamersImages: string[];
  dailyQuest: {
    isDailyQuest: boolean;
    resetsIn: string;
  };
  kind: "Gaming" | "Featured" | "Social";
}

export interface Member {
  uid: string;
  rank: string;
  image: string;
  username: string;
  guilds: string;
  joinDate: string;
  reward: string;
}

export interface MembersInfo {
  members: Member[];
  totalMembers: string;
}

export interface StableEntity {
  wid: string;
  eid: string;
  fields: Array<Field>;
};

export interface UserTokenInfo {
  name: string;
  logo: string;
  balance: string;
  symbol: string;
  fee: number;
  decimals: number;
  ledger: string;
};

export interface UserNftInfo {
  principal: string;
  name: string;
  canister: string;
  balance: string;
  logo: string;
  url: string;
  stakedNfts: [[string, Number]];
  unstakedNfts: [[string, Number]];
  dissolvedNfts: [[string, Number, string]];
};

export interface EXTStake {
  'staker': string,
  'dissolvedAt': bigint,
  'stakedAt': bigint,
  'tokenIndex': number,
}

export interface Profile {
  principal: string;
  username: string;
  image: string;
  tokens: UserTokenInfo[];
};

export interface QuestGamersInfo {
  aid: string;
  total: string;
  images: string[];
};

export type actionId = string;
export type configId = string;
export type entityId = string;
export type worldId = string;
export interface Action {
  'aid': string,
  'callerAction': [] | [SubAction],
  'targetAction': [] | [SubAction],
  'worldAction': [] | [SubAction],
}
export interface ActionArg { 'fields': Array<Field>, 'actionId': string }
export interface ActionConstraint {
  'icrcConstraint': Array<IcrcTx>,
  'entityConstraint': Array<EntityConstraint>,
  'nftConstraint': Array<NftTx>,
  'timeConstraint': [] | [
    {
      'actionExpirationTimestamp': [] | [bigint],
      'actionHistory': Array<{ 'updateEntity': UpdateEntity }>,
      'actionStartTimestamp': [] | [bigint],
      'actionTimeInterval': [] | [
        { 'intervalDuration': bigint, 'actionsPerInterval': bigint }
      ],
    }
  ],
}
export interface ActionLockStateArgs { 'aid': string, 'uid': string }
export interface ActionOutcome {
  'possibleOutcomes': Array<ActionOutcomeOption>,
}
export interface ActionOutcomeHistory {
  'wid': worldId,
  'appliedAt': bigint,
  'option': { 'updateEntity': UpdateEntity } |
  { 'updateAction': UpdateAction } |
  { 'transferIcrc': TransferIcrc } |
  { 'mintNft': MintNft },
}
export interface ActionOutcomeOption {
  'weight': number,
  'option': { 'updateEntity': UpdateEntity } |
  { 'updateAction': UpdateAction } |
  { 'transferIcrc': TransferIcrc } |
  { 'mintNft': MintNft },
}
export interface ActionResult { 'outcomes': Array<ActionOutcome> }
export interface ActionReturn {
  'worldOutcomes': Array<ActionOutcomeOption>,
  'targetOutcomes': Array<ActionOutcomeOption>,
  'targetPrincipalId': string,
  'callerPrincipalId': string,
  'worldPrincipalId': string,
  'callerOutcomes': Array<ActionOutcomeOption>,
}
export interface ActionState {
  'actionCount': bigint,
  'intervalStartTs': bigint,
  'actionId': string,
}
export interface ActionStatusReturn {
  'entitiesStatus': Array<ConstraintStatus>,
  'timeStatus': {
    'nextAvailableTimestamp': [] | [bigint],
    'actionsLeft': [] | [bigint],
  },
  'actionHistoryStatus': Array<ConstraintStatus>,
  'isValid': boolean,
}
export interface AddToList { 'value': string, 'fieldName': string }
export type BlockIndex = bigint;
export type BlockIndex__1 = bigint;
export interface ConstraintStatus {
  'eid': string,
  'expectedValue': string,
  'currentValue': string,
  'fieldName': string,
}
export interface ContainsText {
  'contains': boolean,
  'value': string,
  'fieldName': string,
}
export interface DecrementActionCount {
  'value': { 'number': number } |
  { 'formula': string },
}
export interface DecrementNumber {
  'fieldName': string,
  'fieldValue': { 'number': number } |
  { 'formula': string },
}
export type DeleteEntity = {};
export interface DeleteField { 'fieldName': string }
export interface EntityConstraint {
  'eid': entityId,
  'wid': [] | [worldId],
  'entityConstraintType': EntityConstraintType,
}
export type EntityConstraintType = { 'greaterThanEqualToNumber': GreaterThanOrEqualToNumber };
export interface EntityPermission { 'eid': entityId, 'wid': worldId }
export interface EntitySchema {
  'eid': string,
  'uid': string,
  'fields': Array<Field>,
}
export interface EqualToNumber {
  'value': number,
  'equal': boolean,
  'fieldName': string,
}
export interface EqualToText {
  'value': string,
  'equal': boolean,
  'fieldName': string,
}
export interface Exist { 'value': boolean }
export interface ExistField { 'value': boolean, 'fieldName': string }
export interface Field { 'fieldName': string, 'fieldValue': string }
export interface GlobalPermission { 'wid': worldId }
export interface GreaterThanNowTimestamp { 'fieldName': string }
export interface GreaterThanNumber { 'value': number, 'fieldName': string }
export interface GreaterThanOrEqualToNumber {
  'value': number,
  'fieldName': string,
}
export interface IcrcTx {
  'toPrincipal': string,
  'canister': string,
  'amount': number,
}
export interface IncrementNumber {
  'fieldName': string,
  'fieldValue': { 'number': number }
}
export interface LessThanNowTimestamp { 'fieldName': string }
export interface LessThanNumber { 'value': number, 'fieldName': string }
export interface LowerThanOrEqualToNumber {
  'value': number,
  'fieldName': string,
}
export interface MintNft {
  'assetId': string,
  'metadata': string,
  'canister': string,
}
export interface NftTransfer { 'toPrincipal': string }
export interface NftTx {
  'metadata': [] | [string],
  'nftConstraintType': {
    'hold': { 'originalEXT': null } |
    { 'boomEXT': null }
  } |
  { 'transfer': NftTransfer },
  'canister': string,
}
export interface RemoveFromList { 'value': string, 'fieldName': string }
export interface RenewTimestamp {
  'fieldName': string,
  'fieldValue': { 'number': number } |
  { 'formula': string },
}
export type Result = { 'ok': TransferResult } |
{ 'err': { 'Err': string } | { 'TxErr': TransferError } };
export type Result_1 = { 'ok': TransferResult__1 } |
{ 'err': { 'Err': string } | { 'TxErr': TransferError__1 } };
export type Result_2 = { 'ok': null } |
{ 'err': null };
export type Result_3 = { 'ok': ActionReturn } |
{ 'err': string };
export type Result_4 = { 'ok': string } |
{ 'err': string };
export type Result_5 = { 'ok': Array<StableEntity> } | { 'err': string };
export type Result_6 = { 'ok': Array<ActionState> } | { 'err': string };
export type Result_7 = { 'ok': ActionStatusReturn } | { 'err': string };
export type Result_8 = { 'ok': Array<ActionOutcomeHistory> } |
{ 'err': string };
export interface SetNumber {
  'fieldName': string,
  'fieldValue': { 'number': number } |
  { 'formula': string },
}
export interface SetText { 'fieldName': string, 'fieldValue': string }
export interface StableConfig { 'cid': configId, 'fields': Array<Field> }
export interface ConfigData {
  'cid': configId,
  'imageUrl': string,
  'description': string,
  'name': string,
  'gameUrl': string
};
export interface StableEntity {
  'eid': entityId,
  'wid': worldId,
  'fields': Array<Field>,
}
export interface SubAction {
  'actionConstraint': [] | [ActionConstraint],
  'actionResult': ActionResult,
}
export type Timestamp = bigint;
export type Tokens = bigint;
export interface Tokens__1 { 'e8s': bigint }
export type TransferError = {
  'GenericError': { 'message': string, 'error_code': bigint }
} |
{ 'TemporarilyUnavailable': null } |
{ 'BadBurn': { 'min_burn_amount': Tokens } } |
{ 'Duplicate': { 'duplicate_of': BlockIndex } } |
{ 'BadFee': { 'expected_fee': Tokens } } |
{ 'CreatedInFuture': { 'ledger_time': Timestamp } } |
{ 'TooOld': null } |
{ 'InsufficientFunds': { 'balance': Tokens } };
export type TransferError__1 = {
  'TxTooOld': { 'allowed_window_nanos': bigint }
} |
{ 'BadFee': { 'expected_fee': Tokens__1 } } |
{ 'TxDuplicate': { 'duplicate_of': BlockIndex__1 } } |
{ 'TxCreatedInFuture': null } |
{ 'InsufficientFunds': { 'balance': Tokens__1 } };
export interface TransferIcrc { 'canister': string, 'quantity': number }
export type TransferResult = { 'Ok': BlockIndex } |
{ 'Err': TransferError };
export type TransferResult__1 = { 'Ok': BlockIndex__1 } |
{ 'Err': TransferError__1 };
export interface UpdateAction {
  'aid': actionId,
  'updates': Array<UpdateActionType>,
}
export type UpdateActionType = {
  'decrementActionCount': DecrementActionCount
};
export interface UpdateEntity {
  'eid': entityId,
  'wid': [] | [worldId],
  'updates': Array<UpdateEntityType>,
}
export type UpdateEntityType = { 'setNumber': SetNumber } | { 'incrementNumber': IncrementNumber } | { 'decrementNumber': DecrementNumber };



export interface Account {
  'owner': Principal,
  'subaccount': [] | [Uint8Array | number[]],
}
export type AccountIdentifier = string;
export interface FeatureFlags { 'icrc2': boolean }
export type Icrc1BlockIndex = bigint;
export type Icrc1Tokens = bigint;
export type Icrc1TransferError = {
  'GenericError': { 'message': string, 'error_code': bigint }
} |
{ 'TemporarilyUnavailable': null } |
{ 'BadBurn': { 'min_burn_amount': Icrc1Tokens } } |
{ 'Duplicate': { 'duplicate_of': Icrc1BlockIndex } } |
{ 'BadFee': { 'expected_fee': Icrc1Tokens } } |
{ 'CreatedInFuture': { 'ledger_time': bigint } } |
{ 'TooOld': null } |
{ 'InsufficientFunds': { 'balance': Icrc1Tokens } };
export type Icrc1TransferResult = { 'Ok': Icrc1BlockIndex } |
{ 'Err': Icrc1TransferError };

export type MetadataValue = { 'Int': bigint } |
{ 'Nat': bigint } |
{ 'Blob': Uint8Array | number[] } |
{ 'Text': string };
export interface SupplyConfigs {
  'boom_dao_treasury': {
    'icp': bigint,
    'boom': bigint,
    'icrc': bigint,
    'icp_account': AccountIdentifier,
    'icrc_result': [] | [TransferResult],
    'icrc_account': Account,
    'icp_result': [] | [TransferResult__1],
    'boom_result': [] | [TransferResult],
  },
  'participants': { 'icrc': bigint },
  'other': [] | [
    {
      'icp': bigint,
      'boom': bigint,
      'icrc': bigint,
      'account': Account,
      'icrc_result': [] | [TransferResult],
      'icp_result': [] | [Icrc1TransferResult],
      'boom_result': [] | [TransferResult],
    }
  ],
  'team': {
    'icp': bigint,
    'boom': bigint,
    'icrc': bigint,
    'account': Account,
    'icrc_result': [] | [TransferResult],
    'icp_result': [] | [Icrc1TransferResult],
    'boom_result': [] | [TransferResult],
  },
  'liquidity_pool': {
    'icp': bigint,
    'boom': bigint,
    'icrc': bigint,
    'account': Account,
    'icrc_result': [] | [TransferResult],
    'icp_result': [] | [Icrc1TransferResult],
    'boom_result': [] | [TransferResult],
  },
  'gaming_guilds': {
    'icp': bigint,
    'boom': bigint,
    'icrc': bigint,
    'account': Account,
    'icrc_result': [] | [TransferResult],
    'icp_result': [] | [Icrc1TransferResult],
    'boom_result': [] | [TransferResult],
  },
}
export interface Token {
  'fee': bigint,
  'decimals': [] | [number],
  'logo': string,
  'name': string,
  'description': string,
  'token_canister_id': string,
  'symbol': string,
}
export interface TokenInfo {
  'token_canister_id': string,
  'token_swap_configs': TokenSwapConfigs,
  'token_configs': Token,
  'token_project_configs': TokenProject,
}
export interface TokenProject {
  'creator': string,
  'metadata': Array<[string, string]>,
  'name': string,
  'description': { 'formattedText': string } |
  { 'plainText': string },
  'website': string,
  'bannerUrl': string,
  'creatorImageUrl': string,
  'creatorAbout': string,
}
export interface TokenSwapConfigs {
  'max_token_e8s': bigint,
  'min_token_e8s': bigint,
  'min_participant_token_e8s': bigint,
  'swap_start_timestamp_seconds': bigint,
  'swap_due_timestamp_seconds': bigint,
  'token_supply_configs': SupplyConfigs,
  'max_participant_token_e8s': bigint,
  'swap_type': TokenSwapType,
}
export type TokenSwapType = { 'icp': null } | { 'boom': null };
export interface TokensInfo {
  'active': Array<TokenInfo>,
  'inactive': Array<TokenInfo>,
}

export interface TokenConfigs {
  name: string;
  symbol: string;
  logoUrl: string;
  description: string;
}

export interface SwapConfigs {
  swapType: string;
  raisedToken: string;
  maxToken: string;
  minToken: string;
  minParticipantToken: string;
  maxParticipantToken: string;
  participants: string;
  endTimestamp: {
    days: string,
    hrs: string,
    mins: string
  };
  status: boolean;
  result: boolean;
}

export interface ProjectConfigs {
  name: string;
  bannerUrl: string;
  description: string;
  website: string;
  creator: string;
  creatorAbout: string;
  creatorImageUrl: string;
}

export interface LaunchCardProps {
  id: string;
  project: ProjectConfigs;
  swap: SwapConfigs;
  token: TokenConfigs;
}

export interface ParticipantDetails {
  'boom_e8s' : bigint,
  'icp_e8s' : bigint,
  'boom_refund_result' : [] | [TransferResult],
  'account' : Account,
  'token_e8s' : [] | [bigint],
  'mint_result' : [] | [TransferResult],
  'icp_refund_result' : [] | [Icrc1TransferResult],
}
type GranularSpeed = {
  type: "keyStrokeDelayInMs";
  value: number;
};
type Speed =
  | 1
  | 2
  | 3
  | 4
  | 5
  | 6
  | 7
  | 8
  | 9
  | 10
  | 11
  | 12
  | 13
  | 14
  | 15
  | 16
  | 17
  | 18
  | 19
  | 20
  | 21
  | 22
  | 23
  | 24
  | 25
  | 26
  | 27
  | 28
  | 29
  | 30
  | 31
  | 32
  | 33
  | 34
  | 35
  | 36
  | 37
  | 38
  | 39
  | 40
  | 41
  | 42
  | 43
  | 44
  | 45
  | 46
  | 47
  | 48
  | 49
  | 50
  | 51
  | 52
  | 53
  | 54
  | 55
  | 56
  | 57
  | 58
  | 59
  | 60
  | 61
  | 62
  | 63
  | 64
  | 65
  | 66
  | 67
  | 68
  | 69
  | 70
  | 71
  | 72
  | 73
  | 74
  | 75
  | 76
  | 77
  | 78
  | 79
  | 80
  | 81
  | 82
  | 83
  | 84
  | 85
  | 86
  | 87
  | 88
  | 89
  | 90
  | 91
  | 92
  | 93
  | 94
  | 95
  | 96
  | 97
  | 98
  | 99;

export type TypeSpeed = GranularSpeed | Speed | undefined;
