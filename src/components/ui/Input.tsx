import React from "react";
import { cx } from "@/utils";
import Hint from "./Hint";

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  hint?: {
    body: React.ReactNode;
    right?: boolean;
  };
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, hint, ...rest }, ref) => {
    return (
      <div className="relative">
        <input
          ref={ref}
          className={cx(
            rest.disabled && "border-gray-400 dark:border-gray-600",
            hint && "pr-16",
            className,
          )}
          {...rest}
        />

        {!!hint && (
          <div className="absolute right-6 bottom-3">
            <Hint right={hint.right}>{hint.body}</Hint>
          </div>
        )}
      </div>
    );
  },
);

export default Input;
