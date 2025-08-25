import React, {useState, useEffect, useCallback} from 'react';
import axios from 'axios';
import {debounce} from 'lodash';
import MarkdownEditor from '../../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function Title({resource, setResource}) {
  const [value, setValue] = useState(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = (newValue) => {
    showSavingMsg();
    axios.patch(
      '/stash_datacite/titles/update',
      {authenticity_token, id: resource.id, title: newValue},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log('Not a 200 response while saving Title form');
        }
        if (data.data) {
          const {descriptions, title} = data.data;
          setResource((r) => ({...r, title, descriptions}));
        }
        showSavedMsg();
      });
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  useEffect(() => {
    const p = document.createElement('p');
    p.innerHTML = resource.title;
    setValue(p);
  }, [resource.title]);

  return (
    <div style={{margin: '1em auto'}}>
      <label className="required input-label" htmlFor={`title__${resource.id}`} id={`title__${resource.id}_label`}>
        Submission title
      </label>
      {value && (
        <MarkdownEditor
          micro
          attr={{
            'aria-errormessage': 'title_error',
            'aria-labelledby': `title__${resource.id}_label`,
            'aria-describedby': 'title-ex',
          }}
          buttons={['emphasis', 'superscript', 'subscript']}
          htmlInput={value}
          id={`title__${resource.id}`}
          onChange={checkSubmit}
        />
      )}
      <div id="title-ex"><i aria-hidden="true" />The title should be a succinct summary of the data and its purpose or use</div>
    </div>
  );
}

export default Title;
