import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import Checkbox, { CheckboxProps } from "../ui/Checkbox";
import FormErrorMessage from "./FormErrorMessage";
import FormWrapper from "./FormWrapper";

export type FormCheckboxProps<T extends FieldValues> = CheckboxProps &
  UseControllerProps<T>;

const FormCheckbox = <T extends FieldValues>({
  control,
  name,
  className,
  ...rest
}: FormCheckboxProps<T>) => {
  const {
    field: { value, ...restField },
    fieldState: { error },
  } = useController({
    name,
    control,
  });

  return (
    <FormWrapper>
      <Checkbox
        {...restField}
        className={cx(error && "form-error", className)}
        checked={value}
        {...rest}
      />

      <FormErrorMessage>{error?.message}</FormErrorMessage>
    </FormWrapper>
  );
};

export default FormCheckbox;
