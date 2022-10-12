import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import KeywordAutocomplete from './KeywordAutocomplete';

function Keywords({
  resourceId, subjects, createPath, deletePath,
}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const [subjs, setSubjs] = useState(subjects);

  // passing this in as a normal function below caused some eslint issues.  But probably not really a problem for it being used once.
  // See https://dmitripavlutin.com/dont-overuse-react-usecallback/  .  Good to switch to "useCallback" for long lists
  // of items where function may be recreated multiple times.  Probably not needed here.
  const saveKeyword = (strKeyword) => {
    // the controller for this is a bit weird since it may accept one keyword or multiple separated by commas and it returns
    // the full list of keywords again after adding one or more
    showSavingMsg();
    axios.post(
      createPath,
      {authenticity_token: csrf, subject: strKeyword, resource_id: resourceId},
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
    // takes the params id and deletes the subject, subj_xoxo
    const trueDelPath = deletePath.replace('subj_xoxo', id);
    axios.delete(trueDelPath, {
      data: {authenticity_token: csrf},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        return;
      }
      // removes the item we just deleted from the list based on id
      setSubjs(subjs.filter((item) => (item.id !== data.data.id)));
    });
  }

  return (
    <div className="c-keywords">
      <label className="c-input__label" htmlFor="keyword_ac">Keywords:</label>
        &nbsp;&nbsp;Adding keywords improves the findability of your dataset. E.g. scientific names, method type

      <div id="js-keywords__container" className="c-keywords__container c-keywords__container--has-blur">
        {subjs.map((subj) => (
          <span className="c-keywords__keyword" key={subj.id}>
            {subj.subject}
            <span className="delete_keyword">
              {/* eslint-disable jsx-a11y/anchor-has-content, jsx-a11y/anchor-is-valid */}
              <a
                id={`sub_remove_${subj.id}`}
                href="#"
                aria-label="Remove this keyword"
                role="button"
                className="c-keywords__keyword-remove"
                rel="nofollow"
                onClick={(e) => {
                  e.preventDefault();
                  deleteKeyword(subj.id);
                }}
              />
              {/* eslint-enable jsx-a11y/anchor-has-content, jsx-a11y/anchor-is-valid */}
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
            }
          }
        />
      </div>
    </div>
  );
}

export default Keywords;

Keywords.propTypes = {
  resourceId: PropTypes.number.isRequired,
  subjects: PropTypes.array.isRequired,
  createPath: PropTypes.string.isRequired,
  deletePath: PropTypes.string.isRequired,
};
