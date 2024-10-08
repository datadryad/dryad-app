import React from 'react';

export {default} from './ReadMeWizard';

export const readmeCheck = (resource) => {
  const readme = resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  if (readme) {
    try {
      const obj = JSON.parse(readme);
      if (typeof obj === 'object') {
        return (
          <p className="error-text" id="readme_error">A completed README is required</p>
        );
      }
    } catch (e) {
      return false;
    }
  }
  return false;
};
