import {
  FieldValues,
  UseControllerProps,
  useController,
} from "react-hook-form";
import { cx } from "@/utils";
import TextArea, { TextAreaProps } from "../ui/TextArea";

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

  return <TextArea {...field} className={cx("", className)} {...rest} />;
};

export default FormTextArea;
