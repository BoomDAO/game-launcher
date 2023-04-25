import React from "react";

const Box = ({ children }: React.PropsWithChildren) => {
  return <div className="rounded-primary border p-4">{children}</div>;
};

export default Box;
