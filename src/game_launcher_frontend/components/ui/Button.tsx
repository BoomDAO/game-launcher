import React from "react";
import { ArrowUpRightIcon } from "@heroicons/react/20/solid";
import { cx } from "@/utils";
import Loader from "./Loader";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  size?: "normal" | "big";
  rightArrow?: boolean;
  isLoading?: boolean;
  isClaimSuccess?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      size = "normal",
      rightArrow,
      children,
      className,
      isLoading,
      isClaimSuccess,
      disabled,
      ...rest
    },
    ref,
  ) => {
    return (
      <button
        ref={ref}
        className={cx(
          "flex w-fit items-center rounded-primary uppercase text-white",
          size === "normal" && "gap-2 px-6 py-2 text-sm",
          size === "big" && "gap-2 px-12 py-4 text-base md:text-lg",
          isLoading || disabled
            ? "cursor-default bg-gray-600 text-gray-500"
            : "gradient-bg",
          className,
          isClaimSuccess || disabled
          ? "cursor-default gradient-bg-grey"
          : ""
        )}
        disabled={disabled || isLoading || isClaimSuccess}
        {...rest}
      >
        {
          (isClaimSuccess) ? <>DONE</> : <>{children}</>
        }
        {isLoading && (
          <Loader
            className={cx(size === "normal" ? "h-4 w-4" : "ml-2 h-6 w-6")}
          />
          // <img src="/logo.svg" alt="logo" className="h-6 w-6 animate-pulse" />
        )}
        {!isLoading && rightArrow && (
          <ArrowUpRightIcon
            className={size === "normal" ? "w-5" : "w-6 md:w-7"}
          />
        )}
      </button>
    );
  },
);

export default Button;
