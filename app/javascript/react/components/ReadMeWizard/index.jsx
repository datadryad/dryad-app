import React, {useRef, useEffect} from 'react';
import axios from 'axios';

export {default} from './ReadMeWizard';

export const readmeCheck = (resource, review) => {
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
  } else if (review) {
    return <p className="error-text" id="readme_error">A README is required</p>;
  }
  return false;
};

export function ReadMePreview({resource}) {
  const readmeRef = useRef(null);

  const getREADME = () => {
    axios.get(`/stash/resources/${resource.id}/display_readme`).then((data) => {
      const active_readme = document.createRange().createContextualFragment(data.data);
      readmeRef.current.append(active_readme);
    });
  };

  useEffect(() => {
    if (readmeRef.current) {
      getREADME();
    }
  }, [resource, readmeRef]);

  if (resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description) {
    return (
      <div ref={readmeRef} />
    );
  }
  return null;
}
