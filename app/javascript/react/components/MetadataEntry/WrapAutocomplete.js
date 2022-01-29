import React, {useState} from 'react';
import RorAutocomplete from "./RorAutocomplete";

export default function WrapAutocomplete() {
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs
  // which show lifting state in class components.  It's also simpler and clearer.

  const [acText, setAcText] = useState();
  const [acID, setAcID] = useState();
  const [autoBlurred, setAutoBlurred] = useState(false);

  // do something when blurring from the autocomplete, passed up here
  /*
  useEffect(() => {
        alert('blur changed!');
      }, [blurred]);
  )*/

  return (
      <>
        <RorAutocomplete acText={acText || ''} setAcText={setAcText} setAcID={setAcID} setAutoBlurred={setAutoBlurred} />
        <p>Typed value is: {acText}</p>
        <p>Selected ID is: {acID}</p>
        <p>Blurred: {'' + autoBlurred}</p>
      </>
  )
}