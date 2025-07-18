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
       saveOnEnter -- boolean. Saves input field entered text when enter key is pressed.

       See the file RorAutocomplete.js for a real example.
 */
export default function Autocomplete(
  {
    acText, setAcText, acID, setAcID, setAutoBlurred, supplyLookupList, nameFunc, idFunc,
    controlOptions: {
      htmlId, labelText, desBy, isRequired, errorId, saveOnEnter,
    },
  },
) {
  const [inputItems, setInputItems] = useState([]);
  const [status, setStatus] = useState(null);
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
      setStatus(items.length > 0 ? 'Results loaded' : 'Loading results');
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
    if (acText === '') setInputItems([]);
  };

  const saveText = (e) => {
    setTextEnter(e.currentTarget.checked);
    setAutoBlurred(true);
    if (acText === '') setInputItems([]);
  };

  const {
    isOpen,
    openMenu,
    getLabelProps,
    getMenuProps,
    getInputProps,
    getComboboxProps,
    highlightedIndex,
    getItemProps,
  } = useCombobox({
    items: inputItems,
    onSelectedItemChange: ({selectedItem}) => {
      setAcID(idFunc(selectedItem));
      setAcText(nameFunc(selectedItem));
      setAutoBlurred(true); // this notifies parent component to save
      if (acText === '') setInputItems([]);
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
            className={`input-label ${(isRequired ? 'required' : 'optional')}`}
            id={`label_${htmlId}`}
            htmlFor={htmlId}
          >
            {labelText}
          </label>
        ) : '' }
      <div
        {...getComboboxProps()}
        aria-controls={`menu_${htmlId}`}
        className="searchselect"
        aria-errormessage={errorId || null}
        aria-label={`${labelText ? `${labelText} s` : 'S'}earch + select`}
        aria-describedby={desBy || null}
      >
        <input
          className="c-input__select"
          {...getInputProps(
            {
              onFocus: (e) => {
                const {value} = e.target;
                if (value?.length >= 3) {
                  getInputItems(value);
                }
                if (!isOpen) {
                  openMenu();
                  setStatus(inputItems.length > 0 ? 'Results loaded' : 'Loading results');
                }
              },
              onBlur: (e) => {
                if (completionClick.current) {
                  // don't fire a save after a mousedown state set on clicking a completion item, it's not a real blur
                  completionClick.current = false;
                } else if (acText && !acID) {
                  checkValues(e);
                } else {
                  clearErrors();
                  setAutoBlurred(true); // set this to notify the parent component to save or do whatever
                  if (acText === '') setInputItems([]);
                }
              },
              onChange: (e) => {
                const {value} = e.target;
                // reset information if they've changed input text, but otherwise leave alone
                if (acText !== value) {
                  setAcText(value);
                  setAcID('');
                  setTextEnter(false);
                }
                // only autocomplete with 3 or more characters so as not to waste queries
                if (value?.length >= 3) {
                  getInputItems(value);
                } else {
                  setInputItems([]);
                }
              },
              onKeyDown: (e) => {
                if (saveOnEnter && highlightedIndex < 0 && e.key === 'Enter') {
                  setAutoBlurred(true);
                  if (acText === '') setInputItems([]);
                }
              },
            },
          )}
          id={htmlId}
          style={{flex: 1}}
          value={acText || ''}
          aria-controls={`menu_${htmlId}`}
          aria-labelledby={`label_${htmlId}`}
          aria-invalid={showError && !textEnter ? 'true' : null}
          aria-errormessage={`error_${htmlId}`}
          placeholder="Find as you type..."
        />
        <span className="screen-reader-only" id={`label_${htmlId}_list`}>{`${labelText ? `${labelText} a` : 'A'}utocomplete list`}</span>
        <ul
          {...getMenuProps()}
          id={`menu_${htmlId}`}
          aria-labelledby={`label_${htmlId}_list`}
          tabIndex={-1}
          hidden={!isOpen}
        >
          {!inputItems.length && <li><i className="fas fa-circle-notch fa-spin" aria-hidden="true" /></li>}
          {inputItems.map((item, index) => {
            const id = idFunc(item);
            const name = nameFunc(item);
            const Display = () => item.display;
            return (
              <li
                key={id}
                name={name}
                className={`${highlightedIndex === index ? 'focussed' : ''} ${id === acID ? 'selected-option' : ''}`}
                {...getItemProps({
                  item, index, id, 'aria-selected': id === acID, onMouseDown: () => { completionClick.current = true; },
                })}
              >
                {item.display ? <Display key={name} /> : name}
              </li>
            );
          })}
        </ul>
      </div>
      {showError && (
        <>
          {!textEnter && (
            <span className="c-ac__error_message" id={`error_${htmlId}`}>
              Search and select from the dropdown list, or check the box below
            </span>
          )}
          <label className="c-input__label c-ac__checkbox">
            <input type="checkbox" className="use-text-entered" checked={textEnter} onChange={saveText} />
            {` I cannot find my ${labelText?.toLowerCase() || 'item'}, "${acText}", in the list`}
          </label>
        </>
      )}
      <span className="screen-reader-only" role="status">{status}</span>
    </>
  );
}

Autocomplete.propTypes = {
  acText: PropTypes.string.isRequired,
  setAcText: PropTypes.func.isRequired,
  acID: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  setAcID: PropTypes.func.isRequired,
  setAutoBlurred: PropTypes.func.isRequired,
  supplyLookupList: PropTypes.func.isRequired,
  nameFunc: PropTypes.func.isRequired,
  idFunc: PropTypes.func.isRequired,
  controlOptions: PropTypes.object.isRequired,
};
