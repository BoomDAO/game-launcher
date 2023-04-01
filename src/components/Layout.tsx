import React from "react";
import { useAuth } from "@/context/authContext";
import Footer from "./Footer";
import TopBar from "./TopBar";
import Center from "./ui/Center";
import LogoLoader from "./ui/LogoLoader";
import Space from "./ui/Space";

const Layout = ({ children }: React.PropsWithChildren) => {
  const { isLoading } = useAuth();

  if (isLoading)
    return (
      <Center className="h-screen">
        <LogoLoader className="h-20 w-20" />
      </Center>
    );

  return (
    <>
      <TopBar />
      <div className="m-auto flex min-h-screen w-full max-w-screen-xl flex-col px-8 py-6">
        <Space size="medium" />
        <main className="flex-1">{children}</main>
        <Space size="medium" />
        <Footer />
      </div>
    </>
  );
};

export default Layout;
