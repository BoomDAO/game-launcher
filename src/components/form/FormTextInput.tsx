import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import Input, { InputProps } from "../ui/Input";

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

  return <Input {...field} className={cx("", className)} {...rest} />;
};

export default FormTextInput;
