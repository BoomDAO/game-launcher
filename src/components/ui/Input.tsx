import React from "react";
import { cx } from "@/utils";

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, ...rest }, ref) => {
    return (
      <input
        ref={ref}
        className={cx(
          rest.disabled && "border-gray-400 dark:border-gray-600",
          className,
        )}
        {...rest}
      />
    );
  },
);

export default Input;
