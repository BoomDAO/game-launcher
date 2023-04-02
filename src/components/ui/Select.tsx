import React from "react";
import { Listbox } from "@headlessui/react";
import { ChevronUpDownIcon } from "@heroicons/react/20/solid";
import { cx } from "@/utils";

export type SelectOption = { value: string | number; label: string };

export interface SelectProps {
  data: SelectOption[];
  placeholder?: string;
  className?: string;
  onValueChange?: (value: SelectOption) => void;
  value?: string | number;
  disabled?: boolean;
}

const Select = React.forwardRef<HTMLElement, SelectProps>(
  (
    {
      data,
      placeholder = "Choose option",
      className,
      onValueChange,
      value,
      disabled,
    },
    ref,
  ) => {
    const onChange = (value: SelectOption) => {
      onValueChange && onValueChange(value);
    };

    const selected = React.useMemo(() => {
      if (!value) return undefined;
      const find = data.find((item) => item.value === value);
      return find;
    }, [value]);

    return (
      <Listbox
        ref={ref}
        value={selected}
        onChange={onChange}
        disabled={disabled}
      >
        {({ open, disabled }) => (
          <>
            <div className="relative w-full">
              <Listbox.Button
                className={cx(
                  "relative w-full rounded-t-primary border border-black px-8 py-4 text-left dark:border-white",
                  !open && "rounded-b-primary",
                  disabled && "border-gray-400 dark:border-gray-600",
                  className,
                )}
              >
                <span
                  className={cx("block truncate", !selected && "text-gray-500")}
                >
                  {selected?.label || placeholder}
                </span>
                <span className="pointer-events-none absolute inset-y-0 right-4 flex items-center pr-2">
                  <ChevronUpDownIcon
                    className="h-5 w-5 text-dark dark:text-white"
                    aria-hidden="true"
                  />
                </span>
              </Listbox.Button>

              <Listbox.Options className="absolute z-10 max-h-60 w-full overflow-auto rounded-b-primary border border-t-0 border-black bg-white py-4 shadow-lg focus:outline-none dark:border-white dark:bg-dark">
                {data.map((option) => (
                  <Listbox.Option
                    key={option.value}
                    className={({ active }) =>
                      cx(
                        "relative cursor-default select-none py-2 pl-8 pr-9",
                        active &&
                          "bg-lightPrimary text-white dark:bg-darkPrimary",
                      )
                    }
                    value={option}
                  >
                    {({ selected }) => (
                      <span
                        className={cx(
                          "block truncate",
                          selected ? "font-semibold" : "font-normal",
                        )}
                      >
                        {option.label}
                      </span>
                    )}
                  </Listbox.Option>
                ))}
              </Listbox.Options>
            </div>
          </>
        )}
      </Listbox>
    );
  },
);

export default Select;
