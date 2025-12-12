import React, {useState, useEffect} from 'react';
import RorAutocomplete from '../RorAutocomplete';
import {useStore} from '../../../shared/store';
/* eslint-disable react/no-array-index-key */

export default function Affiliations({
  formRef, id, affiliations, setAffiliations,
}) {
  const {updateStore} = useStore();
  const [affs, setAffs] = useState(affiliations.length > 0 ? affiliations : [{long_name: '', ror_id: ''}]);

  useEffect(() => {
    setAffiliations(affs);
    updateStore({refreshFees: true});
  }, [affs]);

  const updateName = (i, v) => {
    setAffs((afs) => afs.map((a, x) => (i === x ? {...a, long_name: v} : a)));
  };
  const updateID = (i, v) => {
    setAffs((afs) => afs.map((a, x) => (i === x ? {...a, ror_id: v} : a)));
  };
  const newAff = (e) => {
    setAffs((afs) => afs.concat([{long_name: '', ror_id: ''}]));
    e.target.blur();
  };
  const removeAff = (index) => {
    setAffs((afs) => afs.filter((a, i) => i !== index));
  };

  return (
    <>
      {affs.map((aff, i) => (
        <div className="input-stack affiliation-input" key={`aff${i}`}>
          <div className="input-line">
            <label id={`label_instit_affil_${id}-${i}`} htmlFor={`instit_affil_${id}-${i}`} className="input-label">
              Institutional affiliation
            </label>
            {i !== 0 && (
              <button type="button" aria-label={`Remove affiliation ${aff.long_name}`} title="Remove affiliation" onClick={() => removeAff(i)}>
                <i className="fas fa-xmark" aria-hidden="true" />
              </button>
            )}
          </div>
          <RorAutocomplete
            formRef={formRef}
            acText={aff.long_name || ''}
            setAcText={(v) => updateName(i, v)}
            acID={aff.ror_id || ''}
            setAcID={(v) => updateID(i, v)}
            controlOptions={{
              htmlId: `instit_affil_${id}-${i}`,
              isRequired: true,
              errorId: 'author_aff_error',
              desBy: `${id}-${`aff${i}`}-ex`,
            }}
          />
          <div id={`${id}-${`aff${i}`}-ex`}><i aria-hidden="true" />Employer or sponsor</div>
        </div>
      ))}
      <div className="author-one-line"><button type="button" className="add-aff-button" onClick={newAff}>+ Add affiliation</button></div>
    </>
  );
}
