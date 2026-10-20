import React, {useState, useRef, useEffect, useCallback} from 'react';
import axios from 'axios';
import {debounce} from 'lodash';
import MarkdownEditor from '../../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function Title({resource, setResource, setTouched}) {
  const prevTitle = useRef('');
  const [value, setValue] = useState(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = (newValue) => {
    showSavingMsg();
    prevTitle.current = newValue
    axios.patch(
      '/stash_datacite/titles/update',
      {authenticity_token, id: resource.id, title: newValue},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.data) {
          const {descriptions, title} = data.data;
          setResource((r) => ({...r, title, descriptions}));
        }
        showSavedMsg();
      });
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  const onBlur = async() => {
    checkSubmit.flush();
    /* eslint-disable-next-line no-undef */
    await awaitSelector('.saving_text[hidden]');
    setTouched(true);
  }

  useEffect(() => {
    if (resource.title?.trim() !== prevTitle.current?.trim()) {
      if (document.activeElement?.getAttribute('name') !== 'title') {
        const p = document.createElement('p');
        p.innerHTML = resource.title;
        setValue(p);
      }
      prevTitle.current = resource.title;
    }
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
            name: 'title',
          }}
          buttons={['emphasis', 'superscript', 'subscript']}
          htmlInput={value}
          id={`title__${resource.id}`}
          key={value?.innerHTML}
          onChange={checkSubmit}
          onBlur={onBlur}
        />
      )}
      <div id="title-ex"><i aria-hidden="true" />The title should be a succinct summary of the data and its purpose or use</div>
    </div>
  );
}

export default Title;
