import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import KeywordAutocomplete from './KeywordAutocomplete';

function Keywords({resource, setResource}) {
  const subjects = resource.subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
  const [subjs, setSubjs] = useState(subjects);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const saveKeyword = (strKeyword) => {
    // the controller for this is a bit weird since it may accept one keyword or multiple separated by commas and it returns
    // the full list of keywords again after adding one or more
    showSavingMsg();
    axios.post(
      '/stash_datacite/subjects/create',
      {authenticity_token, subject: strKeyword, resource_id: resource.id},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status !== 200) {
        return [];
        // raise an error here if we want to catch it and display something to user or do something else
      }
      setSubjs(data.data);
      showSavedMsg();
      return data.data;
    });
  };

  function deleteKeyword(id) {
    showSavingMsg();
    axios.delete(`/stash_datacite/subjects/${id}/delete`, {
      data: {authenticity_token, resource_id: resource.id},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        return;
      }
      showSavedMsg();
      // removes the item we just deleted from the list based on id
      setSubjs(subjs.filter((item) => (item.id !== data.data.id)));
    });
  }

  useEffect(() => {
    setResource((r) => ({...r, subjects: [...r.subjects.filter((s) => ['fos', 'bad_fos'].includes(s.subject_scheme)), ...subjs]}));
  }, [subjs]);

  return (
    <div className="c-keywords">
      <label className="input__label required" id="label_keyword_ac" htmlFor="keyword_ac">
        Subject keywords
        <span className="details">(at least 3)</span>
      </label>
      <div
        id="js-keywords__container"
        className="c-keywords__container"
        role="listbox"
        aria-labelledby="label_keyword_ac"
        aria-multiselectable="true"
        aria-describedby="keywords-ex"
      >
        {subjs.map((subj) => (
          <span className="c-keywords__keyword" aria-selected="true" key={subj.id}>
            {subj.subject}
            <span className="delete_keyword">
              <button
                id={`sub_remove_${subj.id}`}
                aria-label={`Remove keyword ${subj.subject}`}
                title="Remove"
                type="button"
                className="c-keywords__keyword-remove"
                onClick={() => deleteKeyword(subj.id)}
              >
                <i className="fas fa-times" aria-hidden="true" />
              </button>
            </span>
          </span>
        ))}
        <KeywordAutocomplete
          id=""
          name=""
          saveFunction={saveKeyword}
          controlOptions={
            {
              htmlId: 'keyword_ac',
              labelText: '',
              isRequired: false,
              saveOnEnter: true,
              errorId: 'subj_error',
            }
          }
        />
      </div>
      <div id="keywords-ex"><i className="ie" />Scientific names, method types, or keywords from your related article</div>
    </div>
  );
}

export default Keywords;

Keywords.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
