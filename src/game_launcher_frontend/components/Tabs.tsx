import { cx } from "@/utils";
import { useNavigate } from "react-router-dom";

interface TabsProps {
  tabs: { name: string; id: number; url?: string; }[];
  active: number;
  setActive: (val: number) => void;
}

const Tabs = ({ tabs, active, setActive }: TabsProps) => {
  const navigate = useNavigate();
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
          onChange={(e) => { setActive(parseInt(e.target.value, 10)) }}
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
        <div className="border-b border-black dark:border-white">
          <nav className="-mb-px flex" aria-label="Tabs">
            {tabs.map((tab) => (
              <button
                onClick={() => {
                  setActive(tab.id); if (tab.url) {
                    navigate(tab.url);
                  }
                }}
                key={tab.id}
                className={cx(
                  activeItem === tab
                    ? "border-lightPrimary text-lightPrimary dark:border-darkPrimary dark:text-darkPrimary"
                    : "border-transparent text-gray-500 hover:border-gray-400 hover:text-gray-400",
                  "w-1/4 border-b-2 py-4 px-1 text-center text-sm font-medium",
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

export default Tabs;
