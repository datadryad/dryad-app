import React, {useState} from 'react';
import axios from 'axios';
import PublicationForm from './PublicationForm';
import Title from './Title';

export default function Publication({resource, setResource}) {
  const [importType, setImportType] = useState(resource.identifier.import_info);

  const optionChange = (choice) => {
    setImportType(choice);
    setResource((r) => {
      r.identifier.import_info = choice;
      return r;
    });
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
    if (v === '1') {
      if (n === 'published') document.getElementById('manuscript').setAttribute('hidden', true);
      optionChange(n);
    }
    if (v === '0') {
      if (n === 'published') document.getElementById('manuscript').removeAttribute('hidden');
      optionChange('other');
    }
  };

  if (resource.title) {
    return (
      <>
        <h2>Title/Import</h2>
        <Title resource={resource} setResource={setResource} />
        <PublicationForm resource={resource} setResource={setResource} />
      </>
    );
  }
  return (
    <>
      <h2>Title/Import</h2>
      <fieldset onChange={setOption}>
        <p><legend>Is your data used in a published article?</legend></p>
        <p className="radio_choice">
          <label><input name="published" type="radio" value="1" defaultChecked={importType === 'published'} />Yes</label>
          <label><input name="published" type="radio" value="0" required defaultChecked={importType === 'manuscript'} />No</label>
        </p>
      </fieldset>
      <fieldset id="manuscript" onChange={setOption} hidden={importType !== 'manuscript'}>
        <p><legend>Is your data used in a submitted manuscript?</legend></p>
        <p className="radio_choice">
          <label className="required"><input name="manuscript" type="radio" value="1" defaultChecked={importType === 'manuscript'} />Yes</label>
          <label className="required">
            <input name="manuscript" type="radio" value="0" required defaultChecked={importType === 'published'} />No
          </label>
        </p>
      </fieldset>
      {importType !== 'other' && <PublicationForm resource={resource} setResource={setResource} importType={importType} />}
      {importType === 'other' && <Title resource={resource} setResource={setResource} />}
    </>
  );
}
