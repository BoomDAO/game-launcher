import React from "react";
import { cx } from "@/utils";

interface SpaceProps extends React.HTMLAttributes<HTMLDivElement> {
  size?: "small" | "normal" | "medium" | "large";
}

const Space = ({ size = "normal", className, ...rest }: SpaceProps) => {
  return (
    <div
      className={cx(
        size === "small" && "pb-4",
        size === "normal" && "pb-8",
        size === "medium" && "pb-16",
        size === "large" && "pb-32",
        className,
      )}
      {...rest}
    />
  );
};

export default Space;
