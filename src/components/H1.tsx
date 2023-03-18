import React from "react";
import { twMerge } from "tailwind-merge";

const H1 = ({
  children,
  className,
  ...rest
}: React.HTMLAttributes<HTMLHeadingElement>) => {
  return (
    <h1 className={twMerge("text-6xl", className)} {...rest}>
      {children}
    </h1>
  );
};

export default H1;
