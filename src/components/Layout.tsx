import React from "react";
import Navigation from "./Navigation";

const Layout = ({ children }: React.PropsWithChildren) => {
  return (
    <div className="m-auto w-full max-w-screen-xl space-y-6 px-6 py-4">
      <Navigation />
      {children}
    </div>
  );
};

export default Layout;
