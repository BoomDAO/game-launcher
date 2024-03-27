import { useTranslation } from "react-i18next";
import {
  ArrowLongLeftIcon,
  ArrowLongRightIcon,
} from "@heroicons/react/20/solid";
import { cx } from "@/utils";
import React from "react";

interface PaginationProps {
  totalNumbers: number;
  pageNumber: number;
  setPageNumber: (number: number) => void;
}

const MembersPagination = ({
  pageNumber,
  setPageNumber,
  totalNumbers,
}: PaginationProps) => {
  const { t } = useTranslation();
  const [pages, setPages] = React.useState(Array.from({ length: (totalNumbers >= 10) ? (Math.min((Math.ceil(pageNumber/10) * 10), totalNumbers) == totalNumbers ? totalNumbers % 10 : 10) : totalNumbers }).map((_, i) => {
    let expected_window = Math.ceil(pageNumber / 10);
    let start = ((expected_window - 1) * 10) + 1;
    let end = Math.min(totalNumbers, start + 9); 
    let index = ((expected_window - 1) * 10) + i;
    const page = index + 1;
    // const active = page === pageNumber;
    const active = false;
    return (
      <button
        key={index}
        onClick={() => setPageNumber(page)}
        className={cx(
          "inline-flex items-center rounded-primary px-4 py-2 text-sm font-medium leading-snug text-black hover:text-lightPrimary",
          "dark:text-white dark:hover:text-darkPrimary",
          active &&
          "bg-gray-200 text-lightPrimary dark:bg-white dark:text-darkPrimary",
        )}
      >
        {index + 1}
      </button>
    );
  }));
  const [current, setCurrent] = React.useState(pageNumber);

  const disabledPrevious = pageNumber <= 1;
  const disabledNext = pageNumber === totalNumbers;

  React.useEffect(() => {
    setPageNumber(current);
  }, [pages, current]);

  const onPreviousClick = () => {
    if (disabledPrevious) return;
    setPageNumber(pageNumber - 1);
  };
  const onNextClick = () => {
    if (disabledNext) return;
    setPageNumber(pageNumber + 1);
  };
  const onLeftWindowClick = () => {
    let expected_window = Math.ceil(pageNumber / 10) - 1;
    if (expected_window > 0) {
      let start = ((expected_window - 1) * 10) + 1;
      let end = Math.min((expected_window * 10), totalNumbers);
      if (end >= start) {
        setPages(Array.from({ length: (end - start + 1) }).map((_, i) => {
          const page = start;
          let index = ((expected_window - 1) * 10) + i;
          // const active = start === index + 1;
          const active = false;
          return (
            <button
              key={index}
              onClick={() => setPageNumber(index + 1)}
              className={cx(
                "inline-flex items-center rounded-primary px-4 py-2 text-sm font-medium leading-snug text-black hover:text-lightPrimary",
                "dark:text-white dark:hover:text-darkPrimary",
                active &&
                "bg-gray-200 text-lightPrimary dark:bg-white dark:text-darkPrimary",
              )}
            >
              {index + 1}
            </button>
          );
        }));
        setCurrent(start);
      };
    };
  };

  const onRightWindowClick = () => {
    let expected_window = Math.ceil(pageNumber / 10) + 1;
    let start = ((expected_window - 1) * 10) + 1;
    let end = Math.min(((expected_window + 1) * 10), totalNumbers);
    if (end >= start) {
      setPages(Array.from({ length: (end - start + 1) }).map((_, i) => {
        const page = start;
        let index = ((expected_window - 1) * 10) + i;
        // const active = start === index + 1;
        const active = false;
        return (
          <button
            key={index}
            onClick={() => setPageNumber(index + 1)}  
            className={cx(
              "inline-flex items-center rounded-primary px-4 py-2 text-sm font-medium leading-snug text-black hover:text-lightPrimary",
              "dark:text-white dark:hover:text-darkPrimary",
              active &&
              "bg-gray-200 text-lightPrimary dark:bg-white dark:text-darkPrimary",
            )}
          >
            {index + 1}
          </button>
        );
      }));
      setCurrent(start);
    };
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
        <button className="font-bold pb-2 pr-4 hover:text-lightPrimary" onClick={onLeftWindowClick}>. . .</button>
        { pages }
        <button className="font-bold pb-2 pl-4 hover:text-lightPrimary" onClick={onRightWindowClick}>. . .</button>
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

export default MembersPagination;
