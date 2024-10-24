import React from 'react';

export {default} from './DescriptionGroup';
export {default as DescPreview} from './DescPreview';

export const abstractCheck = (resource, review) => {
  const anydesc = resource.descriptions.some((d) => !!d.description);
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract')?.description;
  if ((review || anydesc) && !abstract) {
    return (
      <p className="error-text" id="abstract_error">An abstract is required</p>
    );
  }
  return false;
};
