import React, {useCallback, useState} from 'react';
import {useCombobox} from 'downshift';
import {comboboxStyles, menuStyles} from './shared';
import axios from "axios";
import _debounce from 'lodash/debounce';
import stringSimilarity from 'string-similarity';

export default function RorAutocomplete() {
  const [inputItems, setInputItems] = useState([]);

  // see https://stackoverflow.com/questions/36294134/lodash-debounce-with-react-input
  const debounceFN = useCallback(_debounce(supplyLookupList, 500), []);

  function supplyLookupList(qt) {
    axios.get('https://api.ror.org/organizations', { params: {query: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'} } )
        .then((data) => {
          if (data.status !== 200) {
            console.log('Response failure not a 200 response');
          }else{
            // const myList = data.data.items.map((item) => item.name);
            const myList = data.data.items;
            console.log(myList);
            setInputItems(sortSimilarity(myList, stringItem, qt), );
          }
        });
  }

  function stringItem(item){
    return (item?.name || '');
  }

  function sortSimilarity(list, itemToStringFN, typedValue){
    for (const item of list) {
      item.similarity = stringSimilarity.compareTwoStrings(itemToStringFN(item), typedValue);
    }

    list.sort((x, y) => (x.similarity < y.similarity) ? 1 : -1 );

    return list;
  }

  const {
    isOpen,
    getToggleButtonProps,
    getLabelProps,
    getMenuProps,
    getInputProps,
    getComboboxProps,
    highlightedIndex,
    getItemProps,
  } = useCombobox({
    items: inputItems,
    onInputValueChange: ({inputValue}) => {
      // only autocomplete with 3 or more characters so as not to waste queries
      if (!inputValue || inputValue.length < 4){
        setInputItems([],);
        return;
      }
      debounceFN(inputValue);
    },
    itemToString: (item) => stringItem(item),
  });

  return (
      <div>
        <label {...getLabelProps()}>Choose an element:</label>
        <div style={comboboxStyles} {...getComboboxProps()}>
          <input className='c-input__text' {...getInputProps()} />
        </div>
        <ul {...getMenuProps()} style={menuStyles}>
          {isOpen &&
          inputItems.map((item, index) => (
              <li
                  style={
                    highlightedIndex === index ? {backgroundColor: '#bde4ff'} : {}
                  }
                  key={item.id}
                  {...getItemProps({item, index})}
              >
                {item.name}
              </li>
          ))}
        </ul>
      </div>
  );
};
