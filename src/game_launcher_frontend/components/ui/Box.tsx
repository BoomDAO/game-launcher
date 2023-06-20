import React from "react";
import { cx } from "@/utils";

const Box = ({
  children,
  className,
}: React.PropsWithChildren<React.HTMLAttributes<HTMLDivElement>>) => {
  return (
    <div className={cx("rounded-primary border px-8 py-6", className)}>
      {children}
    </div>
  );
};

export default Box;
