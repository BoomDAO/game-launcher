import React from "react";
import { AuthContextProvider, useAuth } from "@/context/authContext";

function App() {
  const { login, logout, session } = useAuth();

  console.log("session", session);

  return (
    <AuthContextProvider>
      {session ? (
        <button onClick={logout}>logout</button>
      ) : (
        <button onClick={login}>login</button>
      )}
    </AuthContextProvider>
  );
}

export default App;
