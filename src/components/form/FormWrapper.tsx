import React from "react";
import { cx } from "@/utils";

const FormWrapper = ({
  children,
  className,
  ...rest
}: React.HTMLAttributes<HTMLDivElement>) => {
  return (
    <div className={cx("flex w-full flex-col gap-2", className)} {...rest}>
      {children}
    </div>
  );
};

export default FormWrapper;
