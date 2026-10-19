import React from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';
import {orderedItems} from '../DragonDropList';

export {default} from './Support';
export {default as SuppPreview} from './SuppPreview';

export const fundingCheck = (resource) => {
  const pubbed = resource.identifier.pub_state === 'published'
  const orgs = resource.contributors.filter((f) => f.contributor_type === 'funder');
  if (orgs.length < 1) {
    if (pubbed) return false;
    return (
      <p className="error-text" id="funder_error">
        Granting organization is blank. Check &quot;No funding received&quot; if there is no funding associated with the submission
      </p>
    )
  }
  const funders = orderedItems({items: orgs, typeName: 'funder'});
  const orgError = funders.findIndex((f) => !f.contributor_name);
  if (orgError >= 0) {
    return (
      <p className="error-text" id="funder_error" data-index={orgError}>
        {orgError === 0
          ? 'Granting organization is blank. Check "No funding received" if there is no funding associated with the submission'
          : `${upCase(ordinalNumber(orgError + 1))} granting organization is blank. Fill in or delete the entry`}
      </p>
    );
  }
  const groupError = funders.findIndex((f) => f.group_required);
  if (groupError >= 0) {
    return (
      <p className="error-text" id="funder_group_error">
        {upCase(ordinalNumber(groupError + 1))} granting organization requires the selection of a child institution
      </p>
    );
  }
  return false;
};
