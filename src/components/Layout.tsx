import React from "react";
import Footer from "./Footer";
import Navigation from "./Navigation";

const Layout = ({ children }: React.PropsWithChildren) => {
  return (
    <div className="m-auto flex min-h-screen w-full max-w-screen-xl flex-col px-8 py-6">
      <Navigation />
      <main className="flex-1">{children}</main>
      <Footer />
    </div>
  );
};

export default Layout;
