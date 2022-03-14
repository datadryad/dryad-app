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

  function SubjDisplay({subj}){
    return (
        <span className="c-keywords__keyword">
          {subj.subject}
          <span className="delete_keyword">
            <a id={`sub_remove_${subj.id}`}
               aria-label="Remove this keyword"
               role="button"
               className="c-keywords__keyword-remove"
               rel="nofollow"
            ></a>
          </span>
        </span>
    );
  }

  function saveKeyword(strKeyword){
    // this controller is a bit weird since it may accept one keyword or multiple separated by commas and it returns
    // the full list of keywords again after changing one or more
    console.log('Saving keyword here');
    axios.post(createPath, {authenticity_token: csrf, subject: strKeyword, resource_id: resourceId},
        { headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'} }
    ).then((data) => {
      if (data.status !== 200) {
        return [];
        // raise an error here if we want to catch it and display something to user or do something else
      }
      debugger;
    });
  }

  return (
      <div className='c-keywords'>
        <label className="c-input__label" htmlFor="keyword">Keywords:</label>
        &nbsp;&nbsp;Adding keywords improves the findability of your dataset. E.g. scientific names, method type

        <div id="js-keywords__container" className="c-keywords__container c-keywords__container--has-blur">
          {subjects.map(subj => <SubjDisplay subj={subj} key={subj.id} /> )}
          <KeywordAutocomplete id='' name='' saveFunction={saveKeyword} controlOptions={
            { htmlId: `keyword_ac`,
              labelText: 'Keyword',
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