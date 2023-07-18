import React, {useRef, useState} from 'react';
import PropTypes from 'prop-types';
import RorAutocomplete from './MetadataEntry/RorAutocomplete';

// the autocomplete name, autocomplete id (like ROR), get/set autocomplete Text, get/set autocomplete ID
export default function AffiliationSelect({name, rorId, controlOptions}) {
  const formRef = useRef(0);
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs.
  // also tracking "autoBlurred" since we need to know when things exit to trigger form resubmission or sending to server.
  const [acText, setAcText] = useState(name);
  const [acID, setAcID] = useState(rorId);

  return (
    <div ref={formRef} handleSubmit={() => false}>
      <RorAutocomplete
        formRef={formRef}
        acText={acText || ''}
        setAcText={setAcText}
        acID={acID || ''}
        autoBlur={false}
        setAcID={setAcID}
        controlOptions={controlOptions}
      />
      <input type="hidden" name="affiliation" value={acText} />
      <input type="hidden" name="affiliation_id" value={acID} />
    </div>
  );
}

AffiliationSelect.propTypes = {
  name: PropTypes.string.isRequired,
  rorId: PropTypes.string.isRequired,
  controlOptions: PropTypes.object.isRequired,
};
