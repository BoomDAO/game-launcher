import React from "react";
import { cx } from "@/utils";
import Button from "./Button";

interface UploadButtonProps {
  placeholder?: string;
  buttonText?: string;
}

const UploadButton = ({
  placeholder = "Upload file",
  buttonText = "Upload file",
}: UploadButtonProps) => {
  const [uploadName, setUploadName] = React.useState("");

  const hiddenFileInput = React.useRef<HTMLInputElement>(null);

  const handleClick = (e: React.MouseEvent<HTMLButtonElement, MouseEvent>) => {
    e.preventDefault();
    hiddenFileInput?.current?.click();
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e?.target?.files?.[0];
    if (!file) return;
    setUploadName(file.name);
  };

  return (
    <div className="flex w-full items-center justify-between rounded-primary border border-black px-8 py-[0.63rem] dark:border-white">
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
};

export default UploadButton;
