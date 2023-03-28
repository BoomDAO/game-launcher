import React from "react";
import { Listbox } from "@headlessui/react";
import { ChevronUpDownIcon } from "@heroicons/react/20/solid";
import { cx } from "@/utils";

export type SelectOption = { value: string | number; label: string };

interface SelectProps {
  data: SelectOption[];
  placeholder?: string;
}

const Select = ({ data, placeholder = "Choose option" }: SelectProps) => {
  const [selected, setSelected] = React.useState<SelectOption>();

  return (
    <Listbox value={selected} onChange={setSelected}>
      {({ open }) => (
        <>
          <div className="relative w-full">
            <Listbox.Button
              className={cx(
                "relative w-full rounded-t-primary border border-black px-8 py-4 text-left dark:border-white",
                !open && "rounded-b-primary",
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
};

export default Select;
