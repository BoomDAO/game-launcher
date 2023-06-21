import React from "react";
import {
  CheckCircleIcon,
  ExclamationCircleIcon,
  NoSymbolIcon,
} from "@heroicons/react/24/outline";
import Center from "./ui/Center";
import Loader from "./ui/Loader";

type UploadResultState = {
  display: boolean;
  children: React.ReactNode;
};

interface UploadResultProps {
  isLoading: UploadResultState;
  isSuccess: UploadResultState;
  isError: UploadResultState & {
    error?: unknown;
  };
}

const ErrorAlert = ({ children }: React.PropsWithChildren) => {
  return (
    <div className="bg-error p-4">
      <div className="flex">
        <div className="ml-3">
          <h3 className="text-sm font-medium text-white">Error message</h3>
          <div className="mt-2 text-sm text-white">{children}</div>
        </div>
      </div>
    </div>
  );
};

export const LoadingResult = ({ children }: React.PropsWithChildren) => {
  return (
    <Center className="flex-col gap-2">
      <Loader className="h-7 w-7" />
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

export const PreparingForUpload = ({ show }: { show: boolean }) => {
  return show ? (
    <div className="flex items-center gap-2 ">
      <Loader /> Preparing for upload...
    </div>
  ) : null;
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
      <div className="flex items-center gap-2">
        <Loader /> {isLoading.children}
      </div>
    );

  if (isError.display)
    return (
      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-2 text-error ">
          <ExclamationCircleIcon className="h-6 w-6" /> {isError.children}
        </div>

        {String(isError?.error) && (
          <ErrorAlert>{String(isError.error)}</ErrorAlert>
        )}
      </div>
    );

  return (
    <div className="flex items-center gap-2 text-success ">
      <CheckCircleIcon className="h-6 w-6" /> {isSuccess.children}
    </div>
  );
};
