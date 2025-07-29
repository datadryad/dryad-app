import React from 'react';

export {default} from './Compliance';

export const complianceCheck = (resource) => {
  const {license_id} = resource.identifier;
  const disclaimer = resource.descriptions.find((d) => d.description_type === 'usage_notes');
  if (!license_id) {
    return (
      <p className="error-text" id="license_error">Completion of the compliance questionnaire is required</p>
    );
  }
  if (!disclaimer) {
    return (
      <p className="error-text" id="hsi_error">Completion of the compliance questionnaire is required</p>
    );
  }
  if (disclaimer.description !== null) {
    if (disclaimer.description.split(/\s/).length < 10) {
      return <p className="error-text" id="hsi_error">A human subjects statement of at least 10 words is required</p>;
    }
  }
  return false;
};

export function CompPreview({resource, previous}) {
  const {license_id} = resource.identifier;
  const disclaimer = resource.descriptions.find((d) => d.description_type === 'usage_notes');
  const prev = previous?.descriptions.find((d) => d.description_type === 'usage_notes');
  const diff = previous && disclaimer?.description !== prev?.description;
  return (
    <>
      {diff && <ins />}
      {license_id === 'cc0' && (
        <p>
          <i className="fa-solid fa-circle-check" aria-hidden="true" />{' '}
          Data submitted will be published under the{' '}
          <a href="https://creativecommons.org/publicdomain/zero/1.0/" target="_blank" rel="noreferrer">
          Public domain
            <span role="img" aria-label="CC0 (opens in new window)" style={{marginLeft: '.25ch'}}>
              <i className="fab fa-creative-commons" aria-hidden="true" />
              <i className="fab fa-creative-commons-zero" aria-hidden="true" />
            </span>
          </a>{' '}license waiver.
        </p>
      )}
      {disclaimer && (
        <p>
          <i className="fa-solid fa-circle-check" aria-hidden="true" />{' '}
          The data {disclaimer.description !== null ? 'contains' : 'does not contain'} information on human subjects.
          {disclaimer.description?.split(/\s/)?.length > 9 && ' The human subjects data statement appears in the README.'}
        </p>
      )}
    </>
  );
}
