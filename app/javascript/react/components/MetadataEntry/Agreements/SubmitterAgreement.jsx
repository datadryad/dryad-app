import React, {useState} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import {ExitIcon} from '../../ExitButton';

export default function SubmitterAgreement({preview, resource, setResource, isSubmitter, userMustPay}) {
  const [agree, setAgree] = useState(resource.accepted_agreement);

  const submitted = !!resource.identifier.process_date.processing;
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const toggleTerms = (e) => {
    showSavingMsg();
    const accept = e.target.checked;
    axios.post(
      `/metadata_entry_pages/${accept ? 'accept' : 'reject'}_agreement`,
      {authenticity_token, resource_id: resource.id},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status === 200) {
          setAgree(accept);
          setResource((r) => ({...r, accepted_agreement: accept}));
          showSavedMsg();
        }
      });
  };

  if (preview) {
    if (resource.accepted_agreement) {
      return (
        <p>
          <i className="fas fa-circle-check" aria-hidden="true" />{' '}
          The submitter has agreed to Dryad&apos;s{' '}
          <a href="/terms" target="_blank">terms of submission<ExitIcon /></a>
        </p>
      );
    }
    return (
      <p style={{fontStyle: 'italic'}}><i className="fas fa-square" aria-hidden="true" />{' '} Terms not yet accepted</p>
    );
  }

  if (isSubmitter) {
    return (
      <form id="term-acceptance" onSubmit={(e) => e.preventDefault()}>
        <p className="radio_choice" style={{marginTop: '2em'}}>
          <label>
            <input type="checkbox" id="agreement" defaultChecked={agree} onChange={toggleTerms} required disabled={submitted} />
            <span className="input-label">I agree</span>
            {` to Dryad's ${userMustPay ? 'payment terms and ' : ''}`}
            <a href="/terms" target="_blank">terms of submission<ExitIcon /></a>
          </label>
        </p>
      </form>
    )
  }

  return (
    <div className="callout warn">
      <p>
        Only the submitter can agree to the terms and conditions.
        When you are done editing, please click &nbsp;
        <b><i className="fas fa-floppy-disk" /> Save &amp; exit</b> &nbsp;
        and ask the submitter to complete the submission.
      </p>
    </div>
  );
}