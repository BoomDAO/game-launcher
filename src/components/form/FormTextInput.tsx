import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import Input, { InputProps } from "../ui/Input";
import FormErrorMessage from "./FormErrorMessage";
import FormWrapper from "./FormWrapper";

export type FormTextInputProps<T extends FieldValues> = InputProps &
  UseControllerProps<T>;

const FormTextInput = <T extends FieldValues>({
  control,
  name,
  className,
  ...rest
}: FormTextInputProps<T>) => {
  const {
    field,
    fieldState: { error },
  } = useController({
    name,
    control,
  });

  return (
    <FormWrapper>
      <Input
        {...field}
        className={cx(error && "form-error", className)}
        {...rest}
      />

      <FormErrorMessage>{error?.message}</FormErrorMessage>
    </FormWrapper>
  );
};

export default FormTextInput;
