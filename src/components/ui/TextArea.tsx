import React from "react";
import { cx } from "@/utils";

export interface TextAreaProps
  extends React.InputHTMLAttributes<HTMLTextAreaElement> {
  rows?: number;
}

const TextArea = React.forwardRef<HTMLTextAreaElement, TextAreaProps>(
  ({ className, rows = 5, ...rest }, ref) => {
    return (
      <textarea
        ref={ref}
        className={cx(
          rest.disabled && "border-gray-400 dark:border-gray-600",
          className,
        )}
        rows={rows}
        {...rest}
      />
    );
  },
);

export default TextArea;
