import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import Select, { SelectOption, SelectProps } from "../ui/Select";
import FormErrorMessage from "./FormErrorMessage";
import FormWrapper from "./FormWrapper";

export type FormSelectInputProps<T extends FieldValues> = SelectProps &
  UseControllerProps<T>;

const FormSelect = <T extends FieldValues>({
  control,
  name,
  className,
  onValueChange,
  ...rest
}: FormSelectInputProps<T>) => {
  const {
    field: { onChange: fieldChange, ...restField },
    fieldState: { error },
  } = useController({
    name,
    control,
  });

  const onChange = ({ value }: SelectOption) => fieldChange(value);

  return (
    <FormWrapper>
      <Select
        {...restField}
        onValueChange={onChange}
        className={cx(error && "border-error dark:border-error", className)}
        {...rest}
      />

      <FormErrorMessage>{error?.message}</FormErrorMessage>
    </FormWrapper>
  );
};

export default FormSelect;
