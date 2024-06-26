import { HttpAgent, Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import fetch from "cross-fetch";
import { NFID } from "@nfid/embed";
import { SignIdentity } from "@dfinity/agent";
import { AuthClientStorage } from "@dfinity/auth-client/lib/cjs/storage";
import { IdleOptions } from "@dfinity/auth-client";
// import { MyStorage } from "./MyStorage";

type NFIDConfig = {
  origin?: string; // default is "https://nfid.one"
  application?: { // your application details to display in the NFID iframe
    name?: string; // your app name user can recognize
    logo?: string; // your app logo user can recognize
  };
  identity?: SignIdentity;
  storage?: AuthClientStorage;
  keyType?: "ECDSA" | "ed25519" // default is "ECDSA"
  idleOptions?: IdleOptions;
};

var nfid: NFID | null = null;
// let storage = new MyStorage();
const APPLICATION_NAME = "BOOM DAO";
const APPLICATION_LOGO_URL = "https://i.postimg.cc/L4f471FF/logo.png";
const AUTH_PATH =
  "/authenticate/?applicationName=" + APPLICATION_NAME + "&applicationLogo=" + APPLICATION_LOGO_URL + "#authorize";
const NFID_AUTH_URL = "https://nfid.one" + AUTH_PATH;

export const nfidLogin = async (authClient: AuthClient) => {
  await new Promise((resolve, reject) => {
    authClient.login({
      identityProvider: NFID_AUTH_URL,
      windowOpenerFeatures:
        `left=${window.screen.width / 2 - 525 / 2}, ` +
        `top=${window.screen.height / 2 - 705 / 2},` +
        `toolbar=0,location=0,menubar=0,width=525,height=705`,
      derivationOrigin: "https://7p3gx-jaaaa-aaaal-acbda-cai.ic0.app",
      onSuccess: () => {
        resolve(true);
      },
      onError: (err) => {
        console.log("error", err);
        reject();
      },
    });
  });

  return authClient.getIdentity();
};

export const nfidEmbedLogin = async (nfid: NFID) => {
  if (nfid.isAuthenticated) {
    return nfid.getIdentity();
  };
  const delegationIdentity: Identity = await nfid.getDelegation({
    targets: [],
    derivationOrigin: "https://7p3gx-jaaaa-aaaal-acbda-cai.ic0.app",
    maxTimeToLive: BigInt(24) * BigInt(3_600_000_000_000) // 24 hrs
  });
  return delegationIdentity;
};

export const getAuthClient = async () =>
  await AuthClient.create({
    idleOptions: { idleTimeout: 1000 * 60 * 60 * 24 },
  });

export const getNfid = async () => {
  if (nfid) {
    return nfid;
  };
  const new_nfid = await NFID.init({
    application: {
      name: APPLICATION_NAME,
      logo: APPLICATION_LOGO_URL
    },
    // storage: storage,
    keyType: 'Ed25519',
    idleOptions: { idleTimeout: 1000 * 60 * 60 * 24 },
  });
  nfid = new_nfid;
  return new_nfid;
};

export const getAgent = async (identity?: Identity) =>
  new HttpAgent({
    host: "https://icp0.io/",
    fetch,
    identity,
  });
