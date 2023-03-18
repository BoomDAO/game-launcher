import React from "react";
import Footer from "./Footer";
import Navigation from "./Navigation";
import Space from "./Space";

const Layout = ({ children }: React.PropsWithChildren) => {
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
