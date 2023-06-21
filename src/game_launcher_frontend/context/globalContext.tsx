import React from "react";

interface GlobalContext {
  isOpenNavSidebar: boolean;
  setIsOpenNavSidebar: React.Dispatch<React.SetStateAction<boolean>>;
}

export const GlobalContext = React.createContext({} as GlobalContext);

export const GlobalContextProvider = ({
  children,
}: React.PropsWithChildren) => {
  const [isOpenNavSidebar, setIsOpenNavSidebar] = React.useState(false);

  const value = {
    isOpenNavSidebar,
    setIsOpenNavSidebar,
  };

  return (
    <GlobalContext.Provider value={value}>{children}</GlobalContext.Provider>
  );
};

export const useGlobalContext = () => React.useContext(GlobalContext);
