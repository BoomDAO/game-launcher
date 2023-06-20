import React from "react";
import { cx } from "@/utils";

interface DividerProps extends React.HTMLAttributes<HTMLDivElement> {}

const Divider = ({ className, ...rest }: DividerProps) => {
  return (
    <div
      className={cx("h-0.5 w-full bg-dark dark:bg-white", className)}
      {...rest}
    />
  );
};

export default Divider;
