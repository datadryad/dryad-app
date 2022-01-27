import React, {useState} from 'react';
import {useCombobox} from 'downshift';
import {comboboxStyles, items, menuStyles} from './shared';
import axios from "axios";

export default function RorAutocomplete() {
  const [inputItems, setInputItems] = useState(items);
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
      const result = [];
      // URL = https://api.ror.org/organizations
      // query="name"
      axios.get('https://api.ror.org/organizations', { params: {query: "University of California"},
            headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'} } )
          .then((data) => {
            if (data.status !== 200) {
              console.log('Response failure not a 200 response');
            }else{
              // const myList = data.data.items.map((item) => item.name);
              const myList = data.data.items;
              console.log(myList);
              setInputItems(myList,)
            }
          });
      /*setInputItems(
          items.filter((item) =>
              item.toLowerCase().startsWith(inputValue.toLowerCase()),
          ),
      )*/
    },
    itemToString: (item) => item?.name || '',
  });

  return (
      <div>
        <label {...getLabelProps()}>Choose an element:</label>
        <div style={comboboxStyles} {...getComboboxProps()}>
          <input className='c-input__text' {...getInputProps()} />
          <button
              type="button"
              {...getToggleButtonProps()}
              aria-label="toggle menu"
          >
            &#8595;
          </button>
        </div>
        <ul {...getMenuProps()} style={menuStyles}>
          {isOpen &&
          inputItems.map((item, index) => (
              <li
                  {...getItemProps({item, index})}
                  style={
                    highlightedIndex === index ? {backgroundColor: '#bde4ff'} : {}
                  }
                  key={item.id}
              >
                {item.name}
              </li>
          ))}
        </ul>
      </div>
  );
};
