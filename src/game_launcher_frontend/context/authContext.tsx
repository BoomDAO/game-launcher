import React from "react";
import { Identity, SignIdentity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getAuthClient, nfidLogin, getNfid, nfidEmbedLogin, plugIdentity } from "@/utils";
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

var identity : Identity | null = null;

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

  const assignSession = (nfid: NFID) => {
    const identity = nfid.getIdentity();
    const address = identity.getPrincipal().toString();

    setSession({
      identity,
      address
    });
  };

  const assignPlugSession = async (identity: Identity) => {
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

  const checkPlugAuth = async () => {
    try {
      if (identity != null) {
        console.log(identity);
        await assignPlugSession(identity);
      } else {
        identity = await plugIdentity(signer);
        assignPlugSession(identity);
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
    identity = null;
  };

  const login = async () => {
    // const nfid = await getNfid();
    // const isAuthenticated = nfid.isAuthenticated;
    // if(isAuthenticated) return assignSession(nfid);
    // await nfidEmbedLogin(nfid);
    // window.location.reload();
    // return checkAuth();

    if (identity != null) {
      console.log("connected already");
      setPlug(identity);
      console.log(identity);
    } else {
      let newIdentity = await plugIdentity(signer);
      identity = newIdentity;
      setPlug(identity);
    };
    await checkPlugAuth();
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
