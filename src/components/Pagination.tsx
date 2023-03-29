import { useTranslation } from "react-i18next";
import {
  ArrowLongLeftIcon,
  ArrowLongRightIcon,
} from "@heroicons/react/20/solid";
import { cx } from "@/utils";

interface PaginationProps {
  totalNumbers: number;
  pageNumber: number;
  setPageNumber: (number: number) => void;
}

const Pagination = ({
  pageNumber,
  setPageNumber,
  totalNumbers,
}: PaginationProps) => {
  const { t } = useTranslation();

  const disabledPrevious = pageNumber <= 1;
  const disabledNext = pageNumber === totalNumbers;

  const onPreviousClick = () => {
    if (disabledPrevious) return;
    setPageNumber(pageNumber - 1);
  };
  const onNextClick = () => {
    if (disabledNext) return;
    setPageNumber(pageNumber + 1);
  };

  return (
    <nav className="mt-8 flex items-center justify-between px-4 sm:px-0">
      <div className="-mt-px flex w-0 flex-1">
        <button
          disabled={disabledPrevious}
          onClick={onPreviousClick}
          className={cx(
            "inline-flex items-center border-t-2 border-transparent pr-1 pt-4 text-sm font-medium text-black hover:text-lightPrimary",
            "dark:text-white hover:dark:text-darkPrimary",
            "disabled:text-gray-400 dark:disabled:text-gray-600",
          )}
        >
          <ArrowLongLeftIcon className="mr-3 h-5 w-5" aria-hidden="true" />
          {t("previous")}
        </button>
      </div>
      <div className="hidden md:-mt-px md:flex">
        {Array.from({ length: totalNumbers }).map((_, i) => {
          const page = i + 1;
          const active = page === pageNumber;

          return (
            <button
              onClick={() => setPageNumber(page)}
              className={cx(
                "inline-flex items-center rounded-primary px-4 py-2 text-sm font-medium leading-snug text-black hover:text-lightPrimary",
                "dark:text-white dark:hover:text-darkPrimary",
                active && "bg-white text-lightPrimary dark:text-darkPrimary",
              )}
            >
              {i + 1}
            </button>
          );
        })}
      </div>
      <div className="-mt-px flex w-0 flex-1 justify-end">
        <button
          disabled={disabledNext}
          onClick={onNextClick}
          className={cx(
            "inline-flex items-center pl-1 pt-4 text-sm font-medium text-black hover:text-lightPrimary",
            "dark:text-white hover:dark:text-darkPrimary",
            "disabled:text-gray-400 dark:disabled:text-gray-600",
          )}
        >
          {t("next")}
          <ArrowLongRightIcon className="ml-3 h-5 w-5" aria-hidden="true" />
        </button>
      </div>
    </nav>
  );
};

export default Pagination;
