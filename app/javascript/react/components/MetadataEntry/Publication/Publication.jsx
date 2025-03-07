import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg, formatSizeUnits} from '../../../../lib/utils';
import PublicationForm from './PublicationForm';
import Title from './Title';

export default function Publication({resource, setResource, maxSize}) {
  const subType = resource.resource_type.resource_type;
  const [res, setRes] = useState(resource);
  const [assoc, setAssoc] = useState(null);
  const [showTitle, setShowTitle] = useState(false);
  const [importType, setImportType] = useState(resource.identifier.import_info);
  const [sponsored, setSponsored] = useState(false);
  const [dupeWarning, setDupeWarning] = useState(false);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const optionChange = (choice) => {
    showSavingMsg();
    setImportType(choice);
    setRes((r) => ({...r, identifier: {...r.identifier, import_info: choice}}));
    axios.patch(
      `/resources/${resource.id}/import_type`,
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

  const setImport = (e) => {
    const v = e.target.value;
    if (v === 'no') {
      setAssoc(false);
      optionChange('other');
    }
    if (v === 'yes') setAssoc(true);
  };

  const setOption = (e) => {
    const v = e.target.value;
    optionChange(v);
  };

  useEffect(() => {
    if (assoc === false) setShowTitle(true);
    if (assoc === true && !res.title) setShowTitle(false);
  }, [assoc]);

  useEffect(() => {
    setResource(res);
    const {publication_name, manuscript_number} = res.resource_publication;
    const primary_article = res.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
    const {publication_name: preprint_server} = res.resource_preprint || {};
    const preprint = res.related_identifiers.find((r) => r.work_type === 'preprint')?.related_identifier;
    if ((!!publication_name && (!!manuscript_number || !!primary_article))
      || (!!preprint_server && !!preprint)) {
      console.log('hey');
      setShowTitle(true);
    }
    setSponsored(!!res.journal?.payment_plan_type && (manuscript_number || primary_article) ? res.journal.title : false);
    if (res.title && !resource.identifier.process_date?.processing) {
      axios.get(`/resources/${resource.id}/dupe_check.json`).then((data) => {
        setDupeWarning(data.data?.[0]?.title || false);
      });
    } else {
      setDupeWarning(false);
    }
  }, [res]);

  useEffect(() => {
    const it = resource.identifier.import_info;
    if (it === 'other') setAssoc(false);
    if (['published', 'preprint', 'manuscript'].includes(it)) setAssoc(true);
  }, []);

  return (
    <>
      <fieldset onChange={setImport}>
        <legend>
          Is your {subType === 'collection' ? 'collection associated with' : 'data used in'} a research article?
        </legend>
        <p className="radio_choice">
          <label><input name="assoc" type="radio" value="yes" defaultChecked={assoc === true ? 'checked' : null} />Yes</label>
          <label><input name="assoc" type="radio" value="no" required defaultChecked={assoc === false ? 'checked' : null} />No</label>
        </p>
      </fieldset>

      {assoc && (
        <>
          <div className="callout alt">
            <p><i className="fas fa-circle-info" /> The title and other metadata can be imported from some article sources.</p>
          </div>
          <fieldset onChange={setOption} style={{margin: '2rem 0'}}>
            <legend>
              From what source would you like to import information?
            </legend>
            <ul className="o-list" style={{marginTop: '1rem'}}>
              <li className="radio_choice">
                <label>
                  <input name="import" type="radio" value="manuscript" defaultChecked={importType === 'manuscript' ? 'checked' : null} />
                  Submitted manuscript
                </label>
              </li>
              <li className="radio_choice">
                <label>
                  <input name="import" type="radio" value="preprint" defaultChecked={importType === 'preprint' ? 'checked' : null} />
                  Preprint
                </label>
              </li>
              <li className="radio_choice">
                <label>
                  <input name="import" type="radio" value="published" defaultChecked={importType === 'published' ? 'checked' : null} />
                  Published article
                </label>
              </li>
            </ul>
          </fieldset>
        </>
      )}

      {sponsored && (
        <div className="callout">
          <p>Payment for this submission is sponsored by <b>{sponsored}</b></p>
        </div>
      )}

      {importType && importType !== 'other' && (
        <PublicationForm resource={res} setResource={setRes} setSponsored={setSponsored} importType={importType} key={importType} />
      )}

      {showTitle && (
        <Title key={res.title} resource={res} setResource={setRes} />
      )}

      {dupeWarning && (
        <div className="callout warn">
          <p>
            This is the same title or primary publication as your existing submission:
            <b style={{display: 'block', marginTop: '.5ch'}}>{dupeWarning}</b>
          </p>
          <div>
            <form action={`/resources/${resource.id}`} method="post" style={{display: 'inline'}}>
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
