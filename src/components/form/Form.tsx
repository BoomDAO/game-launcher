import React from "react";
import { cx } from "@/utils";

interface FormProps extends React.FormHTMLAttributes<HTMLFormElement> {}

const Form = ({ children, className, ...rest }: FormProps) => {
  return (
    <form className={cx("flex flex-col gap-6", className)} {...rest}>
      {children}
    </form>
  );
};

export default Form;
