import { cx } from "@/utils";
import { useNavigate } from "react-router-dom";

interface TabsProps {
  tabs: { name: string; id: number; url?: string; }[];
  active: number;
  setActive: (val: number) => void;
}

const VerticalTabs = ({ tabs, active, setActive }: TabsProps) => {
  const navigate = useNavigate();
  const activeItem = tabs.find((tab) => tab.id === active);

  return (
        <div className="border-black dark:border-white w-full">
          <div className="">
            {tabs.map((tab) => (
              <button
                onClick={() => {
                  setActive(tab.id);
                }}
                key={tab.id}
                className={cx(
                  activeItem === tab
                    ? "border-lightPrimary text-lightPrimary dark:border-darkPrimary dark:text-darkPrimary"
                    : "border-transparent text-gray-500 hover:border-gray-400 hover:text-gray-400",
                  "w-full pb-2 text-base font-medium text-left",
                )}
              >
                {tab.name}
              </button>
            ))}
          </div>
        </div>
  );
};

export default VerticalTabs;
