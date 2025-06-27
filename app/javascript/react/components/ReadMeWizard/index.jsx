import React from 'react';

export {default} from './ReadMeWizard';
export {default as ReadMePreview} from './ReadMePreview';

export const readmeCheck = (resource) => {
  const {descriptions, identifier: {publication_date}, generic_files: files} = resource;
  if (files === undefined) return false;
  const readme = descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const markdownFile = files.filter((f) => f.file_state !== 'deleted' && f.type === 'StashEngine::DataFile' && f.download_filename === 'README.md');
  const readmeFile = files.filter((f) => f.file_state !== 'deleted' && f.type === 'StashEngine::DataFile' && f.download_filename.includes('README'));
  if (readme) {
    try {
      const obj = JSON.parse(readme);
      if (typeof obj === 'object') {
        return (
          <p className="error-text" id="readme_error">
            A completed README is required.
            Complete each section of the README generator, and click the &quot;Next&quot; buttons,{' '}
            until you are able to &quot;Complete &amp; generate&quot; your README
          </p>
        );
      }
    } catch (e) {
      return false;
    }
  }
  if (!publication_date || publication_date > new Date('2022-09-28')) {
    if (!markdownFile) return <p className="error-text" id="readme_error">A README is required</p>;
  } else if (publication_date > new Date('2021-12-20')) {
    if (!readmeFile) return <p className="error-text" id="readme_error">A README is required</p>;
  }
  return false;
};
