import React from "react";
import { cx } from "@/utils";

const FormErrorMessage = ({
  children,
  className,
  ...rest
}: React.HTMLAttributes<HTMLParagraphElement>) => {
  return (
    <p
      className={cx(
        "pl-4 text-sm text-error",
        !children && "hidden",
        className,
      )}
      {...rest}
    >
      {children}
    </p>
  );
};

export default FormErrorMessage;
