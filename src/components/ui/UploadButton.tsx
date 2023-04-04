import React from "react";
import { GameFile } from "@/types";
import { convertToBase64, cx, getGameFiles } from "@/utils";
import Button from "./Button";
import Hint from "./Hint";

export interface UploadButtonProps {
  placeholder?: string;
  buttonText?: string;
  uploadType?: "image" | "folder" | "zip";
  onUpload?: (file: GameFile[] | string) => void;
  className?: string;
  disabled?: boolean;
  setDisableSubmit?: (val: boolean) => void;
  hint?: {
    body: React.ReactNode;
    right?: boolean;
  };
}

const UploadButton = React.forwardRef<HTMLDivElement, UploadButtonProps>(
  (
    {
      placeholder = "Upload file",
      buttonText = "Upload file",
      uploadType = "image",
      className,
      onUpload,
      disabled,
      setDisableSubmit,
      hint,
    },
    ref,
  ) => {
    const [isLoading, setIsLoading] = React.useState(false);
    const [uploadName, setUploadName] = React.useState("");

    const hiddenFileInput = React.useRef<HTMLInputElement>(null);

    const onLoading = (val: boolean) => {
      setIsLoading(val);
      setDisableSubmit && setDisableSubmit(val);
    };

    const handleClick = (
      e: React.MouseEvent<HTMLButtonElement, MouseEvent>,
    ) => {
      e.preventDefault();
      hiddenFileInput?.current?.click();
    };

    const handleChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
      onLoading(true);
      if (uploadType === "image") {
        const file = e?.target?.files?.[0];
        if (!file) return;
        setUploadName(file.name);
        const base64 = await convertToBase64(file);
        onUpload && onUpload(base64);
      }

      if (uploadType === "folder" || uploadType === "zip") {
        const { files } = e.target;
        if (!files?.length) return;
        setUploadName(`${files?.length} files to upload`);

        const gameFiles: GameFile[] = [];

        for await (const file of files) {
          const gameFile = await getGameFiles(file);
          gameFiles.push(gameFile);
        }

        onUpload && onUpload(gameFiles);
      }

      onLoading(false);
    };

    return (
      <div
        ref={ref}
        className={cx(
          "flex w-full items-center justify-between rounded-primary border border-black px-6 py-[0.63rem] dark:border-white",
          disabled && "border-gray-400 dark:border-gray-600",
          className,
        )}
      >
        <div className={cx(!uploadName && "text-gray-500")}>
          {uploadName || placeholder}
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={handleClick} disabled={disabled || isLoading}>
            {isLoading ? "Uploading" : buttonText}
          </Button>
          {!!hint && <Hint right={hint.right}>{hint.body}</Hint>}
        </div>
        <input
          type="file"
          ref={hiddenFileInput}
          onChange={handleChange}
          className="hidden"
          disabled={disabled}
          accept={uploadType === "zip" ? ".zip,.rar,.7zip" : undefined}
          /* @ts-expect-error */
          webkitdirectory={uploadType === "folder" ? "true" : undefined}
        />
      </div>
    );
  },
);

export default UploadButton;
