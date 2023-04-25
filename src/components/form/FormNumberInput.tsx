import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import NumberInput, { InputProps } from "../ui/NumberInput";
import FormErrorMessage from "./FormErrorMessage";
import FormWrapper from "./FormWrapper";

export type FormNumberInputProps<T extends FieldValues> = InputProps &
  UseControllerProps<T>;

const FormNumberInput = <T extends FieldValues>({
  control,
  name,
  className,
  ...rest
}: FormNumberInputProps<T>) => {
  const {
    field,
    fieldState: { error },
  } = useController({
    name,
    control,
  });

  return (
    <FormWrapper>
      <NumberInput
        {...field}
        className={cx(error && "form-error", className)}
        {...rest}
      />

      <FormErrorMessage>{error?.message}</FormErrorMessage>
    </FormWrapper>
  );
};

export default FormNumberInput;
