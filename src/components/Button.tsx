import React from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  size?: "normal" | "big";
  rightArrow?: boolean;
}

const Button = ({ size, rightArrow, children, ...rest }: ButtonProps) => {
  return <button {...rest}>{children}</button>;
};

export default Button;
