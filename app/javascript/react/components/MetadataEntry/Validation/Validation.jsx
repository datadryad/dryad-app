import React, {
  useRef, useState, useEffect, useCallback,
} from 'react';
import axios from 'axios';
import {debounce} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

export default function Validation({resource, setResource}) {
  const hsiRef = useRef(null);
  const [hsi, setHSI] = useState(null);
  const [desc, setDesc] = useState('');
  const [disclaimer, setDisclaimer] = useState(resource.descriptions.find((d) => d.description_type === 'usage_notes'));

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = () => {
    if (disclaimer) {
      const {value} = hsiRef.current || {};
      if (disclaimer.description !== value || (!hsi && !!desc)) {
        const subJson = {
          authenticity_token,
          description: {
            description: hsi === false ? null : value,
            resource_id: resource.id,
            id: disclaimer.id,
          },
        };
        showSavingMsg();
        axios.patch(
          '/stash_datacite/descriptions/update',
          subJson,
          {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
        ).then((data) => {
          setDisclaimer(data.data);
          showSavedMsg();
        });
      }
    }
  };

  const create = (val) => {
    showSavingMsg();
    axios.post(
      '/stash_datacite/descriptions/create',
      {
        authenticity_token, resource_id: resource.id, type: 'usage_notes', val,
      },
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      showSavedMsg();
      setDisclaimer(data.data);
    });
  };

  const setBool = (e) => {
    const v = e.target.value;
    if (hsi === null) create(v === 'yes' ? '' : null);
    if (v === 'no') setHSI(false);
    if (v === 'yes') setHSI(true);
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  useEffect(() => {
    if (disclaimer) {
      setResource((r) => ({...r, descriptions: [disclaimer, ...r.descriptions.filter((d) => d.description_type !== 'usage_notes')]}));
    }
  }, [disclaimer]);

  useEffect(() => checkSubmit(), [desc]);

  useEffect(() => submit(), [hsi]);

  useEffect(() => {
    setHSI(disclaimer ? disclaimer?.description !== null : null);
    setDesc(disclaimer?.description);
  }, []);

  return (
    <>
      <fieldset onChange={setBool}>
        <legend>Does your data contain information on human subjects?</legend>
        <p className="radio_choice">
          <label><input name="hsi" type="radio" value="yes" defaultChecked={hsi === true ? 'checked' : null} />Yes</label>
          <label><input name="hsi" type="radio" value="no" required defaultChecked={hsi === false ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      {hsi && (
        <>
          <h3 id="hsi-label">Human subjects de-identification</h3>
          <div id="hsi-desc">
            <p>A written statement is required.</p>
            <ol>
              <li>Confirm that you received explicit consent from your participants to publish the de-identified data.</li>
              <li>Explain how you de-identified the data.</li>
            </ol>
            <p>This statement will appear with your submission README.</p>
          </div>
          <textarea
            ref={hsiRef}
            className="c-input__textarea"
            style={{width: '100%'}}
            id="disclaimer-area"
            rows={5}
            value={desc || ''}
            onBlur={submit}
            onChange={(e) => setDesc(e.target.value)}
            aria-describedby="hsi-desc"
            aria-labelledby="hsi-label"
            aria-errormessage="hsi_error"
          />
        </>
      )}
    </>
  );
}
