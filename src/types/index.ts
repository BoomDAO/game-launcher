import { Principal } from "@dfinity/principal";

export interface Game {
  url: string;
  name: string;
  canister_id: string;
  description: string;
  platform: string;
  image: string;
}

export interface CreateGame extends Game {
  principal: Principal;
}
