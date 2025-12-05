import React, {useRef, useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import {ExitIcon} from '../../ExitButton';
import Calculations from './Calculations';
import CalculateFees from '../../CalculateFees';
import {useStore} from '../../../shared/store';

export default function Agreements({
  resource, setResource, user, form, previous, config, current, setAuthorStep, preview = false,
}) {
  const {updateStore, storeState: {dpc, fees, userMustPay}} = useStore();
  const subType = resource.resource_type.resource_type;
  const submitted = !!resource.identifier.process_date.processing;
  const curated = !!resource.identifier.process_date.curation_end;
  const {users} = resource;
  const submitter = users.find((u) => u.role === 'submitter');
  const isSubmitter = user.id === submitter.id;
  const formRef = useRef(null);
  const [ppr, setPPR] = useState(resource.hold_for_peer_review);
  const [agree, setAgree] = useState(resource.accepted_agreement);
  const [reason, setReason] = useState('');

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const postPPR = (bool) => {
    showSavingMsg();
    axios.patch(
      '/stash_datacite/peer_review/toggle',
      {authenticity_token, id: resource.id, hold_for_peer_review: bool},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status === 200) {
          const {hold_for_peer_review} = data.data;
          setPPR(hold_for_peer_review);
          setResource((r) => ({...r, hold_for_peer_review}));
          showSavedMsg();
        }
      });
  };

  const togglePPR = (e) => {
    const v = e.target.value;
    postPPR(v === '1');
  };

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

  useEffect(() => {
    const existing = formRef.current?.querySelector('#dryad-member');
    if (formRef.current && !existing) {
      const active_form = document.createRange().createContextualFragment(form);
      formRef.current.append(active_form);
    }
    if (!!dpc.aff_tenant && existing) {
      formRef.current.querySelector('#dryad-member').hidden = true;
      formRef.current.querySelector('#edit-tenant-form').hidden = false;
      formRef.current.querySelector('#searchselect-tenant__value').value = dpc.aff_tenant.id;
      formRef.current.querySelector('#searchselect-tenant__label').value = dpc.aff_tenant.short_name;
      formRef.current.querySelector('#searchselect-tenant__input').value = dpc.aff_tenant.short_name;
    }
  }, [dpc, formRef.current]);

  useEffect(() => {
    if (resource.identifier.pub_state === 'published') {
      setReason(', because the data has been previously published');
    } else if (dpc.man_decision_made) {
      setReason(', because the journal has made a decision on the associated manuscript');
    } else if (resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier) {
      setReason(', because the associated primary publication is not in peer review');
    } else if (curated) {
      setReason(', because the dataset has previously been submitted and entered curation');
    }
    if (!preview && !curated) {
      if (dpc.automatic_ppr && !ppr)
        postPPR(true);
      else
        if (!dpc.allow_review && ppr) postPPR(false);
    }
  }, [dpc]);

  useEffect(() => {
    if (preview || current) updateStore({refreshDpcStatus: true});
  }, [current, preview]);

  if (Object.keys(dpc).length === 0) {
    return (
      <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>
    );
  }
  return (
    <>
      {preview && (
        <>
          <h2>{subType === 'collection' ? 'Is your collection' : 'Are your files'} ready to publish?</h2>
          <div className="callout alt">
            {ppr ? (
              <p>
                {subType === 'collection' ? 'This collection will be ' : 'These files will be '}
                kept private while your manuscript undergoes peer review
              </p>
            ) : (
              <p>
                {subType === 'collection'
                  ? 'This collection will be publically viewable '
                  : <>These files <b>will be available for public download</b> </>}as soon as possible
              </p>
            )}
          </div>
          {previous && ppr !== previous.hold_for_peer_review && <p className="del ins">PPR setting changed</p>}
        </>
      )}
      {!preview && (
        <>
          {!curated && dpc.automatic_ppr && (
            <>
              <h3>{subType === 'collection' ? 'Is your collection' : 'Are your files'} ready to publish?</h3>
              <p>
                This submission is associated with a manuscript from an{' '}
                <a href="/journals" target="_blank">integrated journal<ExitIcon /></a>.
                It will remain Private for Peer Review until formal acceptance of the associated manuscript.
              </p>
            </>
          )}
          {!curated && dpc.allow_review ? (
            <fieldset onChange={togglePPR} aria-labelledby="toggle-ppr">
              <h3 style={{margin: '0'}} id="toggle-ppr">
                {`${subType === 'collection' ? 'Is your collection' : 'Are your files'} ready to publish?`}
              </h3>
              <p className="radio_choice">
                <label style={!ppr ? {fontWeight: 'bold'} : {}}>
                  <input type="radio" name="peer_review" value="0" defaultChecked={!ppr} />
                  {`My ${subType === 'collection'
                    ? 'collection should be publically viewable '
                    : 'files should be available for public download '} as soon as possible`}
                </label>
              </p>
              <p className="radio_choice" style={{marginBottom: 0}}>
                <label style={ppr ? {fontWeight: 'bold'} : {}}>
                  <input type="radio" name="peer_review" value="1" defaultChecked={ppr} />
                  {`Keep my ${subType === 'collection' ? 'collection' : 'files'} private while my manuscript undergoes peer review`}
                </label>
              </p>
            </fieldset>
          ) : (
            <>
              <h3>{subType === 'collection' ? 'Is your collection' : 'Are your files'} ready to publish?</h3>
              <p>
                The Private for Peer Review option is not available for this submission{reason}.
                The submission will proceed to our curation process for evaluation and publication.
              </p>
            </>
          )}
        </>
      )}
      {preview ? <h2>Do you agree to Dryad’s terms?</h2> : <h3 style={{marginTop: '3rem'}}>Do you agree to Dryad’s terms?</h3>}
      {subType !== 'collection' && (
        <>
          {dpc.funder_will_pay && (
            <div className="callout">
              <p>Payment for this submission is sponsored by <b>{dpc.paying_funder}</b></p>
            </div>
          )}
          {!dpc.funder_will_pay && dpc.institution_will_pay && (
            <>
              <div className="callout">
                <p>Payment for this submission is sponsored by <b>{resource.tenant.long_name}</b></p>
              </div>
              {previous && resource.tenant_id !== previous.tenant_id && <p className="del ins">Partner institution changed</p>}
            </>
          )}
          {!dpc.funder_will_pay && !dpc.institution_will_pay && dpc.journal_will_pay && (
            <div className="callout">
              <p>Payment for this submission is sponsored by <b>{resource.resource_publication.publication_name}</b></p>
            </div>
          )}
          {resource.identifier.old_payment_system
            ? userMustPay && (
              <>
                <Calculations resource={resource} config={config} />
                <p>The submitter may choose an invoice recipient upon submission of the dataset.</p>
              </>
            )
            : (
              /* eslint-disable max-len */
              <>
                <CalculateFees resource={resource} fees={fees} ppr={ppr} />
                {fees.total ? <p>You will be asked to pay this fee upon submission. If you require an invoice to be sent to another entity for payment, an additional administration fee will be charged.</p> : null}
              </>
              /* eslint-enable max-len */
            )}
        </>
      )}
      {!preview && !isSubmitter && (
        <div className="callout warn">
          <p>
            Only the submitter can agree to the terms and conditions.
            When you are done editing, please click &nbsp;
            <b><i className="fas fa-floppy-disk" /> Save &amp; exit</b> &nbsp;
            and ask the submitter to complete the submission.
          </p>
        </div>
      )}
      {isSubmitter && (
        <>
          {(subType !== 'collection'
            && (!resource.identifier.payment_type || resource.identifier.payment_type === 'unknown')
            && (userMustPay || (!dpc.funder_will_pay && dpc.institution_will_pay))) && (
            <>
              {dpc.institution_will_pay && !!dpc.aff_tenant && dpc.aff_tenant.id !== resource.tenant_id && (
                <>
                  <p><b>Is this correct?</b> Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is also a Dryad partner.</p>
                  <div style={{maxWidth: '700px'}} ref={formRef} />
                </>
              )}
              {userMustPay && (
                <div className="callout warn" style={{margin: '1em 0', paddingBottom: '5px'}}>
                  <p style={{marginBottom: '.75em'}}>
                    <i className="fas fa-circle-question" aria-hidden="true" style={{marginRight: '.5ch'}} />
                    Are you affiliated with a Dryad partner institution that covers the Data Publishing Charge?
                  </p>
                  <div style={{backgroundColor: 'white', padding: '10px', marginBottom: '5px'}}>
                    {!!dpc.aff_tenant && (
                      <p>
                        Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is a Dryad partner.
                        Verify your credentials for DPC sponsorship.
                      </p>
                    )}
                    {resource.tenant.authentication?.table?.strategy === 'author_match' && (
                      <p style={{marginTop: 0}}>
                        <em>
                          For DPC sponsorship, <b>{resource.tenant.short_name}</b> must appear in your author affiliation list for this submission.
                        </em>{' '}
                        <span
                          style={{whiteSpace: 'nowrap'}}
                          role="button"
                          tabIndex="0"
                          className="o-button__plain-text7"
                          onClick={setAuthorStep}
                          onKeyDown={(e) => {
                            if (['Enter', 'Space'].includes(e.key)) {
                              setAuthorStep();
                            }
                          }}
                        ><i className="fa fa-pencil" aria-hidden="true" style={{marginRight: '.25ch'}} />Edit the author list
                        </span>
                      </p>
                    )}
                    <div style={{maxWidth: '700px'}} ref={formRef} />
                  </div>
                </div>
              )}
            </>
          )}
          {!preview && (
            <p className="radio_choice" style={{marginTop: '2em'}}>
              <label>
                <input type="checkbox" id="agreement" defaultChecked={agree} onChange={toggleTerms} required disabled={submitted} />
                <span className="input-label">I agree</span>
                {` to Dryad's ${subType !== 'collection' && userMustPay ? 'payment terms and ' : ''}`}
                <a href="/terms" target="_blank">terms of submission<ExitIcon /></a>
              </label>
            </p>
          )}
        </>
      )}
      {preview && (
        <div>
          {resource.accepted_agreement ? (
            <p>
              <i className="fas fa-circle-check" aria-hidden="true" />{' '}
              The submitter has agreed to Dryad&apos;s{' '}
              <a href="/terms" target="_blank">terms of submission<ExitIcon /></a>
            </p>
          ) : (
            <p style={{fontStyle: 'italic'}}><i className="fas fa-square" aria-hidden="true" />{' '} Terms not yet accepted</p>
          )}
        </div>
      )}
    </>
  );
}
