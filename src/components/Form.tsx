import React from "react";
import { twMerge } from "tailwind-merge";

interface FormProps extends React.FormHTMLAttributes<HTMLFormElement> {}

const Form = ({ children, className, ...rest }: FormProps) => {
  return (
    <form className={twMerge("flex flex-col gap-6", className)} {...rest}>
      {children}
    </form>
  );
};

export default Form;
