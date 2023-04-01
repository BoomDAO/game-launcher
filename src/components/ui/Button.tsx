import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { cx } from "@/utils";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  size?: "normal" | "big";
  rightArrow?: boolean;
  isLoading?: boolean;
}

const Button = ({
  size = "normal",
  rightArrow,
  children,
  className,
  isLoading,
  disabled,
  ...rest
}: ButtonProps) => {
  return (
    <button
      className={cx(
        "flex w-fit items-center rounded-primary uppercase text-white",
        size === "normal" && "gap-1 px-6 py-2 text-sm",
        size === "big" && "gap-2 px-12 py-4 text-lg",
        isLoading || disabled
          ? "cursor-default bg-gray-600 text-gray-500"
          : "gradient-bg",
        className,
      )}
      disabled={disabled || isLoading}
      {...rest}
    >
      {children}
      {isLoading && (
        <img src="/logo.svg" alt="logo" className="h-6 w-6 animate-pulse" />
      )}
      {!isLoading && rightArrow && (
        <ArrowUpRightIcon className={size === "normal" ? "w-5" : "w-7"} />
      )}
    </button>
  );
};

export default Button;
