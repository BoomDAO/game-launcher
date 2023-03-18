import React from "react";
import { cx } from "@/utils";

const H1 = ({
  children,
  className,
  ...rest
}: React.HTMLAttributes<HTMLHeadingElement>) => {
  return (
    <h1 className={cx("text-6xl", className)} {...rest}>
      {children}
    </h1>
  );
};

export default H1;
