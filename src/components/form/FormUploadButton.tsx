import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { GameFile, cx } from "@/utils";
import UploadButton, { UploadButtonProps } from "../ui/UploadButton";
import FormErrorMessage from "./FormErrorMessage";
import FormWrapper from "./FormWrapper";

export type FormUploadButtonProps<T extends FieldValues> = UploadButtonProps &
  UseControllerProps<T>;

const FormUploadButton = <T extends FieldValues>({
  control,
  name,
  className,
  onUpload,
  uploadType = "image",
  ...rest
}: FormUploadButtonProps<T>) => {
  const {
    field: { onChange: fieldChange, ...restField },
    fieldState: { error },
  } = useController({
    name,
    control,
  });

  const onChange = (file: GameFile[] | string) => {
    if (uploadType === "image") return fieldChange(file);
    return;
  };

  return (
    <FormWrapper>
      <UploadButton
        {...restField}
        className={cx(error && "border-error dark:border-error")}
        onUpload={onChange}
        uploadType={uploadType}
        {...rest}
      />

      <FormErrorMessage>{error?.message}</FormErrorMessage>
    </FormWrapper>
  );
};

export default FormUploadButton;
