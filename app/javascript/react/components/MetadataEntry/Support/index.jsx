import React from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';

export {default} from './Support';

export const fundingCheck = (funders) => {
  if (funders.length < 1) return false;
  const orgError = funders.findIndex((f) => !f.contributor_name);
  if (orgError >= 0) {
    return (
      <p className="error-text" id="funder_error" data-index={orgError}>
        {upCase(ordinalNumber(orgError + 1))} granting organization is required.
        {orgError === 0 ? ' Check "No funding received" if there is no funding associated with the dataset.' : ''}
      </p>
    );
  }
  return false;
};
