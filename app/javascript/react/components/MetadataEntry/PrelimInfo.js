import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderForm from './FunderForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function PrelimInfo(){

  return (
    <>
      <div className="js-contributors_form_top">
        <p id="import-choices-label">My data is related to:</p>
      </div>

      <div className="c-import__choicesbox js-import-choice" role="group" aria-labelledby="import-choices-label">
        <div className="c-import__choicebox">
          <div className="c-import__icon"><i className="fa fa-pencil-square-o fa-3x"></i></div>
          <div>
            <input type="radio" name="import_type" id="choose_manuscript" value="manuscript"/>
            <label htmlFor="choose_manuscript">&nbsp;a manuscript in progress</label>
          </div>
        </div>

        <div className="c-import__choicebox">
          <div className="c-import__icon"><i className="fa fa-file-text-o fa-3x"></i></div>
          <div>
            <input type="radio" name="import_type" id="choose_published" value="published"/>
            <label htmlFor="choose_published">&nbsp;a published article</label>
          </div>
        </div>

        <div className="c-import__choicebox">
          <div className="c-import__icon"><i className="fa fa-table fa-3x"></i></div>
          <div>
            <input type="radio" name="import_type" id="choose_other" value="other" checked="checked"/>
            <label htmlFor="choose_other">&nbsp;other or not applicable</label>
          </div>
        </div>
      </div>
    </>
  )
}

export default PrelimInfo;
