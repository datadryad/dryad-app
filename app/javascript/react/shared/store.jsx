import React, {
  createContext, useContext, useMemo, useState,
} from 'react';

const StoreContext = createContext();

export function StoreProvider({children, initialState = {}}) {
  const [storeState, setStoreState] = useState(initialState);

  const updateStore = (mergeObject) => {
    setStoreState((prevState) => ({...prevState, ...mergeObject}));
  };

  const contextValue = useMemo(
    () => ({storeState, updateStore}),
    [storeState, updateStore],
  );

  return (
    <StoreContext.Provider value={contextValue}>
      {children}
    </StoreContext.Provider>
  );
}

export const useStore = () => useContext(StoreContext);
