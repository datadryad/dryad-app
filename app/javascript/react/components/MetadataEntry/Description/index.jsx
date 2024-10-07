import React from 'react';

export {default} from './DescriptionGroup';

export const abstractCheck = (resource) => {
  const anydesc = resource.descriptions.some((d) => !!d.description);
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract')?.description;
  if (anydesc && !abstract) {
    return (
      <p className="error-text" id="abstract_error">An abstract is required</p>
    );
  }
  return false;
};
