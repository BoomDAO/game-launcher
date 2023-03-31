import React from "react";
import { ExclamationCircleIcon, NoSymbolIcon } from "@heroicons/react/24/solid";
import Center from "./ui/Center";
import LogoLoader from "./ui/LogoLoader";

export const LoadingResult = ({ children }: React.PropsWithChildren) => {
  return (
    <Center className="flex-col gap-2">
      <LogoLoader />
      {children}
    </Center>
  );
};

export const NoDataResult = ({ children }: React.PropsWithChildren) => {
  return (
    <Center className="flex-col gap-2">
      <NoSymbolIcon className="h-12 w-12" />
      {children}
    </Center>
  );
};

export const ErrorResult = ({ children }: React.PropsWithChildren) => {
  return (
    <Center className="flex-col gap-2">
      <ExclamationCircleIcon className="h-12 w-12" />
      {children}
    </Center>
  );
};
