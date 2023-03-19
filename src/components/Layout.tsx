import React from "react";
import { useAuth } from "@/context/authContext";
import Footer from "./Footer";
import LogoLoader from "./LogoLoader";
import Navigation from "./Navigation";
import Space from "./Space";

const Layout = ({ children }: React.PropsWithChildren) => {
  const { isLoading } = useAuth();

  if (isLoading) return <LogoLoader />;

  return (
    <div className="m-auto flex min-h-screen w-full max-w-screen-xl flex-col px-8 py-6">
      <Navigation />
      <Space />
      <main className="flex-1">{children}</main>
      <Space size="medium" />
      <Footer />
    </div>
  );
};

export default Layout;
