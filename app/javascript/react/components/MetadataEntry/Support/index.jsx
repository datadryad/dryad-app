import React from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';

export {default} from './Support';
export {default as SuppPreview} from './SuppPreview';

export const fundingCheck = (funders) => {
  if (funders.length < 1) return true;
  const orgError = funders.findIndex((f) => !f.contributor_name);
  if (orgError >= 0) {
    return (
      <p className="error-text" id="funder_error" data-index={orgError}>
        {orgError === 0
          ? 'Granting organization is blank. Check "No funding received" if there is no funding associated with the dataset'
          : `${upCase(ordinalNumber(orgError + 1))} granting organization is blank. Fill in or delete the entry`}
      </p>
    );
  }
  const groupError = funders.findIndex((f) => f.group_required);
  if (groupError >= 0) {
    return (
      <p className="error-text" id="funder_group_error" data-index={groupError}>
        {upCase(ordinalNumber(groupError + 1))} granting organization requires the selection of a child institution
      </p>
    );
  }
  return false;
};
