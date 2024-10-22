import React from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';

export {default} from './Authors';
export {default as AuthPreview} from './AuthPreview';

export const authorCheck = (authors, id) => {
  if (!authors.find((a) => a.id === id)?.author_email) {
    const ind = authors.findIndex((a) => a.id === id);
    return (
      <p className="error-text" id="author_email_error" data-index={ind}>Submitting author email is required</p>
    );
  }
  const fnameErr = authors.findIndex((a) => !a.author_first_name);
  if (fnameErr >= 0) {
    return (
      <p className="error-text" id="author_fname_error" data-index={fnameErr}>
        {upCase(ordinalNumber(fnameErr + 1))} author first name is required
      </p>
    );
  }
  const lnameErr = authors.findIndex((a) => !a.author_last_name);
  if (lnameErr >= 0) {
    return (
      <p className="error-text" id="author_lname_error" data-index={lnameErr}>
        {upCase(ordinalNumber(lnameErr + 1))} author last name is required
      </p>
    );
  }
  const affErr = authors.findIndex((a) => !a.affiliations?.[0]?.long_name);
  if (affErr >= 0) {
    return (
      <p className="error-text" id="author_aff_error" data-index={affErr}>{upCase(ordinalNumber(affErr + 1))} author affiliation is required</p>
    );
  }
  return false;
};
