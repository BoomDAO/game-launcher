// import { Principal } from "@dfinity/principal";
import React from "react";
import { Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { nfidLogin } from "@/utils";

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
  const [isLoading, setIsLoading] = React.useState(false);
  const [session, setSession] = React.useState<Session | null>(null);

  const assignSession = (authClient: AuthClient) => {
    const identity = authClient.getIdentity();

    setSession({
      identity,
      address: "1234312312",
    });
  };

  const checkAuth = async () => {
    try {
      setIsLoading(true);
      const authClient = await AuthClient.create();
      const isAuthenticated = await authClient.isAuthenticated();
      if (!isAuthenticated) return;
      assignSession(authClient);
    } catch (error) {
      console.log("err while checking auth", error);
      setSession(null);
    } finally {
      setIsLoading(false);
    }
  };

  React.useEffect(() => {
    checkAuth();
  }, []);

  const logout = async () => {
    const authClient = await AuthClient.create();
    await authClient.logout();
    setSession(null);
  };

  const login = async () => {
    const authClient = await AuthClient.create();
    const isAuthenticated = await authClient.isAuthenticated();
    if (isAuthenticated) return assignSession(authClient);

    await nfidLogin(authClient);

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

export const useAuth = () => React.useContext(AuthContext);
