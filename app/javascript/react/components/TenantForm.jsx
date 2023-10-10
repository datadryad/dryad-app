import React, {useRef, useState} from 'react';
import PropTypes from 'prop-types';
import GenericNameIdAutocomplete from './MetadataEntry/GenericNameIdAutocomplete';

// the autocomplete name, autocomplete id (like ROR), get/set autocomplete Text, get/set autocomplete ID
export default function TenantForm({tenants}) {
  const formRef = useRef(0);
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs.
  // also tracking "autoBlurred" since we need to know when things exit to trigger form resubmission or sending to server.
  const [acText, setAcText] = useState('');
  const [acID, setAcID] = useState('');

  const nameFunc = (item) => item.name;
  const idFunc = (item) => item.id;

  const supplyLookupList = (qt) => new Promise((resolve) => {
    if (qt.length > 0) {
      const lcqt = qt.toLowerCase();
      resolve(tenants.filter((t) => t.name.toLowerCase().includes(lcqt)));
    } else {
      resolve(tenants);
    }
  });

  return (
    <div ref={formRef}>
      <GenericNameIdAutocomplete
        acText={acText || ''}
        setAcText={setAcText}
        acID={acID}
        setAcID={setAcID}
        supplyLookupList={supplyLookupList}
        nameFunc={nameFunc}
        idFunc={idFunc}
        controlOptions={{htmlId: 'tenant_id', labelText: '', showDropdown: true}}
        setAutoBlurred={() => false}
      />
      <input type="hidden" name="tenant_id" value={acID} />
    </div>
  );
}

TenantForm.propTypes = {tenants: PropTypes.array.isRequired};
