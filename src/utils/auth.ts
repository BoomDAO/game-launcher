import { AuthClient } from "@dfinity/auth-client";

const APPLICATION_NAME = "IC_GAMES_DEPLOYER";
const AUTH_PATH =
  "/authenticate/?applicationName=" + APPLICATION_NAME + "#authorize";
const NFID_AUTH_URL = "https://nfid.one" + AUTH_PATH;

export const nfidLogin = async (authClient: AuthClient) => {
  await new Promise((resolve, reject) => {
    authClient.login({
      identityProvider: NFID_AUTH_URL,
      windowOpenerFeatures:
        `left=${window.screen.width / 2 - 525 / 2}, ` +
        `top=${window.screen.height / 2 - 705 / 2},` +
        `toolbar=0,location=0,menubar=0,width=525,height=705`,
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
