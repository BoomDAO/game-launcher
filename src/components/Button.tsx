import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { twMerge } from "tailwind-merge";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  size?: "normal" | "big";
  rightArrow?: boolean;
}

const Button = ({
  size = "normal",
  rightArrow,
  children,
  className,
  ...rest
}: ButtonProps) => {
  return (
    <button
      className={twMerge(
        "gradient-bg rounded-primary uppercase text-white",
        rightArrow && "flex items-center",
        size === "normal" && "gap-1 px-6 py-2 text-sm",
        size === "big" && "gap-2 px-12 py-4 text-lg",
        className,
      )}
      {...rest}
    >
      {children}
      {rightArrow && (
        <ArrowUpRightIcon className={size === "normal" ? "w-5" : "w-7"} />
      )}
    </button>
  );
};

export default Button;
