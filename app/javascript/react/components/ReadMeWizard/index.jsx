import React, {useRef, useEffect} from 'react';
import axios from 'axios';

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
  return <p className="error-text" id="readme_error">A README is required</p>;
};

export function ReadMePreview({resource, previous, curator}) {
  const readmeRef = useRef(null);
  const readme = resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const prev = previous?.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const diff = curator && previous && readme !== prev;

  const getREADME = () => {
    axios.get(`/resources/${resource.id}/display_readme${diff ? '?admin' : ''}`).then((data) => {
      const active_readme = document.createRange().createContextualFragment(data.data);
      readmeRef.current.append(active_readme);
    });
  };

  useEffect(() => {
    if (readmeRef.current) {
      getREADME();
    }
  }, [resource, readmeRef]);

  if (readme || diff) {
    return (
      <div ref={readmeRef}>{diff && <ins />}</div>
    );
  }
  if (prev) {
    return <del>README removed</del>;
  }
  return null;
}
