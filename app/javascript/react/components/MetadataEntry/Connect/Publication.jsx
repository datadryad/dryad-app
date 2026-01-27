import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import PublicationForm from './PublicationForm';

export default function Publication({current, resource, setResource}) {
  const subType = resource.resource_type.resource_type;
  const [assoc, setAssoc] = useState(null);
  const [connections, setConnections] = useState([]);
  const [sponsored, setSponsored] = useState(false);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const optionChange = (choice) => {
    showSavingMsg();
    setResource((r) => ({...r, identifier: {...r.identifier, import_info: choice}}));
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
      setConnections([]);
      optionChange('other');
    }
    if (v === 'yes') setAssoc(true);
  };

  const setOption = (e) => {
    const checked = e.currentTarget.querySelectorAll('input:checked');
    const selected = [...checked].map((i) => i.value);
    setConnections(selected);
  };

  const form = (type, hidden) => (
    <PublicationForm
      current={current}
      resource={resource}
      setResource={setResource}
      setSponsored={setSponsored}
      importType={type}
      hidden={hidden}
      connections={connections}
      key={type}
    />
  );

  useEffect(() => {
    const {manuscript_number} = resource.resource_publication;
    const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
    if (manuscript_number || primary_article) {
      setSponsored(Object.hasOwn(resource.identifier.display_payer, 'title') ? resource.identifier.display_payer.title : false);
    } else {
      setSponsored(false);
    }
  }, [resource.identifier.display_payer, resource.resource_publication, resource.related_identifiers]);

  useEffect(() => {
    const selected = new Set([]);
    const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
    const preprint = resource.resource_preprint?.publication_name
      && resource.related_identifiers.find((r) => r.work_type === 'preprint')?.related_identifier;
    if (resource.resource_publication.manuscript_number) selected.add('manuscript');
    if (primary_article) selected.add('published');
    if (!primary_article && resource.resource_publication?.publication_name) selected.add('manuscript');
    if (preprint) selected.add('preprint');
    if (selected.size) setAssoc(true);
    else if (resource.identifier.import_info === 'other') setAssoc(false);
    setConnections([...selected]);
  }, []);

  return (
    <>
      {subType === 'dataset' && (
        <div className="callout alt">
          <p><i className="fas fa-circle-info" /> If your data is connected to a journal, the Data Publishing Charge may be sponsored</p>
        </div>
      )}
      <fieldset onChange={setImport}>
        <legend>
          Is your {subType} associated with a preprint, an article, or a manuscript submitted to a journal?
        </legend>
        <p className="radio_choice">
          <label><input name="assoc" type="radio" value="yes" defaultChecked={assoc === true ? 'checked' : null} />Yes</label>
          <label><input name="assoc" type="radio" value="no" required defaultChecked={assoc === false ? 'checked' : null} />No</label>
        </p>
      </fieldset>

      {sponsored && (
        <div className="callout">
          <p>Payment for this submission is sponsored by <b>{sponsored}</b></p>
        </div>
      )}

      {assoc && (
        <fieldset onChange={setOption} style={{margin: '2rem 0'}}>
          <legend>
              Which would you like to connect?
          </legend>
          <ul className="o-list" style={{marginTop: '1rem'}}>
            <li>
              <span className="radio_choice">
                <label>
                  <input name="import" type="checkbox" value="manuscript" defaultChecked={connections.includes('manuscript') ? 'checked' : null} />
                    Submitted manuscript
                </label>
              </span>
              {form('manuscript', !connections.includes('manuscript'))}
            </li>
            <li>
              <span className="radio_choice">
                <label>
                  <input name="import" type="checkbox" value="published" defaultChecked={connections.includes('published') ? 'checked' : null} />
                    Published article
                </label>
              </span>
              {form('published', !connections.includes('published'))}
            </li>
            <li>
              <span className="radio_choice">
                <label>
                  <input name="import" type="checkbox" value="preprint" defaultChecked={connections.includes('preprint') ? 'checked' : null} />
                    Preprint
                </label>
              </span>
              {form('preprint', !connections.includes('preprint'))}
            </li>
          </ul>
        </fieldset>
      )}
    </>
  );
}
