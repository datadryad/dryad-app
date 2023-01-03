import React, {useEffect, useState} from 'react';
import axios from 'axios';
import stringSimilarity from 'string-similarity';
import PropTypes from 'prop-types';
import GenericNameIdAutocomplete from './GenericNameIdAutocomplete';

// the autocomplete name, autocomplete id (like ROR), formRef for parent form, get/set autocomplete Text, get/set autocomplete ID
export default function FunderAutocomplete({
  formRef, acText, setAcText, acID, setAcID, controlOptions, groupings,
}) {
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs.
  // also tracking "autoBlurred" since we need to know when things exit to trigger form resubmission or sending to server.
  const [prevText, setPrevText] = useState(acText);
  const [prevID, setPrevID] = useState(acID);
  const [autoBlurred, setAutoBlurred] = useState(false);
  const [showSelect, setShowSelect] = useState(null);

  // do something when blurring from the autocomplete, passed up here, probably want to save on blur, but save
  // action may be different depending on autocomplete context inside another form or may save directly.
  useEffect(() => {
    const group = groupings.find((g) => g.name_identifier_id === acID);
    if (group) {
      setShowSelect(group);
    } else {
      setShowSelect(null);
    }
    if (autoBlurred) {
      if (!acText) {
        setAcID('');
      }
      if (prevText !== acText || prevID !== acID) {
        // from the ref, submit the Formik form above me
        formRef.current.handleSubmit();
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
  const supplyLookupList = (qt) => axios.get('https://api.crossref.org/funders', {
    params: {query: qt},
    headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
  })
    .then((data) => {
      if (data.status !== 200) {
        return [];
        // raise an error here if we want to catch it and display something to user or do something else
      }

      const list = data.data.message.items.map((item) => {
        // add one point if starts with the same string, sends to top
        const similarity = stringSimilarity.compareTwoStrings(item.name, qt) + (item.name.startsWith(qt) ? 1 : 0);
        return {...item, similarity};
      });
      list.sort((x, y) => ((x.similarity < y.similarity) ? 1 : -1));
      // Add 'N/A' to the top of the list in case there is no funder
      const na_item = {id: 0, name: 'N/A', uri: '0'};
      list.unshift(na_item);
      return list;
    });

  // Given a js object from list (supplyLookupList above) it returns the string name
  const nameFunc = (item) => (item?.name || '');

  // Given a js object from list (supplyLookupList above) it returns the unique identifier
  const idFunc = (item) => item.uri;

  const subSelect = (e) => {
    const select = e.target;
    setAcID(select.value);
    setAcText(select.selectedOptions[0].text);
    setAutoBlurred(true);
    setShowSelect(null);
  };

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
      {showSelect && (
        <>
          <label htmlFor="subfunder_select" className="c-input__label" style={{marginTop: '1em'}}>{showSelect.group_label}</label>
          <select id="subfunder_select" className="c-input__select" onChange={subSelect}>
            <option value="">- Select one -</option>
            {showSelect.json_contains.map((i) => <option key={i.name_identifier_id} value={i.name_identifier_id}>{i.contributor_name}</option>)}
          </select>
        </>
      )}
    </>
  );
}

FunderAutocomplete.propTypes = {
  formRef: PropTypes.object.isRequired,
  acText: PropTypes.string.isRequired,
  setAcText: PropTypes.func.isRequired,
  acID: PropTypes.string.isRequired,
  setAcID: PropTypes.func.isRequired,
  controlOptions: PropTypes.object.isRequired,
};
