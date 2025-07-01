import React from 'react';

function ReadmeWarning({resource}) {
  const {descriptions, generic_files: files} = resource;
  const readme = descriptions.find((d) => d.description_type === 'technicalinfo')?.description;

  if (files === undefined) return null;

  const present = files.filter((f) => f.file_state !== 'deleted');
  const data = present.filter((f) => f.type === 'StashEngine::DataFile' && f.upload_file_name !== 'README.md');

  if (readme) {
    try {
      const obj = JSON.parse(readme);
      if (typeof obj === 'object') return null;
    } catch (e) {
      const missing = data.filter((f) => !readme.includes(f.download_filename));
      if (missing.length) {
        return (
          <div className="callout warn" style={{margin: '1rem 0'}}>
            <p><i className="fas fa-triangle-exclamation" aria-hidden="true" /> The following files from your dataset are not listed in the README</p>
            <ul>{missing.map((f) => <li key={f.id}>{f.download_filename}</li>)}</ul>
          </div>
        );
      }
    }
  }
  return null;
}

export default ReadmeWarning;
