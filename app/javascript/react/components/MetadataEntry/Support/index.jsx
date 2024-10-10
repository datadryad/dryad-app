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

const contribName = (name) => (name.endsWith('*') ? name.slice(0, -1) : name);

export function SuppPreview({resource, admin}) {
  const facility = resource.contributors.find((c) => c.contributor_type === 'sponsor');
  const funders = resource.contributors.filter((c) => c.contributor_type === 'funder');
  return (
    <>
      {facility && facility.contributor_name && (
        <div className="o-metadata__group2-item">
          Research facility: {facility.contributor_name}
        </div>
      )}
      {funders.length > 0 && funders[0].contributor_name !== 'N/A' && (
        <>
          <h3>Funding</h3>
          <ul className="o-list">
            {funders.map((funder) => (
              <li>
                <span>
                  {contribName(funder.contributor_name)}
                  {admin && !funder.name_identifier_id && (
                    <i className="fas fa-triangle-exclamation unmatched-icon" role="note" aria-label="Unmatched funder" title="Unmatched funder" />
                  )}
                </span>
                {funder.award_number && <>, <span>{funder.award_number}</span></>}
                {funder.award_description && <>: <span>{funder.award_description}</span></>}
              </li>
            ))}
          </ul>
        </>
      )}
    </>
  );
}
