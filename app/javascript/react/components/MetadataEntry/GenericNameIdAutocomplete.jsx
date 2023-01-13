import React, {useCallback, useState, useRef} from 'react';
import {useCombobox} from 'downshift';
import {debounce} from 'lodash';
import PropTypes from 'prop-types';

/* This is kind of ugly, but is based on the parent component (more specific autocomplete details) defining some things
   and passing down details for it to work with.  The react docs I found suggested if something needed to be shared by
   components, to define at the higher level and pass down.

   passed in:
   acText, setAcText -- get/set the text for the autocompleted value (useState in React functional components)
   acID, setAcID -- get/set the Id that might go along with the text item
   setAutoBlurred -- the set half of a useState.  Component sets to true when blurred and parent component is responsible to save then
   supplyLookupList(query_terms) is a function passed in that will supply the autocomplete list when called as appropriate for parent
   nameFunc(item) is a function that returns the name for an item from the list
   idFunc(item) is a function that returns an id for an item from the list
   controlOptions: {
       htmlID -- the base unique ID used for this autocomplete component (should be unique on the page)
       labelText -- The label for the lookup (like "Institutional affiliation")
       isRequired -- boolean.  Makes the * for required fields and also shows warning "?" if no id gets filled for an item

       See the file RorAutocomplete.js for a real example.
 */
export default function GenericNameIdAutocomplete(
  {
    acText, setAcText, acID, setAcID, setAutoBlurred, supplyLookupList, nameFunc, idFunc,
    controlOptions: {htmlId, labelText, isRequired},
  },
) {
  const [inputItems, setInputItems] = useState([]);
  const [showError, setShowError] = useState(acText && !acID);
  const [textEnter, setTextEnter] = useState(acText && !acID);

  const completionClick = useRef(false);

  const clearErrors = () => {
    setTextEnter(false);
    setShowError(false);
  };

  const getInputItems = useCallback(debounce(async (qt) => {
    supplyLookupList(qt).then((items) => {
      setInputItems(items);
    });
  }, 200), []);

  const checkValues = (e) => {
    // check if text is in the id list
    const {children} = document.getElementById(e.currentTarget.getAttribute('aria-controls'));
    const match = children.namedItem(acText);
    if (match) {
      setAcID(match.id);
      clearErrors();
      setAutoBlurred(true);
    } else if (isRequired) {
      setShowError(true);
    } else {
      setAutoBlurred(true);
    }
  };

  const saveText = (e) => {
    setTextEnter(e.currentTarget.checked);
    setAutoBlurred(true);
  };

  const {
    isOpen,
    getLabelProps,
    getMenuProps,
    getInputProps,
    getComboboxProps,
    highlightedIndex,
    getItemProps,
  } = useCombobox({
    items: inputItems,
    onInputValueChange: ({inputValue}) => {
      // reset information if they've changed input text, but otherwise leave alone
      if (acText !== inputValue) {
        setAcText(inputValue);
        setAcID('');
      }
      // only autocomplete with 3 or more characters so as not to waste queries
      if (inputValue?.length > 3) {
        getInputItems(inputValue);
      } else {
        setInputItems([]);
      }
    },
    onSelectedItemChange: ({selectedItem}) => {
      setAcID(idFunc(selectedItem));
      setAcText(nameFunc(selectedItem));
      setAutoBlurred(true); // this notifies parent component to save
      clearErrors();
    },
    itemToString: (item) => nameFunc(item),
  });

  return (
    <>
      { labelText
        ? (
          <label
            {...getLabelProps()}
            className={`c-input__label ${(isRequired ? 'required' : '')}`}
            id={`label_${htmlId}`}
            htmlFor={htmlId}
          >
            {labelText}:
          </label>
        ) : '' }
      <div
        {...getComboboxProps()}
        aria-owns={`menu_${htmlId}`}
        className="c-auto_complete"
      >
        <input
          className="c-input__text c-ac__input"
          {...getInputProps(
            {
              onBlur: (e) => {
                document.getElementById(`menu_${htmlId}`).blur();
                if (completionClick.current) {
                  // don't fire a save after a mousedown state set on clicking a completion item, it's not a real blur
                  completionClick.current = false;
                } else if (acText && !acID) {
                  checkValues(e);
                } else {
                  clearErrors();
                  setAutoBlurred(true); // set this to notify the parent component to save or do whatever
                }
              },
            },
          )}
          id={htmlId}
          style={{flex: 1}}
          value={acText || ''}
          aria-controls={`menu_${htmlId}`}
          aria-labelledby={`label_${htmlId}`}
          aria-invalid={showError && !textEnter}
          aria-errormessage={`error_${htmlId}`}
        />
        { !acID && isRequired
          ? (
            <span
              className="is__required"
              title={`${labelText} not found. Select the correct item from the auto-complete list. `
                      + `${(labelText === 'Granting organization') ? 'If no funding is applicable, check the box below.' : ''}`}
            >&#x2753;
            </span>
          )
          : ''}
        <ul
          {...getMenuProps()}
          className="c-ac__menu"
          id={`menu_${htmlId}`}
          aria-labelledby={`label_${htmlId}`}
        >
          {isOpen
            && inputItems.map((item, index) => {
              const id = idFunc(item);
              const name = nameFunc(item);
              return (
                <li
                  key={id}
                  name={name}
                  className={`c-ac__menu_item ${highlightedIndex === index ? 'highlighted' : ''}`}
                  {...getItemProps({
                    item, index, id, onMouseDown: () => { completionClick.current = true; },
                  })}
                >
                  {name}
                </li>
              );
            })}
        </ul>
      </div>
      {showError && (
        <>
          {!textEnter && (
            <span className="c-ac__error_message" id={`error_${htmlId}`}>Please select an item from the list, or check the box below</span>
          )}
          <label className="c-input__label c-ac__checkbox">
            <input type="checkbox" className="use-text-entered" checked={textEnter} onChange={saveText} />
            {` I cannot find my ${labelText.toLowerCase()}, "${acText}", in the list`}
          </label>
        </>
      )}
    </>
  );
}

GenericNameIdAutocomplete.propTypes = {
  acText: PropTypes.string.isRequired,
  setAcText: PropTypes.func.isRequired,
  acID: PropTypes.string.isRequired,
  setAcID: PropTypes.func.isRequired,
  setAutoBlurred: PropTypes.func.isRequired,
  supplyLookupList: PropTypes.func.isRequired,
  nameFunc: PropTypes.func.isRequired,
  idFunc: PropTypes.func.isRequired,
  controlOptions: PropTypes.object.isRequired,
};
