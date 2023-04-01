import { Toaster, resolveValue } from "react-hot-toast";
import {
  CheckCircleIcon,
  ExclamationCircleIcon,
  XCircleIcon,
} from "@heroicons/react/24/solid";
import { cx } from "@/utils";

const Toast = () => {
  return (
    <Toaster
      position="top-right"
      reverseOrder={false}
      toastOptions={{ duration: 5000 }}
    >
      {(toast) => {
        let icon = <ExclamationCircleIcon className="w-5" />;

        if (toast.type === "error") {
          icon = <XCircleIcon className="w-5" />;
        }
        if (toast.type === "success") {
          icon = <CheckCircleIcon className="w-5" />;
        }

        return (
          <div
            className={cx(
              "flex w-full max-w-md items-center gap-4 rounded-primary bg-yellow-500 py-4 px-6 text-white shadow-lg transition-all ease-in-out hover:bg-opacity-90",
              toast.type === "success" && "bg-success",
              toast.type === "error" && "bg-error",
            )}
          >
            <div>{icon}</div>
            <div>{resolveValue(toast.message, toast)}</div>
          </div>
        );
      }}
    </Toaster>
  );
};

export default Toast;
