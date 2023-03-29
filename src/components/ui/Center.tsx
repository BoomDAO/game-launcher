import React from "react";
import { cx } from "@/utils";

const Center = ({
  className,
  children,
  ...rest
}: React.HTMLAttributes<HTMLDivElement>) => {
  return (
    <div
      className={cx("flex w-full items-center justify-center", className)}
      {...rest}
    >
      {children}
    </div>
  );
};

export default Center;
