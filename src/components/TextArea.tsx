import React from "react";
import { twMerge } from "tailwind-merge";

interface TextAreaProps extends React.InputHTMLAttributes<HTMLTextAreaElement> {
  rows?: number;
}

const TextArea = React.forwardRef<HTMLTextAreaElement, TextAreaProps>(
  ({ className, rows = 5, ...rest }, ref) => {
    return (
      <textarea
        ref={ref}
        className={twMerge("", className)}
        rows={rows}
        {...rest}
      />
    );
  },
);

export default TextArea;
