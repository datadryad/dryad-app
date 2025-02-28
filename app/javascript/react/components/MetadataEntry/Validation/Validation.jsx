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
  const [license, setLicense] = useState(resource.identifier.license_id);
  const [disclaimer, setDisclaimer] = useState(resource.descriptions.find((d) => d.description_type === 'usage_notes'));
  const submitted = !!resource.identifier.process_date.processing;

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const licenseChange = (e) => {
    const val = e.target.checked ? e.target.value : null;
    showSavingMsg();
    setLicense(val);
    setResource((r) => ({...r, identifier: {...r.identifier, license_id: val}}));
    axios.patch(
      `/resources/${resource.id}/license_agree`,
      {authenticity_token, license_id: val},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then(() => {
        showSavedMsg();
      });
  };

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
      <h3>Can your data be shared in the public domain?</h3>
      <p>All data deposited at Dryad must comply with a CC0 license waiver.{' '}
        <a href="https://blog.datadryad.org/2023/05/30/good-data-practices-removing-barriers-to-data-reuse-with-cc0-licensing/" target="_blank" rel="noreferrer">
          Learn more about why we use CC0<span className="screen-reader-only"> (opens in new window)</span>.
        </a>
      </p>
      <p>
        CC0 means others can freely share, modify, adapt, and use the data in any way, without conditions such as providing attribution.
        If data comes from a copyrighted source or has a license other than CC0, it cannot be shared on Dryad.
        Authors are legally responsible for ensuring their dataset does not violate copyright claims over material generated or published by others.
      </p>
      <fieldset>
        <legend>Do you understand and agree to the <a href="https://creativecommons.org/publicdomain/zero/1.0/legalcode.en" target="_blank" rel="noreferrer">license terms<span className="screen-reader-only"> (opens in new window)</span></a>?</legend>
        <p className="radio_choice">
          <label>
            <input
              disabled={submitted}
              aria-describedby="license-legend"
              name="license"
              type="checkbox"
              value="cc0"
              defaultChecked={license === 'cc0' ? 'checked' : null}
              onChange={licenseChange}
              aria-errormessage="license_error"
            />
            By checking this box, I confirm that my files are compatible with the CC0 license waiver
          </label>
        </p>
      </fieldset>
      <fieldset onChange={setBool} style={{display: 'block'}}>
        <legend role="heading" aria-level="3" style={{display: 'block', margin: '2rem 0 0'}} className="o-heading__level3">
          Does your data contain information on human subjects?
        </legend>
        <p className="radio_choice">
          <label><input name="hsi" type="radio" value="yes" defaultChecked={hsi === true ? 'checked' : null} />Yes</label>
          <label><input name="hsi" type="radio" value="no" required defaultChecked={hsi === false ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      {hsi && (
        <>
          <p style={{marginTop: 0}}>
            Dryad does not accept data with personally identifiable information (PII).
            Because data archived in Dryad is available in the public domain, all human subjects data must be properly anonymized and prepared{' '}
            under applicable legal and ethical guidelines to protect participants.
          </p>
          <p>
            If your data does not meet Dryad’s human subjects data standards for publication,{' '}
            your submission will be returned for revisions until it complies, or we can direct you to a more suitable repository.
          </p>
          <h4 id="hsi-label">Human subjects de-identification</h4>
          <div id="hsi-desc">
            <p>A written statement is required:</p>
            <ol>
              <li>Confirm that you received explicit consent from your participants to publish the de-identified data in the public domain.</li>
              <li>Explain how you de-identified the data.</li>
            </ol>
            <p>This statement will appear with your submission README and will be rederenced by users of your data.</p>
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
