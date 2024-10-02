import React from 'react';
import {upCase} from '../../../../lib/utils';

export {default} from './Authors';

const ordinal = ['zeroth', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth',
  'ninth', 'tenth', 'eleventh', 'twelfth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth',
  'seventeenth', 'eighteenth', 'nineteenth'];
const deca = ['twent', 'thirt', 'fort', 'fift', 'sixt', 'sevent', 'eight', 'ninet'];

const ordinalNumber = (n) => {
  if (n < 20) return ordinal[n];
  if (n % 10 === 0) return `${deca[Math.floor(n / 10) - 2]}ieth`;
  return `${deca[Math.floor(n / 10) - 2]}y-${ordinal[n % 10]}`;
};

export const authorCheck = (authors, id) => {
  if (!authors.find((a) => a.id === id)?.author_email) {
    return (
      <p className="error-text" id="author_email_error">Submitting author email is required</p>
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
  const affErr = authors.findIndex((a) => !a.affiliations[0]?.long_name);
  if (affErr >= 0) {
    return (
      <p className="error-text" id="author_aff_error" data-index={affErr}>{upCase(ordinalNumber(affErr + 1))} author affiliation is required</p>
    );
  }
  return false;
};
