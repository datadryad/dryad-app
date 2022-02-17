import React, {useEffect, useState} from 'react';
import GenericAutocomplete from "./GenericAutocomplete";
import axios from "axios";
import stringSimilarity from "string-similarity";

export default function RorAutocomplete({name, id}) {
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs
  // which show lifting state in class components.  It's also simpler and clearer.

  const [acText, setAcText] = useState(name);
  const [acID, setAcID] = useState(id);
  const [autoBlurred, setAutoBlurred] = useState(false);

  // do something when blurring from the autocomplete, passed up here, probably want to save on blur, but save
  // action may be different depending on autocomplete context inside another form or may save directly.
  useEffect(() => {
        if(autoBlurred) {
          if(!acText){
            setAcID('');
          }
        };
        setAutoBlurred(false);
        /* it seems like the current way is to add these hidden fields to the authors form and submit that form
          author[affiliation][long_name]: Universidad de Congreso
          author[affiliation][ror_id]: https://ror.org/01tnfvr41
         */
      }, [autoBlurred]);

  /* supplyLookupList returns a promise that will supply a list of js objects that
     can have their properties used to create the autocomplete list.
     It is required to be passed in so we can get lists from various data sources.
   */
  function supplyLookupList(qt) {
    return axios.get('https://api.ror.org/organizations', { params: {query: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'} } )
        .then((data) => {
          if (data.status !== 200) {
            // raise an error here if we want to catch it and display something to user or do something else
          }else{
            const list = data.data.items;
            for (const item of list) {
              // add string similarity rating to each object in the list
              item.similarity = stringSimilarity.compareTwoStrings(item.name, qt) +
                  ( item.name.startsWith(qt) ? 1 : 0 ); // add one point if starts with the same string
            }
            list.sort((x, y) => (x.similarity < y.similarity) ? 1 : -1 );
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
          <GenericAutocomplete
              acText={acText || ''}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
              setAutoBlurred={setAutoBlurred}
              supplyLookupList={supplyLookupList}
              nameFunc={nameFunc}
              idFunc={idFunc}
          />
        { /* <p>Typed value is: {acText}</p>
        <p>Selected ID is: {acID}</p>
        <p>Blurred: {'' + autoBlurred}</p> */}
      </>
  )
}