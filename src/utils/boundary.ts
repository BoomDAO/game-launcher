import { HttpAgent, Identity } from "@dfinity/agent";
import fetch from "cross-fetch";

export const getAgent = async (identity?: Identity) =>
  new HttpAgent({
    host: "https://ic0.app/",
    fetch,
    identity,
  });
