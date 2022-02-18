import React, {useCallback, useState} from 'react';
import {useCombobox} from 'downshift';
import _debounce from 'lodash/debounce';
import {menuStyles} from './AcMenuStyles';

export default function GenericNameIdAutocomplete(
  {
    acText, setAcText, acID, setAcID, setAutoBlurred, supplyLookupList, nameFunc, idFunc,
    controlOptions: {htmlId, labelText, isRequired},
  },
) {
  const [inputItems, setInputItems] = useState([]);

  let lastItemText = '';

  // see https://stackoverflow.com/questions/36294134/lodash-debounce-with-react-input
  const debounceFN = useCallback(_debounce(wrapLookupList, 500), []);

  function wrapLookupList(qt) {
    supplyLookupList(qt).then((items) => {
      setInputItems(items);
    });
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
      if (!inputValue || inputValue.length < 3) {
        setInputItems([]);
        return;
      }
      debounceFN(inputValue);
    },
    onSelectedItemChange: ({selectedItem}) => {
      setAcID(idFunc(selectedItem));
      lastItemText = nameFunc(selectedItem);
      setAutoBlurred(true); // this indicates a blur so that it can trigger save or whatever action blur takes
    },
    itemToString: (item) => nameFunc(item),
  });

  return (
    <>
      <label
        {...getLabelProps()}
        className={`c-input__label ${(isRequired ? 'required' : '')}`}
        id={`label_${htmlId}`}
        htmlFor={htmlId}
      >
        {labelText}:
      </label>
      <div {...getComboboxProps()} aria-owns={`menu_${htmlId}`} style={{position: 'relative', display: 'flex'}}>
        <input
          className="c-input__text"
          {...getInputProps()}
          id={htmlId}
          style={{flex: 1}}
          value={acText}
          aria-controls={`menu_${htmlId}`}
          aria-labelledby={`label_${htmlId}`}
          onBlur={(e) => {
            /* workaround: We don't want to set blur unless relatedTarget exists as a good element.
                    It is null when clicking on an autocomplete menu and we don't want to trigger the autoBlur flag for that
                    */
            if (e.relatedTarget) {
              setAutoBlurred(true);
              closeMenu(); // by default this library leaves the menu open all over the page if you tab out
            }
          }}
        />
        { !acID && isRequired
          ? <span title={`${labelText} not found. Select the correct ${labelText} from the auto-complete list.`}>&#x2753;</span>
          : ''}
        <ul
          {...getMenuProps()}
          style={menuStyles}
          id={`menu_${htmlId}`}
          aria-labelledby={`label_${htmlId}`}
        >
          {isOpen
            && inputItems.map((item, index) => (
              <li
                style={
                      highlightedIndex === index ? {backgroundColor: '#bde4ff', marginBottom: '0.5em'} : {marginBottom: '0.5em'}
                    }
                key={idFunc(item)}
                {...getItemProps({item, index})}
              >
                {nameFunc(item)}
              </li>
            ))}
        </ul>
      </div>
    </>
  );
}
