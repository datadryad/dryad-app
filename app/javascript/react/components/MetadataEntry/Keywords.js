import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderAutocomplete from './FunderAutocomplete';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';
import KeywordAutocomplete from "./KeywordAutocomplete";

function Keywords({resourceId, subjects, createPath, deletePath}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const [subjs, setSubjs] = useState(subjects);

  function SubjDisplay({subj}){
    return (
        <span className="c-keywords__keyword">
          {subj.subject}
          <span className="delete_keyword">
            <a id={`sub_remove_${subj.id}`}
               href='#'
               aria-label="Remove this keyword"
               role="button"
               className="c-keywords__keyword-remove"
               rel="nofollow"
               onClick={(e) => {
                 e.preventDefault();
                 deleteKeyword(subj.id)
               }}
            ></a>
          </span>
        </span>
    );
  }

  function saveKeyword(strKeyword){
    // the controller for this is a bit weird since it may accept one keyword or multiple separated by commas and it returns
    // the full list of keywords again after adding one or more
    axios.post(createPath, {authenticity_token: csrf, subject: strKeyword, resource_id: resourceId},
        { headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'} }
    ).then((data) => {
      if (data.status !== 200) {
        return [];
        // raise an error here if we want to catch it and display something to user or do something else
      }
      setSubjs(data.data);
    });
  }

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
      <div className='c-keywords'>
        <label className="c-input__label" htmlFor="keyword">Keywords:</label>
        &nbsp;&nbsp;Adding keywords improves the findability of your dataset. E.g. scientific names, method type

        <div id="js-keywords__container" className="c-keywords__container c-keywords__container--has-blur">
          {subjs.map(subj => <SubjDisplay subj={subj} key={subj.id} /> )}
          <KeywordAutocomplete id='' name='' saveFunction={saveKeyword} controlOptions={
            { htmlId: `keyword_ac`,
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

/*
<input type="text" name="subject" id="keyword"
                   className="js-keywords__input c-keywords__input ui-autocomplete-input" autoComplete="off">
*/

// resourceId, origID, contributor, createPath, updatePath, removeFunction

Keywords.propTypes = {
  /*
  resourceId: PropTypes.string.isRequired,
  origID: PropTypes.string.isRequired,
  contributor: PropTypes.object.isRequired,
  createPath: PropTypes.string.isRequired,
  updatePath: PropTypes.string.isRequired,
  removeFunction: PropTypes.func.isRequired,
   */
};