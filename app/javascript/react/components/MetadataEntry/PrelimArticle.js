import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function PrelimArticle(){
  return (
      <div className="c-import__form-section">
        <p>Please provide the following information. You may either enter the information and leave it or choose to
          autofill your dataset based on the information you supply below.</p>

        <div className="c-input__inline">
          <div className="c-input">
            <label className="c-input__label required" htmlFor="publication">Journal Name</label>
            <input className="c-input__text ui-autocomplete-input" type="text" name="publication" id="publication" />
            <input value="419" type="hidden" name="identifier_id" id="identifier_id" />
            <input value="3621" type="hidden" name="resource_id" id="resource_id" />
            <input type="hidden" name="publication_issn" id="publication_issn" />
            <input type="hidden" name="publication_name" id="publication_name" />
          </div>
          <div className="c-input" style={{display: 'flex'}}>
            <label className="c-input__label required" htmlFor="primary_article_doi">DOI</label>
            <input className="c-input__text" placeholder="5702.125/qlm.1266rr" type="text"
                   name="primary_article_doi" id="primary_article_doi" />
          </div>
        </div>
        <div>
          <input type="submit" name="commit" value="Import Article Metadata" method="post"
                 className="o-button__import-manuscript" />
        </div>
        <div id="population-warnings" className="o-metadata__autopopulate-message">
          Sample warning here.
        </div>
      </div>
  );
}

export default PrelimArticle;