import React from "react";

const Layout = ({ children }: React.PropsWithChildren) => {
  return <div className="px-6 py-4">{children}</div>;
};

export default Layout;
