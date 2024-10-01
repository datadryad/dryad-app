import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PublicationForm from './PublicationForm';
import Title from './Title';

export default function Publication({resource, setResource}) {
  const [importType, setImportType] = useState(resource.identifier.import_info);
  const [checks, setChecks] = useState({published: false, manuscript: false, showTitle: false});

  const optionChange = (choice) => {
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
      });
  };
  const setOption = (e) => {
    const n = e.target.name;
    const v = e.target.value;
    setChecks((s) => ({...s, [n]: v}));
    if (v === 'yes') optionChange(n);
    if (v === 'no') optionChange('other');
  };

  useEffect(() => {
    const {publication_name, manuscript_number} = resource.resource_publication;
    const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article');
    if (publication_name && (manuscript_number || primary_article)) {
      setChecks((s) => ({...s, showTitle: 'yes'}));
    } else if (!resource.title) {
      setChecks((s) => ({...s, showTitle: 'no'}));
    }
  }, [resource]);

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
        <p><legend>Is your data used in a published article?</legend></p>
        <p className="radio_choice">
          <label><input name="published" type="radio" value="yes" defaultChecked={checks.published === 'yes' ? 'checked' : null} />Yes</label>
          <label><input name="published" type="radio" value="no" required defaultChecked={checks.published === 'no' ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      <fieldset id="manuscript" onChange={setOption} hidden={!checks.published || checks.published === 'yes'}>
        <p><legend>Is your data used in a submitted manuscript?</legend></p>
        <p className="radio_choice">
          <label><input name="manuscript" type="radio" value="yes" defaultChecked={checks.manuscript === 'yes' ? 'checked' : null} />Yes</label>
          <label><input name="manuscript" type="radio" value="no" required defaultChecked={checks.manuscript === 'no' ? 'checked' : null} />No</label>
        </p>
      </fieldset>
      {importType !== 'other' && <PublicationForm resource={resource} setResource={setResource} importType={importType} />}
      {((checks.published === 'no' && checks.manuscript === 'no') || checks.showTitle === 'yes') && (
        <Title resource={resource} setResource={setResource} />
      )}
    </>
  );
}
