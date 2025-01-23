import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg, formatSizeUnits} from '../../../../lib/utils';
import {maxSize} from '../../UploadFiles/maximums';
import PublicationForm from './PublicationForm';
import Title from './Title';

export default function Publication({resource, setResource}) {
  const subType = resource.resource_type.resource_type;
  const [res, setRes] = useState(resource);
  const [importType, setImportType] = useState(resource.identifier.import_info);
  const [checks, setChecks] = useState({published: false, manuscript: false, showTitle: false});
  const [sponsored, setSponsored] = useState(false);
  const [dupeWarning, setDupeWarning] = useState(false);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const optionChange = (choice) => {
    showSavingMsg();
    setImportType(choice);
    setRes((r) => ({...r, identifier: {...r.identifier, import_info: choice}}));
    axios.patch(
      `/stash/resources/${resource.id}/import_type`,
      {authenticity_token, import_info: choice},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't change import_type on remote server");
        }
        showSavedMsg();
      });
  };
  const setOption = (e) => {
    const n = e.target.name;
    const v = e.target.value;
    setChecks((s) => ({...s, [n]: v}));
    if (v === 'yes') optionChange(n);
    if (v === 'no') optionChange(n === 'published' && checks.manuscript === 'yes' ? 'manuscript' : 'other');
  };

  useEffect(() => {
    setResource(res);
    const {publication_name, manuscript_number} = res.resource_publication;
    const primary_article = res.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
    if (!!publication_name && (!!manuscript_number || !!primary_article)) {
      setChecks((s) => ({...s, showTitle: 'yes'}));
    } else if (!res.title) {
      setChecks((s) => ({...s, showTitle: 'no'}));
    }
    setSponsored(!!res.journal?.payment_plan_type && (manuscript_number || primary_article) ? res.journal.title : false);
    if (res.title && !resource.identifier.process_date?.processing) {
      axios.get(`/stash/resources/${resource.id}/dupe_check`).then((data) => {
        setDupeWarning(data.data?.[0]?.title || false);
      });
    } else {
      setDupeWarning(false);
    }
  }, [res]);

  useEffect(() => {
    const it = resource.identifier.import_info;
    if (it === 'published') setChecks({published: 'yes', manuscript: false, showTitle: resource.title ? 'yes' : 'no'});
    if (it === 'manuscript') setChecks({published: 'no', manuscript: 'yes', showTitle: resource.title ? 'yes' : 'no'});
    if (it === 'other' && resource.title) setChecks({published: 'no', manuscript: 'no', showTitle: 'yes'});
  }, []);

  return (
    <>
      <h2>Title/Import</h2>
      <fieldset onChange={setOption}>
        <legend style={{margin: '1em 0 0'}}>
          Is your {subType === 'collection' ? 'collection associated with' : 'data used in'} a published article, with a DOI?
        </legend>
        <p className="radio_choice">
          <label><input name="published" type="radio" value="yes" defaultChecked={checks.published === 'yes' ? 'checked' : null} />Yes</label>
          <label><input name="published" type="radio" value="no" required defaultChecked={checks.published === 'no' ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      <fieldset id="manuscript" onChange={setOption} hidden={!checks.published || checks.published === 'yes'}>
        <legend style={{margin: '1.5em 0 0'}}>
          Is your {subType === 'collection' ? 'collection associated with' : 'data used in'} a submitted manuscript, with a manuscript number?
        </legend>
        <p className="radio_choice">
          <label><input name="manuscript" type="radio" value="yes" defaultChecked={checks.manuscript === 'yes' ? 'checked' : null} />Yes</label>
          <label><input name="manuscript" type="radio" value="no" required defaultChecked={checks.manuscript === 'no' ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      {sponsored && (
        <div className="callout">
          <p>Payment for this submission is sponsored by <b>{sponsored}</b></p>
        </div>
      )}
      {importType !== 'other' && <PublicationForm resource={res} setResource={setRes} setSponsored={setSponsored} importType={importType} />}
      {((checks.published === 'no' && checks.manuscript === 'no') || checks.showTitle === 'yes') && (
        <Title key={res.title} resource={res} setResource={setRes} />
      )}
      {dupeWarning && (
        <div className="callout warn">
          <p>
            This is the same title or primary publication as your existing submission:
            <b style={{display: 'block', marginTop: '.5ch'}}>{dupeWarning}</b>
          </p>
          <div>
            <form action={`/stash/resources/${resource.id}`} method="post" style={{display: 'inline'}}>
              <input type="hidden" name="_method" value="delete" />
              <input type="hidden" name="authenticity_token" value={authenticity_token} />
              <button type="submit" className="o-link__primary" style={{border: 0, padding: 0, background: 'transparent'}}>
                Delete this new submission
              </button>
            </form> if you did not intend to create it.
          </div>
          <p>
            Do you have more than {formatSizeUnits(maxSize)} of files and need to split a dataset into multiple submissions?
            Please ensure the title of this submission distinguishes it, or marks it as part of a series.
          </p>
        </div>
      )}
    </>
  );
}
