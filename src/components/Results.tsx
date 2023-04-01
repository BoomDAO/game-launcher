import React from "react";
import {
  CheckCircleIcon,
  ExclamationCircleIcon,
  NoSymbolIcon,
} from "@heroicons/react/24/outline";
import Center from "./ui/Center";
import Loader from "./ui/Loader";
import LogoLoader from "./ui/LogoLoader";

type UploadResultState = {
  display: boolean;
  text: string;
};

interface UploadResultProps {
  isLoading: UploadResultState;
  isSuccess: UploadResultState;
  isError: UploadResultState;
}

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

export const UploadResult = ({
  isError,
  isLoading,
  isSuccess,
}: UploadResultProps) => {
  const display = isLoading.display || isError.display || isSuccess.display;

  if (!display) return null;

  if (isLoading.display)
    return (
      <div className="flex gap-2">
        <Loader /> {isLoading.text}
      </div>
    );

  if (isError.display)
    return (
      <div className="flex gap-2 text-error">
        <ExclamationCircleIcon className="h-6 w-6" /> {isError.text}
      </div>
    );

  return (
    <div className="flex gap-2 text-success">
      <CheckCircleIcon className="h-6 w-6" /> {isSuccess.text}
    </div>
  );
};
