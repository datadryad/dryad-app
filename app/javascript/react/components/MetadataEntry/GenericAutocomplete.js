import React, {useCallback, useState} from 'react';
import {useCombobox} from 'downshift';
import {menuStyles} from './shared';
import axios from "axios";
import _debounce from 'lodash/debounce';
import stringSimilarity from 'string-similarity';


export default function GenericAutocomplete({acText, setAcText, acID, setAcID, setAutoBlurred}) {
  const [inputItems, setInputItems] = useState([]);

  let lastItemText = '';

  // see https://stackoverflow.com/questions/36294134/lodash-debounce-with-react-input
  const debounceFN = useCallback(_debounce(supplyLookupList, 500), []);

  function supplyLookupList(qt) {
    axios.get('https://api.ror.org/organizations', { params: {query: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'} } )
        .then((data) => {
          if (data.status !== 200) {
            console.log('Response failure not a 200 response');
          }else{
            const myList = data.data.items;
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
    closeMenu,
  } = useCombobox({
    items: inputItems,
    onInputValueChange: ({inputValue}) => {
      setAcText(inputValue);
      if (inputValue !== lastItemText) {
        setAcID(''); // reset any identifiers if they've changed input text, but otherwise leave alone
      }
      // only autocomplete with 3 or more characters so as not to waste queries
      if (!inputValue || inputValue.length < 4){
        setInputItems([],);
        return;
      }
      debounceFN(inputValue);
    },
    onSelectedItemChange: ({selectedItem}) => {
      setAcID(selectedItem.id);
      lastItemText = stringItem(selectedItem);
      console.log(`lastItemText=${lastItemText}`);
    },
    itemToString: (item) => stringItem(item),
  });

  return (
      <>
        <label {...getLabelProps()} className="c-input__label required">Institutional Affiliation:</label>
        <div {...getComboboxProps()} style={{position: 'relative'}}>
          <input className='c-input__text' {...getInputProps()} value={acText}
                 onBlur={ () => {
                   setAutoBlurred(true);
                   closeMenu(); // by default this library leaves the menu open all over the page if you tab out
                 } }
          />
          {acID
              ? ''
              : <span title="Institution not found. Select it from the auto-complete list if it's available.">&#x2753;</span>
          }
          <ul {...getMenuProps()} style={menuStyles}>
            {isOpen &&
            inputItems.map((item, index) => (
                <li
                    style={
                      highlightedIndex === index ? {backgroundColor: '#bde4ff', marginBottom: '0.5em'} : { marginBottom: '0.5em' }
                    }
                    key={item.id}
                    {...getItemProps({item, index})}
                >
                  {item.name}
                </li>
            ))}
          </ul>
        </div>
      </>
  );
};
