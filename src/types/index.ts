export interface Game {
  url: string;
  name: string;
  canister_id: string;
  description: string;
  platform: string;
  image: string;
}

export interface CreateGame
  extends Pick<Game, "name" | "description" | "image" | "platform"> {}
