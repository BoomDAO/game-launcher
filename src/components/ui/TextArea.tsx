import React from "react";
import { cx } from "@/utils";

export interface TextAreaProps
  extends React.InputHTMLAttributes<HTMLTextAreaElement> {
  rows?: number;
}

const TextArea = React.forwardRef<HTMLTextAreaElement, TextAreaProps>(
  ({ className, rows = 5, ...rest }, ref) => {
    return (
      <textarea ref={ref} className={cx("", className)} rows={rows} {...rest} />
    );
  },
);

export default TextArea;
