import React from "react";
import { cx } from "@/utils";

const SubHeading = ({
  children,
  className,
  ...rest
}: React.HTMLAttributes<HTMLHeadingElement>) => {
  return (
    <h6 className={cx("text-2xl md:text-3xl", className)} {...rest}>
      {children}
    </h6>
  );
};

export default SubHeading;
