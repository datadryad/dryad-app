import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderAutocomplete from './FunderAutocomplete';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';

function Keywords({resourceId, subjects, createPath, deletePath}) {

  function SubjDisplay({subj}){

    console.log(subj);

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

  return (
      <div className='c-keywords'>
        <label className="c-input__label" htmlFor="keyword">Keywords:</label>
        &nbsp;&nbsp;Adding keywords improves the findability of your dataset. E.g. scientific names, method type

        <div id="js-keywords__container" className="c-keywords__container c-keywords__container--has-blur">
          {subjects.map(subj => <SubjDisplay subj={subj}/> )}
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