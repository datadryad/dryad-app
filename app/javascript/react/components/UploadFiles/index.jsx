import React from 'react';
import {formatSizeUnits} from '../../../lib/utils';
import {maxFiles, maxSize, maxZenodo} from './maximums';

export {default} from './UploadFiles';

export const filesCheck = (files) => {
  if (files.length > 0) {
    const present = files.filter((f) => f.file_state !== 'deleted');
    const data = present.filter((f) => f.type === 'StashEngine::DataFile' && f.upload_file_name !== 'README.md');
    const software = present.filter((f) => f.type === 'StashEngine::SoftwareFile');
    const supp = present.filter((f) => f.type === 'StashEngine::SuppFile');
    if (!data.some((f) => !f.upload_file_name.includes('README'))) {
      return (
        <p>Data files submitted to Dryad are required</p>
      );
    }
    if (present.length > maxFiles) {
      return (
        <p>A maximum of {maxFiles} files can be uploaded per submission. Remove files to proceed</p>
      );
    }
    if (data.reduce((sum, f) => sum + f.upload_file_size, 0) > maxSize) {
      return (
        <p>Total data file uploads are limited to {formatSizeUnits(maxSize)} per submission. Remove files to proceed</p>
      );
    }
    if (software.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p>Total software file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Remove files to proceed</p>
      );
    }
    if (supp.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p>Total supplemental file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Remove files to proceed</p>
      );
    }
  }
  return false;
};

const fileList = (list) => (
  <ul className="c-review-files__list">
    {list.map((f) => (
      <li key={f.id}>{f.upload_file_name} <span className="file_size">{formatSizeUnits(f.upload_file_size)}</span></li>
    ))}
  </ul>
);

export function FilesPreview({resource}) {
  const present = resource.generic_files.filter((f) => f.file_state !== 'deleted');
  const data = present.filter((f) => f.type === 'StashEngine::DataFile' && f.upload_file_name !== 'README.md');
  const software = present.filter((f) => f.type === 'StashEngine::SoftwareFile');
  const supp = present.filter((f) => f.type === 'StashEngine::SuppFile');

  if (present.length > 0) {
    return (
      <>
        {data.length > 0 && (
          <>
            <h3 className="o-heading__level2">Data files hosted by Dryad</h3>
            {fileList(data)}
          </>
        )}
        {software.length > 0 && (
          <>
            <h3 className="o-heading__level2">Software files hosted by <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<span className="screen-reader-only"> (opens in new window)</span></a></h3>
            <ul className="c-review-files__list">
              {fileList(software)}
            </ul>
          </>
        )}
        {supp.length > 0 && (
          <>
            <h3 className="o-heading__level2">Supplemental files hosted by <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<span className="screen-reader-only"> (opens in new window)</span></a></h3>
            <ul className="c-review-files__list">
              {fileList(supp)}
            </ul>
          </>
        )}
      </>
    );
  }
  return null;
}
