import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import TextArea, { TextAreaProps } from "../ui/TextArea";
import FormErrorMessage from "./FormErrorMessage";
import FormWrapper from "./FormWrapper";

export type FormTextTextAreaProps<T extends FieldValues> = TextAreaProps &
  UseControllerProps<T>;

const FormTextArea = <T extends FieldValues>({
  control,
  name,
  className,
  ...rest
}: FormTextTextAreaProps<T>) => {
  const {
    field,
    fieldState: { error },
  } = useController({
    name,
    control,
  });

  return (
    <FormWrapper>
      <TextArea
        {...field}
        className={cx(error && "border-error dark:border-error", className)}
        {...rest}
      />

      <FormErrorMessage>{error?.message}</FormErrorMessage>
    </FormWrapper>
  );
};

export default FormTextArea;
