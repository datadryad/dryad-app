import React, {useEffect, useRef, useState} from 'react';
import axios from 'axios';
import stringSimilarity from 'string-similarity';
import GenericNameIdAutocomplete from './GenericNameIdAutocomplete';

export default function RorAutocomplete({name, id, controlOptions}) {
  // control options: htmlId, labelText, isRequired (t/f)

  // label: id: downshift-0-label, for: downshift-0-input
  // box id: downshift-0-input, aria-labelledby: downshift-0-label
  // ul id: downshift-0-menu, aria-labeledby: downshift-0-label

  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs.
  // also tracking "autoBlurred" since we need to know when things exit to trigger form resubmission or sending to server.
  const [acText, setAcText] = useState(name);
  const [acID, setAcID] = useState(id);
  const [prevText, setPrevText] = useState(name);
  const [prevID, setPrevID] = useState(id);
  const [autoBlurred, setAutoBlurred] = useState(false);
  const nameRef = useRef(null);

  // do something when blurring from the autocomplete, passed up here, probably want to save on blur, but save
  // action may be different depending on autocomplete context inside another form or may save directly.
  useEffect(() => {
    if (autoBlurred) {
      if (!acText) {
        setAcID('');
      }
      /* it seems like the current way for this to work within authors is to add elements named
            "author[affiliation][long_name]" and "author[affiliation][ror_id]" that have correct values and resubmit
            the form.
           */
      if (prevText !== acText || prevID !== acID) {
        // only resubmit form when there are actual value changes
        $(nameRef.current.form).trigger('submit.rails');
        // console.log(nameRef.current.attr('form'));
      }
      setPrevText(acText);
      setPrevID(acID);
      setAutoBlurred(false);
    }
  }, [autoBlurred]);

  /* supplyLookupList returns a promise that will supply a list of js objects that
     can have their properties used to create the autocomplete list.
     It is required to be passed in so we can get lists from various data sources which may vary across different
     autocompletes for a generic case.
   */
  function supplyLookupList(qt) {
    return axios.get('https://api.ror.org/organizations', {
      params: {query: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    })
      .then((data) => {
        if (data.status !== 200) {
          // raise an error here if we want to catch it and display something to user or do something else
        } else {
          const list = data.data.items;
          for (const item of list) {
            // add string similarity rating to each object in the list
            item.similarity = stringSimilarity.compareTwoStrings(item.name, qt)
                  + (item.name.startsWith(qt) ? 1 : 0); // add one point if starts with the same string, send to top
          }
          list.sort((x, y) => ((x.similarity < y.similarity) ? 1 : -1));
          return list;
        }
      });
  }

  // Given a js object from list (supplyLookupList above) it returns the string name
  function nameFunc(item) {
    return (item?.name || '');
  }

  // Given a js object from list (supplyLookupList above) it returns the unique identifier
  function idFunc(item) {
    return item.id;
  }

  return (
    <>
      <GenericNameIdAutocomplete
        acText={acText || ''}
        setAcText={setAcText}
        acID={acID}
        setAcID={setAcID}
        setAutoBlurred={setAutoBlurred}
        supplyLookupList={supplyLookupList}
        nameFunc={nameFunc}
        idFunc={idFunc}
        controlOptions={controlOptions}
      />
      <input ref={nameRef} type="hidden" value={acText} name="author[affiliation][long_name]" />
      <input type="hidden" value={acID} name="author[affiliation][ror_id]" />
    </>
  );
}
