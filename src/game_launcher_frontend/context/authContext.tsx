import React from "react";
import { Identity, SignIdentity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getAuthClient, nfidLogin, getNfid, nfidEmbedLogin, plugIdentity, getPlugKey } from "@/utils";
import { NFID } from "@nfid/embed";
import { PlugTransport } from "../utils/plugTransport";
import { Signer, createDelegationPermissionScope, createAccountsPermissionScope, createCallCanisterPermissionScope } from "@slide-computer/signer";

interface Session {
  identity: Identity | null;
  address: string | null;
}

export interface PlugPublicKey {
  rawKey: ArrayBuffer;
  derKey: ArrayBuffer;
}

interface AuthContext {
  isLoading: boolean;
  session: Session | null;
  logout: () => Promise<void>;
  login: () => Promise<void>;
}

export const AuthContext = React.createContext({} as AuthContext);

export const AuthContextProvider = ({ children }: React.PropsWithChildren) => {
  const [isLoading, setIsLoading] = React.useState(true);
  const [session, setSession] = React.useState<Session | null>(null);
  const [logging, setLogging] = React.useState<boolean>(false);
  const [plug, setPlug] = React.useState<Identity | null>(null);

  const signer = React.useMemo(() => {
    const transport = new PlugTransport();
    return new Signer({ transport });
  }, []);
  console.log(signer);

  const assignSession = (nfid: NFID) => {
    const identity = nfid.getIdentity();
    const address = identity.getPrincipal().toString();

    setSession({
      identity,
      address
    });
  };

  const assignPlugSession = (identity: Identity) => {
    console.log(identity);
    const address = identity.getPrincipal().toString();
    console.log(address);
    setSession({
      identity,
      address
    })
  };

  const checkAuth = async () => {
    try {
      const nfid = await getNfid();
      const isAuthenticated = nfid.isAuthenticated;
      if (!isAuthenticated) return;
      assignSession(nfid);
    } catch (error) {
      console.log("err while checking auth", error);
      setSession(null);
    } finally {
      setIsLoading(false);
    };
  };

  const checkPlugAuth = () => {
    try {
      if (plug) {
        console.log("checkPlugAuth found identity");
        assignPlugSession(plug);
      } else {
        return;
      }
    } catch (e) {
      console.log("err while checking plug auth ", e);
      setSession(null);
    } finally {
      setIsLoading(false);
    }
  };

  React.useEffect(() => {
    // checkAuth();
    checkPlugAuth();
  }, []);

  const logout = async () => {
    // const nfid = await getNfid();
    // await nfid.logout();
    setSession(null);
    setPlug(null);
    sessionStorage.removeItem("plugIdentity");
  };

  const login = async () => {
    // const nfid = await getNfid();
    // const isAuthenticated = nfid.isAuthenticated;
    // if(isAuthenticated) return assignSession(nfid);
    // await nfidEmbedLogin(nfid);
    // window.location.reload();
    // return checkAuth();

    const isConnected = await (window as any).ic.plug.isConnected();
    let identityString = sessionStorage.getItem("plugIdentity");
    if(isConnected && identityString != null) {
      console.log("connected already");
      let identity = JSON.parse(identityString);
      setPlug(identity);
      checkPlugAuth();
    } else {
      let publicKey = await getPlugKey();
      let identity = await plugIdentity(signer, publicKey);
      sessionStorage.setItem("plugIdentity", JSON.stringify(identity));
      setPlug(identity);
      checkPlugAuth();
    };
  };

  const value = {
    isLoading,
    session,
    logout,
    login,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuthContext = () => React.useContext(AuthContext);
