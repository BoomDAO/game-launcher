import React from "react";
import { GameFile, convertToBase64, cx, getGameFiles } from "@/utils";
import Button from "./Button";

export interface UploadButtonProps {
  placeholder?: string;
  buttonText?: string;
  uploadType?: "image" | "folder" | "zip";
  onUpload?: (file: GameFile[] | string) => void;
  className?: string;
}

const UploadButton = React.forwardRef<HTMLDivElement, UploadButtonProps>(
  (
    {
      placeholder = "Upload file",
      buttonText = "Upload file",
      uploadType = "image",
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
      if (uploadType === "image") {
        const file = e?.target?.files?.[0];
        if (!file) return;
        setUploadName(file.name);
        const base64 = await convertToBase64(file);
        onUpload && onUpload(base64);
      }

      if (uploadType === "folder") {
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
          /* @ts-expect-error */
          webkitdirectory={uploadType !== "folder" ? "true" : "false"}
        />
      </div>
    );
  },
);

export default UploadButton;
