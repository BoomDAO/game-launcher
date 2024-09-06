import React from "react";
import { Identity, SignIdentity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getAuthClient, nfidLogin, getNfid, nfidEmbedLogin } from "@/utils";
import { NFID } from "@nfid/embed";
import { PlugTransport } from "../utils/plugTransport";
import { Signer, createDelegationPermissionScope, createAccountsPermissionScope, createCallCanisterPermissionScope } from "@slide-computer/signer";
import { DelegationChain, DelegationIdentity } from "@dfinity/identity";

interface Session {
  identity: Identity | null;
  address: string | null;
  delegationChain: DelegationChain | null;
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
var delegationChain : DelegationChain | null = null;

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
    const identity = nfid.getIdentity() as any;
    const address = identity.getPrincipal().toString();
    const delegationChain = identity.getDelegation().toJSON() as any;
    setSession({
      identity,
      address,
      delegationChain
    });
  };

  // const assignPlugSession = async (identity: Identity, delegationChain: DelegationChain) => {
  //   const address = identity.getPrincipal().toString();
  //   console.log(address);
  //   setSession({
  //     identity,
  //     address,
  //     delegationChain
  //   })
  // };

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

  // const checkPlugAuth = async () => {
  //   try {
  //     if (identity != null && delegationChain != null) {
  //       await assignPlugSession(identity, delegationChain);
  //     } else {
  //       let res = await plugIdentity(signer);
  //       assignPlugSession(res[0], res[1]);
  //       return;
  //     }
  //   } catch (e) {
  //     console.log("err while checking plug auth ", e);
  //     setSession(null);
  //   } finally {
  //     setIsLoading(false);
  //   }
  // };

  React.useEffect(() => {
    checkAuth();
    // checkPlugAuth();
  }, []);

  const logout = async () => {
    const nfid = await getNfid();
    await nfid.logout();

    // setSession(null);
    // setPlug(null);
    // identity = null;
  };

  const login = async () => {
    const nfid = await getNfid();
    const isAuthenticated = nfid.isAuthenticated;
    if(isAuthenticated) return assignSession(nfid);
    await nfidEmbedLogin(nfid);
    window.location.reload();
    return checkAuth();

    // if (identity != null) {
    //   console.log("connected already");
    //   setPlug(identity);
    // } else {
    //   let res : [DelegationIdentity, DelegationChain] = await plugIdentity(signer);
    //   identity = res[0];
    //   delegationChain = res[1];
    //   setPlug(identity);
    // };
    // await checkPlugAuth();
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
