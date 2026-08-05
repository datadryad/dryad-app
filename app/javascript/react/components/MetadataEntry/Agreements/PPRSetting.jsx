import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import {ExitIcon} from '../../ExitButton';

export default function PPRSetting({ppr, setPPR, resource, setResource, dpc, preview, previous}) {
  const [reason, setReason] = useState('');

  const subType = resource.resource_type.resource_type;
  const curated = !!resource.identifier.process_date.curation_end;
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

  useEffect(() => {
    if (Object.hasOwn(dpc, 'total_file_size')) {
      if (resource.identifier.pub_state === 'published') {
        setReason(', because the data has been previously published');
      } else if (dpc.man_decision_made) {
        setReason(', because the journal has made a decision on the associated manuscript');
      } else if (resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier) {
        setReason(', because the associated primary publication is not in peer review');
      } else if (curated) {
        setReason(', because the dataset has previously been submitted and entered curation');
      }
      if (!curated) {
        if (dpc.automatic_ppr && !ppr) postPPR(true);
        else if (!dpc.allow_review && ppr) postPPR(false);
      }
    }
  }, [dpc]);

  if (preview) {
    return (
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
    )
  }

  if (!curated && dpc.automatic_ppr) {
    return (
      <>
        <h3>{subType === 'collection' ? 'Is your collection' : 'Are your files'} ready to publish?</h3>
        <p>
          This submission is associated with a manuscript from an{' '}
          <a href="/journals" target="_blank">integrated journal<ExitIcon /></a>.
          It will remain Private for Peer Review until formal acceptance of the associated manuscript.
        </p>
      </>
    );
  }

  if (!curated && dpc.allow_review) {
    return (
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
    );
  }

  return (
    <>
      <h3>{subType === 'collection' ? 'Is your collection' : 'Are your files'} ready to publish?</h3>
      <p>
          The Private for Peer Review option is not available for this submission{reason}.
          The submission will proceed to our curation process for evaluation and publication.
      </p>
    </>
  );
}