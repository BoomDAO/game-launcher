import React from "react";
import { Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getAuthClient, nfidLogin, getNfid, nfidEmbedLogin, plugLogin } from "@/utils";
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
  const assignSession = (nfid : NFID) => {
    const identity = nfid.getIdentity();
    const address = identity.getPrincipal().toString();

    setSession({
      identity, 
      address
    });
  };

  const checkAuth = async () => {
    try {
      const nfid = await getNfid();
      const isAuthenticated = nfid.isAuthenticated;
      if(!isAuthenticated) return;
      assignSession(nfid);
    } catch (error) {
      console.log("err while checking auth", error);
      setSession(null);
    } finally {
      setIsLoading(false);
    };
  };

  React.useEffect(() => {
    checkAuth();
  }, []);

  const logout = async () => {
    const nfid = await getNfid();
    await nfid.logout();
    setSession(null);
  };

  const login = async () => {
    // const nfid = await getNfid();
    // const isAuthenticated = nfid.isAuthenticated;
    // if(isAuthenticated) return assignSession(nfid);
    // await nfidEmbedLogin(nfid);
    // window.location.reload();
    await plugLogin();
    return checkAuth();
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
