import React, {useEffect, useRef, useState} from 'react';
import axios from 'axios';
import stringSimilarity from 'string-similarity';
import PropTypes from 'prop-types';
import GenericNameIdAutocomplete from './GenericNameIdAutocomplete';

export default function KeywordAutocomplete({
  name, id, saveFunction, controlOptions,
}) {
  // control options: htmlId, labelText, isRequired (t/f)

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
      if (prevText !== acText || prevID !== acID) {
        saveFunction(acText);
        setAcText('');
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
    return axios.get('/stash_datacite/subjects/autocomplete', {
      params: {term: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    })
      .then((data) => {
        if (data.status !== 200) {
          return [];
          // raise an error here if we want to catch it and display something to user or do something else
        }

        const list = data.data.map((item) => {
          // add one point if starts with the same string, sends to top
          const similarity = stringSimilarity.compareTwoStrings(item.name, qt) + (item.name.startsWith(qt) ? 1 : 0);
          return {...item, similarity};
        });
        list.sort((x, y) => ((x.similarity < y.similarity) ? 1 : -1));
        return list;
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

  /* eslint-disable react/jsx-no-bind */
  // I'm passing in functions for getting name, id and lookup list.  None require any state from this component and are static functions
  // eslint hates it, but what's the point of higher order functions or passing functions to separate concerns if you can't use it?
  // I don't think this is actually a problem and if it causes re-loading of functions, IDK what a good alternative is.
  // The information I can find regarding why not to pass a function through props in react is conflicting and unclear and
  // in fact some sources say to do it to avoid repeating components (like https://www.youtube.com/watch?v=yH5Z-lSeV9Y ).
  // So IDK what the real guidance is for this and it seems to work fine.
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
      <input ref={nameRef} type="hidden" value={acText} className="js-affil-longname" name="author[affiliation][long_name]" />
      <input type="hidden" value={acID} className="js-affil-id" name="author[affiliation][ror_id]" />
    </>
  );
  /* eslint-enable react/jsx-no-bind */
}

KeywordAutocomplete.propTypes = {
  name: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  saveFunction: PropTypes.func.isRequired,
  controlOptions: PropTypes.object.isRequired,
};
