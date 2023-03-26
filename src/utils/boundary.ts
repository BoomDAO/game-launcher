import { Actor, ActorSubclass, HttpAgent, Identity } from "@dfinity/agent";
import { IDL } from "@dfinity/candid";
import fetch from "cross-fetch";

const getAgent = async () =>
  new HttpAgent({
    host: "https://ic0.app/",
    fetch,
  });

export const getActor = async (
  idlFactory: IDL.InterfaceFactory,
  canisterId: string,
) => {
  const agent = await getAgent();

  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
  });
};
