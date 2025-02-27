import React from 'react';

export {default} from './Validation';

export const validationCheck = (resource) => {
  const disclaimer = resource.descriptions.find((d) => d.description_type === 'usage_notes');
  if (!disclaimer) {
    return (
      <p className="error-text" id="hsi_error">Completion of the validation questionnaire is required</p>
    );
  }
  if (disclaimer.description !== null) {
    if (disclaimer.description.split(/\s/).length < 10) {
      return <p className="error-text" id="hsi_error">Completion of the human subjects statement is required</p>;
    }
  }
  return false;
};

export function ValPreview({resource}) {
  const disclaimer = resource.descriptions.find((d) => d.description_type === 'usage_notes');

  if (disclaimer) {
    return (
      <p>
        <i className="fa-solid fa-circle-check" aria-hidden="true" />{' '}
        The data {disclaimer.description ? 'contains' : 'does not contain'} information on human subjects.
        {disclaimer.description?.split(/\s/)?.length > 9 && ' The human subjects data statement appears in the README.'}
      </p>
    );
  }
  return null;
}
