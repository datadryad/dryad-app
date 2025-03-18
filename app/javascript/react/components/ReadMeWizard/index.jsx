import React, {useRef, useEffect} from 'react';
import axios from 'axios';

export {default} from './ReadMeWizard';

export const readmeCheck = (resource) => {
  const {descriptions, identifier: {publication_date}, generic_files: files} = resource;
  const readme = descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const markdownFile = files.filter((f) => f.file_state !== 'deleted' && f.type === 'StashEngine::DataFile' && f.upload_file_name === 'README.md');
  const readmeFile = files.filter((f) => f.file_state !== 'deleted' && f.type === 'StashEngine::DataFile' && f.upload_file_name.startsWith('README'));
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
  if (!publication_date || publication_date > new Date('2023-08-29')) {
    return <p className="error-text" id="readme_error">A README is required</p>;
  } if (publication_date > new Date('2022-09-28')) {
    if (!markdownFile) return <p className="error-text" id="readme_error">A README is required</p>;
  } else if (publication_date > new Date('2021-12-20')) {
    if (!readmeFile) return <p className="error-text" id="readme_error">A README is required</p>;
  }
  return false;
};

export function ReadMePreview({resource, previous, curator}) {
  const readmeRef = useRef(null);
  const readme = resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const prev = previous?.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const diff = previous && readme !== prev;

  const getREADME = () => {
    axios.get(`/resources/${resource.id}/display_readme${curator && diff ? '?admin' : ''}`).then((data) => {
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
