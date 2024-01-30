import { HttpAgent, Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import fetch from "cross-fetch";

const APPLICATION_NAME = "BOOM DAO";
const APPLICATION_LOGO_URL = "https://i.postimg.cc/L4f471FF/logo.png";
const AUTH_PATH =
  "/authenticate/?applicationName=" + APPLICATION_NAME+"&applicationLogo="+APPLICATION_LOGO_URL+"#authorize";
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

export const getAuthClient = async () =>
  await AuthClient.create({
    idleOptions: { idleTimeout: 1000 * 60 * 60 * 24 },
  });

export const getAgent = async (identity?: Identity) =>
  new HttpAgent({
    host: "https://icp0.io/",
    fetch,
    identity,
  });
