import React from "react";
import Navigation from "./Navigation";

const Layout = ({ children }: React.PropsWithChildren) => {
  return (
    <div className="px-6 py-4 space-y-6">
      <Navigation />
      {children}
    </div>
  );
};

export default Layout;
