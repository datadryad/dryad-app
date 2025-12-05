import React, { createContext, useContext, useState } from "react";

const StoreContext = createContext();

export const StoreProvider = ({ children, initialState = {} }) => {
  const [storeState, setStoreState] = useState(initialState);

  const updateStore = (mergeObject) => {
    setStoreState((prevState) => ({ ...prevState, ...mergeObject }));
  }

  return (
    <StoreContext.Provider value={{ storeState, updateStore }}>
      {children}
    </StoreContext.Provider>
  );
}

export const useStore = () => useContext(StoreContext);
