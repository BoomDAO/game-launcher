import React from "react";
import { Identity, SignIdentity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getAuthClient, nfidLogin, getNfid, nfidEmbedLogin, plugLogin, getPlugSigner, getPlugKey } from "@/utils";
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
  const [pubKey, setPubKey] = React.useState<PlugPublicKey | null>(null);
  const [plugIdentity, setPlugIdentity] = React.useState<Identity | null>(null);

  const signer = React.useMemo(() => {
    const transport = new PlugTransport();

    return new Signer({ transport });
  }, []);

  const requestPermissions = React.useCallback(async () => {
    const permissions = await signer.requestPermissions([createDelegationPermissionScope({}), createCallCanisterPermissionScope()])
  }, [signer]);

  const assignSession = (nfid: NFID) => {
    const identity = nfid.getIdentity();
    const address = identity.getPrincipal().toString();

    setSession({
      identity,
      address
    });
  };

  const assignPlugSession = (identity: Identity) => {
    const address = identity.getPrincipal().toString();
    console.log(address);
    console.log(identity);
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
      const isConnected = await (window as any).ic.plug.isConnected();
      if (!isConnected || !plugIdentity) {
        console.log("check 1");
        console.log(plugIdentity);
        return;
      } else {
        console.log("check 4");
        setPubKey(pubKey);
        setPlugIdentity(plugIdentity);
        assignPlugSession(plugIdentity);
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
    setPlugIdentity(null);
    setPubKey(null);
  };

  const login = async () => {
    // const nfid = await getNfid();
    // const isAuthenticated = nfid.isAuthenticated;
    // if(isAuthenticated) return assignSession(nfid);
    // await nfidEmbedLogin(nfid);
    // window.location.reload();
    // return checkAuth();

    const isConnected = await (window as any).ic.plug.isConnected();
    console.log(await (window as any).ic.plug);
    if (isConnected && plugIdentity) {
      console.log("check 2");
      return checkPlugAuth();
    } else {
      console.log("check 3");
      const pubKey = await getPlugKey();
      setPubKey(pubKey);
      await requestPermissions();
      const identity = await plugLogin(signer, pubKey);
      setPlugIdentity(identity);
      assignPlugSession(identity);
    }
    return checkPlugAuth();
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
