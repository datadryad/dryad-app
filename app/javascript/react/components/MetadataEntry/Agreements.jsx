import React, {useRef, useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export default function Agreements({
  resource, setResource, form, previous, preview = false,
}) {
  const subType = resource.resource_type.resource_type;
  const submitted = !!resource.identifier.process_date.processing;
  const curated = !!resource.identifier.process_date.curation_end;
  const formRef = useRef(null);
  const [dpc, setDPC] = useState({});
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
      `/stash/metadata_entry_pages/${accept ? 'accept' : 'reject'}_agreement`,
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
    if (formRef.current) {
      const active_form = document.createRange().createContextualFragment(form);
      formRef.current.append(active_form);
    }
  }, [dpc, formRef]);

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
  }, [dpc]);

  useEffect(() => {
    async function getPaymentInfo() {
      axios.get(`/stash/resources/${resource.id}/dpc_status`).then((data) => {
        if (!preview && !curated) {
          if (data.data.automatic_ppr && !ppr) postPPR(true);
          else if (!data.data.allow_review && ppr) postPPR(false);
        }
        setDPC(data.data);
      });
    }
    getPaymentInfo();
  }, []);

  return (
    <>
      <h2>Agreements</h2>
      {preview && (
        <>
          <h3>Publication{subType === 'collection' ? '' : ' of your files'}</h3>
          <div className="callout alt">
            {ppr ? (
              <p>
                {subType === 'collection' ? 'This collection will be ' : 'These files will be '}kept private while your manuscript is in peer review
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
              <h3>Publication{subType === 'collection' ? '' : ' of your files'}</h3>
              <p>
                This submission is associated with a manuscript from an{' '}
                <a href="/stash/journals" target="_blank">integrated journal<span className="screen-reader-only"> (opens in new window)</span></a>.
                It will remain private for peer review until formal acceptance of the associated manuscript.
              </p>
            </>
          )}
          {!curated && dpc.allow_review ? (
            <fieldset onChange={togglePPR}>
              <h3><legend>Publication{subType === 'collection' ? '' : ' of your files'}</legend></h3>
              <p className="radio_choice">
                <label style={!ppr ? {fontWeight: 'bold'} : {}}>
                  <input type="radio" name="peer_review" value="0" defaultChecked={!ppr} />
                  My {subType === 'collection' ? 'collection should be publically viewable ' : 'files should be available for public download '}
                  as soon as possible
                </label>
              </p>
              <p className="radio_choice">
                <label style={ppr ? {fontWeight: 'bold'} : {}}>
                  <input type="radio" name="peer_review" value="1" defaultChecked={ppr} />
                  Keep my {subType === 'collection' ? 'collection' : 'files'} private while my manuscript is in peer review
                </label>
              </p>
            </fieldset>
          ) : (
            <>
              <h3>Publication{subType === 'collection' ? '' : ' of your files'}</h3>
              <p>
                The private for peer review option is not available for this submission{reason}.
                The submission will proceed to our curation process for evaluation and publication.
              </p>
            </>
          )}
        </>
      )}
      {subType === 'collection' ? <h3>Terms</h3> : (
        <>
          <h3>Payment and terms</h3>
          {dpc.journal_will_pay && (
            <div className="callout">
              <p>Payment for this submission is sponsored by <b>{resource.resource_publication.publication_name}</b></p>
            </div>
          )}
          {!dpc.journal_will_pay && dpc.funder_will_pay && (
            <div className="callout">
              <p>Payment for this submission is sponsored by <b>{dpc.paying_funder}</b></p>
            </div>
          )}
          {!dpc.journal_will_pay && !dpc.funder_will_pay && dpc.institution_will_pay && (
            <>
              <div className="callout">
                <p>Payment for this submission is sponsored by <b>{resource.tenant.long_name}</b></p>
              </div>
              {previous && resource.tenant !== previous.tenant && <p className="del ins">Member institution changed</p>}
            </>
          )}
          {dpc.user_must_pay && (
            <>
              <p>
                Dryad charges a fee for data publication that covers curation and preservation of published
                datasets. Upon publication of your dataset, you will receive an invoice for ${dpc.dpc} USD.
              </p>
              {!!dpc.large_files && (
                <p>
                  For data packages in excess of {dpc.large_file_size}, submitters will be charged $50 USD for
                  each additional 10GB, or part thereof. Submissions between 50 and 60GB = $50 USD, between 60
                  and 70GB = $100 USD, and so on.
                </p>
              )}
            </>
          )}
        </>
      )}
      {preview ? (
        <div>
          {resource.accepted_agreement ? (
            <p>
              <i className="fas fa-check-square" aria-hidden="true" />{' '}
              The submitter has agreed to Dryad&apos;s{' '}
              <a href="/stash/terms" target="_blank">terms of submission <span className="screen-reader-only"> (opens in new window)</span></a>
            </p>
          ) : (
            <p style={{fontStyle: 'italic'}}><i className="fas fa-square" aria-hidden="true" />{' '} Terms not yet accepted</p>
          )}
        </div>
      ) : (
        <>
          <p className="radio_choice">
            <label>
              <input type="checkbox" id="agreement" defaultChecked={agree} onChange={toggleTerms} required disabled={submitted} />
              I agree to Dryad&apos;s {subType !== 'collection' && dpc.user_must_pay ? 'payment terms and ' : ''}
              <a href="/stash/terms" target="_blank">terms of submission <span className="screen-reader-only"> (opens in new window)</span></a>
            </label>
          </p>
          {(subType !== 'collection' && (!dpc.payment_type || dpc.payment_type === 'unknown') && (dpc.user_must_pay || dpc.institution_will_pay)) && (
            <>
              {dpc.user_must_pay && (
                <>
                  <div className="callout warn"><p>Are you affiliated with a Dryad member institution that could sponsor this fee?</p></div>
                  {!!dpc.aff_tenant && (
                    <p>Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is a Dryad member.</p>
                  )}
                </>
              )}
              <div style={{maxWidth: '700px'}} ref={formRef} />
              {dpc.user_must_pay && resource.tenant.authentication?.strategy === 'author_match' && (
                <p><em>For sponsorship, {resource.tenant.short_name} must appear as your author list affiliation for this submission.</em>.</p>
              )}
              {dpc.institution_will_pay && !!dpc.aff_tenant && dpc.aff_tenant.id !== resource.tenant_id && (
                <p><b>Is this correct?</b> Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is also a Dryad member.</p>
              )}
            </>
          )}
        </>
      )}
    </>
  );
}
