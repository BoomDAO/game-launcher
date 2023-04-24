import { cx } from "@/utils";

interface TabsProps {
  tabs: string[];
  active: string;
  setActive: (val: string) => void;
}

const Tabs = ({ tabs, active, setActive }: TabsProps) => {
  const activeItem = tabs.find((tab) => tab === active);

  return (
    <div className="mb-6">
      <div className="sm:hidden">
        <label htmlFor="tabs" className="sr-only">
          Select a tab
        </label>

        <select
          id="tabs"
          name="tabs"
          className="block w-full rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500"
          onChange={(e) => setActive(e.target.value)}
          defaultValue={activeItem}
        >
          {tabs.map((tab) => (
            <option key={tab} value={tab}>
              {tab}
            </option>
          ))}
        </select>
      </div>

      <div className="hidden sm:block">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex" aria-label="Tabs">
            {tabs.map((tab) => (
              <button
                onClick={() => setActive(tab)}
                key={tab}
                className={cx(
                  activeItem === tab
                    ? "border-lightPrimary text-lightPrimary dark:border-darkPrimary dark:text-darkPrimary"
                    : "border-transparent text-gray-500 hover:border-gray-400 hover:text-gray-400",
                  "w-1/4 border-b-2 py-4 px-1 text-center text-sm font-medium",
                )}
                aria-current={activeItem ? "page" : undefined}
              >
                {tab}
              </button>
            ))}
          </nav>
        </div>
      </div>
    </div>
  );
};

export default Tabs;
