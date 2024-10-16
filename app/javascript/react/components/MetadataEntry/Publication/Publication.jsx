import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import PublicationForm from './PublicationForm';
import Title from './Title';

export default function Publication({resource, setResource}) {
  const subType = resource.resource_type.resource_type;
  const [res, setRes] = useState(resource);
  const [importType, setImportType] = useState(resource.identifier.import_info);
  const [checks, setChecks] = useState({published: false, manuscript: false, showTitle: false});
  const [sponsored, setSponsored] = useState(false);

  const optionChange = (choice) => {
    showSavingMsg();
    setImportType(choice);
    setResource((r) => ({...r, identifier: {...r.identifier, import_info: choice}}));
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
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
        <p><legend>Is your {subType === 'collection' ? 'collection associated with' : 'data used in'} in a published article?</legend></p>
        <p className="radio_choice">
          <label><input name="published" type="radio" value="yes" defaultChecked={checks.published === 'yes' ? 'checked' : null} />Yes</label>
          <label><input name="published" type="radio" value="no" required defaultChecked={checks.published === 'no' ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      <fieldset id="manuscript" onChange={setOption} hidden={!checks.published || checks.published === 'yes'}>
        <p><legend>Is your {subType === 'collection' ? 'collection associated with' : 'data used in'} a submitted manuscript?</legend></p>
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
        <Title resource={resource} setResource={setResource} />
      )}
    </>
  );
}
