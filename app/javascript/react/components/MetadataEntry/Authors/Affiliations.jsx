import React, {useState, useEffect} from 'react';
import RorAutocomplete from '../RorAutocomplete';

export default function Affiliations({
  formRef, id, affiliations, setAffiliations,
}) {
  const [affs, setAffs] = useState(affiliations.length > 0 ? affiliations : [{long_name: '', ror_id: ''}]);

  useEffect(() => {
    setAffiliations(affs);
  }, [affs]);

  const updateName = (i, v) => {
    setAffs((afs) => afs.map((a, x) => (i === x ? {...a, long_name: v} : a)));
  };
  const updateID = (i, v) => {
    setAffs((afs) => afs.map((a, x) => (i === x ? {...a, ror_id: v} : a)));
  };
  const newAff = () => setAffs((afs) => afs.concat([{long_name: '', ror_id: ''}]));
  const removeAff = (i) => {
    affs.splice(i, 1);
    setAffs(affs);
  };

  return (
    <>
      {affs.map((aff, i) => (
        <div className="input-stack affiliation-input" key={aff.id || aff.ror_id || affs.length + i}>
          <div className="input-line">
            <label htmlFor={`instit_affil_${id}-${i}`} className="input-label">
              Institutional affiliation
            </label>
            {i !== 0 && (
              <button type="button" aria-label={`Remove affiliation ${aff.long_name}`} title="Remove affiliation" onClick={() => removeAff(i)}>
                <i className="fas fa-xmark" aria-hidden="true" />
              </button>
            )}
          </div>
          <RorAutocomplete
            key={aff?.id || `affTEMP${aff.length + i}`}
            formRef={formRef}
            acText={aff.long_name || ''}
            setAcText={(v) => updateName(i, v)}
            acID={aff.ror_id}
            setAcID={(v) => updateID(i, v)}
            controlOptions={{
              htmlId: `instit_affil_${id}-${i}`,
              isRequired: true,
              errorId: 'author_aff_error',
            }}
          />
        </div>
      ))}
      <span><button type="button" onClick={newAff}>+ Add affiliation</button></span>
    </>
  );
}
