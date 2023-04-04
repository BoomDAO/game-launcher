import React from "react";
import { Popover } from "@headlessui/react";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
import { cx } from "@/utils";

interface HintProps {
  right?: boolean;
}

const Hint = ({ children, right }: React.PropsWithChildren<HintProps>) => {
  return (
    <Popover className="relative leading-none">
      <Popover.Button>
        <InformationCircleIcon className="h-7 w-7 text-info" />
      </Popover.Button>

      <Popover.Panel
        className={cx(
          "absolute z-10 w-[300px] rounded-primary bg-info p-6 text-white shadow-md md:w-[364px]",
          right ? "-left-4" : "-right-4",
        )}
      >
        {children}
      </Popover.Panel>
    </Popover>
  );
};

export default Hint;
