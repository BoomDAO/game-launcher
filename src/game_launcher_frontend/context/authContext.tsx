import React from "react";
import { Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getAuthClient, nfidLogin } from "@/utils";
import { NFID } from "@nfid/embed";

interface Session {
  identity: Identity | null;
  address: string | null;
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

  const assignSession = (authClient: AuthClient) => {
    const identity = authClient.getIdentity();
    const address = identity.getPrincipal().toString();

    setSession({
      identity,
      address,
    });
  };
  // const assignSession = (nfid : NFID) => {
  //   const identity = nfid.getIdentity();
  //   const address = identity.getPrincipal().toString();

  //   setSession({
  //     identity, 
  //     address
  //   });
  // };

  const checkAuth = async () => {
    try {
      const authClient = await getAuthClient();
      const isAuthenticated = await authClient.isAuthenticated();
      if (!isAuthenticated) return;
      assignSession(authClient);
    } catch (error) {
      console.log("err while checking auth", error);
      setSession(null);
    } finally {
      setIsLoading(false);
    }
    // try {
    //   const nfid = await getNfid();
    //   const isAuthenticated = nfid.isAuthenticated;
    //   if(!isAuthenticated) return;
    //   assignSession(nfid);
    // } catch (error) {
    //   console.log("err while checking auth", error);
    //   setSession(null);
    // } finally {
    //   setIsLoading(false);
    // };
  };

  React.useEffect(() => {
    checkAuth();
  }, []);

  const logout = async () => {
    const authClient = await getAuthClient();
    await authClient.logout();
    setSession(null);
    // const nfid = await getNfid();
    // await nfid.logout();
    // setSession(null);
  };

  const login = async () => {
    const authClient = await getAuthClient();
    const isAuthenticated = await authClient.isAuthenticated();
    if (isAuthenticated) return assignSession(authClient);

    await nfidLogin(authClient!);
    window.location.reload();
    return checkAuth();
    // const nfid = await getNfid();
    // const isAuthenticated = nfid.isAuthenticated;
    // if(isAuthenticated) return assignSession(nfid);
    // await nfidEmbedLogin(nfid);
    // window.location.reload();
    // return checkAuth();
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
