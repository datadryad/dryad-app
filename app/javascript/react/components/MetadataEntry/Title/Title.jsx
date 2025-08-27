import React, {useState, useEffect, useCallback} from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import {debounce} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function Title({resource, setResource}) {
  const [value, setValue] = useState('');
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
    setValue(`${resource.title || ''}`);
  }, [resource.title]);

  return (
    <form style={{margin: '1em auto'}} className="input-stack">
      <label className="required input-label" htmlFor={`title__${resource.id}`}>
        Submission title
      </label>
      <input
        name="title"
        type="text"
        className="title c-input__text"
        id={`title__${resource.id}`}
        value={value}
        onBlur={(e) => submit(e.target.value)}
        onChange={(e) => {
          setValue(e.target.value);
          checkSubmit(e.target.value);
        }}
        required
        aria-describedby="title-ex"
        aria-errormessage="title_error"
      />
      <div id="title-ex"><i aria-hidden="true" />The title should be a succinct summary of the data and its purpose or use</div>
    </form>
  );
}

// This has some info https://blog.logrocket.com/validating-react-component-props-with-prop-types-ef14b29963fc/
Title.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};

export default Title;
