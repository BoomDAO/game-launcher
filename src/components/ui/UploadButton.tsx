import React from "react";
import { convertToBase64, cx } from "@/utils";
import Button from "./Button";

export interface UploadButtonProps {
  placeholder?: string;
  buttonText?: string;
  imageUpload?: boolean;
  onUpload?: (file: File | string) => void;
  className?: string;
}

const UploadButton = React.forwardRef<HTMLDivElement, UploadButtonProps>(
  (
    {
      placeholder = "Upload file",
      buttonText = "Upload file",
      imageUpload,
      className,
      onUpload,
    },
    ref,
  ) => {
    const [uploadName, setUploadName] = React.useState("");

    const hiddenFileInput = React.useRef<HTMLInputElement>(null);

    const handleClick = (
      e: React.MouseEvent<HTMLButtonElement, MouseEvent>,
    ) => {
      e.preventDefault();
      hiddenFileInput?.current?.click();
    };

    const handleChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e?.target?.files?.[0];
      if (!file) return;
      setUploadName(file.name);

      let toReturn: File | string = file;
      if (imageUpload) toReturn = await convertToBase64(file);

      onUpload && onUpload(toReturn);
    };

    return (
      <div
        ref={ref}
        className={cx(
          "flex w-full items-center justify-between rounded-primary border border-black px-8 py-[0.63rem] dark:border-white",
          className,
        )}
      >
        <div className={cx(!uploadName && "text-gray-500")}>
          {uploadName || placeholder}
        </div>
        <Button onClick={handleClick}>{buttonText}</Button>
        <input
          type="file"
          ref={hiddenFileInput}
          onChange={handleChange}
          className="hidden"
        />
      </div>
    );
  },
);

export default UploadButton;
