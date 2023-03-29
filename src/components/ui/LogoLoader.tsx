import React from "react";
import { cx } from "@/utils";

interface LogoLoaderProps extends React.ImgHTMLAttributes<HTMLImageElement> {}

const LogoLoader = ({ children, className, ...rest }: LogoLoaderProps) => {
  return (
    <img
      {...rest}
      src="/logo.svg"
      alt="logo"
      className={cx("h-12 w-12 animate-pulse", className)}
    />
  );
};

export default LogoLoader;
