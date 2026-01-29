import React, {useState, useEffect, useCallback} from 'react';
import axios from 'axios';
import {debounce} from 'lodash';
import MarkdownEditor from '../../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

export default function Description({setResource, dcsDescription, mceLabel}) {
  const [desc, setDesc] = useState(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = (value) => {
    const subJson = {
      authenticity_token,
      description: {
        description: value,
        resource_id: dcsDescription.resource_id,
        id: dcsDescription.id,
        description_type: dcsDescription.description_type,
      },
    };
    showSavingMsg();
    axios.patch(
      '/stash_datacite/descriptions/update',
      subJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.data && typeof setResource === 'function') {
          setResource((r) => ({
            ...r,
            descriptions: [{...dcsDescription, description: data.data.description}, ...r.descriptions.filter((d) => d.id !== dcsDescription.id)],
          }));
        }
        showSavedMsg();
      });
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  useEffect(() => {
    const div = document.createElement('div');
    div.innerHTML = dcsDescription.description;
    setDesc(div);
  }, [dcsDescription]);

  return (
    <>
      <div className="input-line spaced" style={{marginBottom: '-.75em'}}>
        <span
          className={`input-label xl${(mceLabel.required ? ' required' : ' optional')}`}
          id={`${dcsDescription?.description_type}_label`}
        >
          {mceLabel.label}
        </span>
        {mceLabel.describe && <div id={`${dcsDescription?.description_type}-ex`}>{mceLabel.describe}</div>}
      </div>
      {desc && (
        <MarkdownEditor
          id={`${dcsDescription?.description_type}-editor`}
          attr={{
            'aria-errormessage': `${dcsDescription?.description_type}_error`,
            'aria-labelledby': `${dcsDescription?.description_type}_label`,
            'aria-describedby': `${dcsDescription?.description_type}-ex`,
            name: dcsDescription?.description_type,
          }}
          htmlInput={desc}
          key={desc?.innerHTML}
          onChange={checkSubmit}
        />
      )}
    </>
  );
}
