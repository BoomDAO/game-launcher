import React from "react";
import { twMerge } from "tailwind-merge";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";

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
        "gradient-bg text-white rounded-primary uppercase",
        rightArrow && "flex items-center gap-1",
        size === "normal" && "px-6 py-2 text-sm",
        size === "big" && "px-12 py-4 text-lg",
        className
      )}
      {...rest}
    >
      {children}
      {rightArrow && <ArrowUpRightIcon className="w-5" />}
    </button>
  );
};

export default Button;
