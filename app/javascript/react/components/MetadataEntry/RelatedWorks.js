import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import RelatedWorkForm from './RelatedWorkForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function RelatedWorks(
    {relatedIdentifiers,
    workTypes}
) {
  return (
      <fieldset className="c-fieldset">
        <legend className="c-fieldset__legend">
          <span className="c-input__hint">
            Are there any preprints, articles, datasets, software packages, or supplemental
            information that have resulted from or are related to this Data Publication?
          </span>
        </legend>
        <div className="replaceme-related-works">
          {relatedIdentifiers.map((relatedIdentifier) => (
              <RelatedWorkForm
                  key={relatedIdentifier.id}
                  relatedIdentifier={relatedIdentifier}
                  workTypes={workTypes}
              />
          ))}
        </div>
      </fieldset>
  );
}

export default RelatedWorks;