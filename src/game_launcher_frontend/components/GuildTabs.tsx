import { cx } from "@/utils";

interface TabsProps {
  tabs: { name: string; id: number }[];
  active: number;
  setActive: (val: number) => void;
}

const GuildTabs = ({ tabs, active, setActive }: TabsProps) => {
  const activeItem = tabs.find((tab) => tab.id === active);

  return (
    <div className="mb-12">
      <div className="sm:hidden">
        <label htmlFor="tabs" className="sr-only">
          Select a tab
        </label>

        <select
          id="tabs"
          name="tabs"
          onChange={(e) => setActive(parseInt(e.target.value, 10))}
          defaultValue={activeItem?.name}
        >
          {tabs.map((tab) => (
            <option key={tab.id} value={tab.id}>
              {tab.name}
            </option>
          ))}
        </select>
      </div>

      <div className="hidden sm:block">
        <div className="">
          <nav className="flex" aria-label="Tabs">
            {tabs.map((tab) => (
              <button
                onClick={() => setActive(tab.id)}
                key={tab.id}
                className={cx(
                  activeItem === tab
                    ? " text-lightPrimary dark:border-darkPrimary dark:text-darkPrimary"
                    : "border-transparent text-gray-500 hover:border-gray-400 hover:text-gray-400",
                  "w-2/12 border-b-2 py-4 px-1 text-center text-sm font-medium",
                )}
                aria-current={activeItem ? "page" : undefined}
              >
                {tab.name}
              </button>
            ))}
          </nav>
        </div>
      </div>
    </div>
  );
};

export default GuildTabs;
