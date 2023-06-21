import React from "react";
import { cx } from "@/utils";

export interface CheckboxProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
}

const Checkbox = React.forwardRef<HTMLInputElement, CheckboxProps>(
  ({ label, className, id, ...rest }, ref) => {
    return (
      <div className="relative flex items-start">
        <div className="flex h-6 items-center">
          <input
            ref={ref}
            id={id}
            type="checkbox"
            className={cx(
              "h-6 w-6 rounded-full border-lightPrimary bg-transparent text-lightPrimary focus:outline-none focus:ring-0 dark:border-darkPrimary dark:text-darkPrimary",
              className,
            )}
            {...rest}
          />
        </div>
        <div className="ml-3 leading-6">
          <label htmlFor={id}>{label}</label>
        </div>
      </div>
    );
  },
);

export default Checkbox;
