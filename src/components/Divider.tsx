import React from "react";
import { twMerge } from "tailwind-merge";

interface DividerProps extends React.HTMLAttributes<HTMLDivElement> {}

const Divider = ({ className, ...rest }: DividerProps) => {
  return (
    <div
      className={twMerge("h-0.5 w-full bg-dark dark:bg-white", className)}
      {...rest}
    />
  );
};

export default Divider;
