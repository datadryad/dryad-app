import React, {useEffect, useState} from 'react';
import GenericAutocomplete from "./GenericAutocomplete";

export default function RorAutocomplete() {
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs
  // which show lifting state in class components.  It's also simpler and clearer.

  const [acText, setAcText] = useState();
  const [acID, setAcID] = useState();
  const [autoBlurred, setAutoBlurred] = useState(false);

  // do something when blurring from the autocomplete, passed up here
  useEffect(() => {
        if(autoBlurred) {
          if(!acText){
            setAcID('');
          }
          console.log('blurred away from input!');
        };
        setAutoBlurred(false);
      }, [autoBlurred]);

  return (
      <>
        <div className="c-input">
          <GenericAutocomplete acText={acText || ''} setAcText={setAcText} acID={acID} setAcID={setAcID} setAutoBlurred={setAutoBlurred} />
        </div>
        <p>Typed value is: {acText}</p>
        <p>Selected ID is: {acID}</p>
        <p>Blurred: {'' + autoBlurred}</p>
      </>
  )
}