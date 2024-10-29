import React from 'react';
import {formatSizeUnits} from '../../../lib/utils';
import {maxFiles, maxSize, maxZenodo} from './maximums';

export {default} from './UploadFiles';
export {default as FilesPreview} from './FilesPreview';

export const filesCheck = (files, review, admin) => {
  if (files.length > 0) {
    const present = files.filter((f) => f.file_state !== 'deleted');
    const data = present.filter((f) => f.type === 'StashEngine::DataFile' && f.upload_file_name !== 'README.md');
    const software = present.filter((f) => f.type === 'StashEngine::SoftwareFile');
    const supp = present.filter((f) => f.type === 'StashEngine::SuppFile');
    if (!data.some((f) => !f.upload_file_name.includes('README'))) {
      return (
        <p className="error-text" id="data_error">Data files submitted to Dryad are required</p>
      );
    }
    if (present.length > maxFiles) {
      return (
        <p className="error-text" id="data_error">A maximum of {maxFiles} files can be uploaded per submission. Remove files to proceed</p>
      );
    }
    if (admin !== 'superuser' && data.reduce((sum, f) => sum + f.upload_file_size, 0) > maxSize) {
      return (
        <p className="error-text" id="data_error">
        Total data file uploads are limited to {formatSizeUnits(maxSize)} per submission. Remove files to proceed
        </p>
      );
    }
    if (software.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p className="error-text" id="software_error">
        Total software file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Remove files to proceed
        </p>
      );
    }
    if (supp.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p className="error-text" id="supp_error">
        Total supplemental file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Remove files to proceed
        </p>
      );
    }
    const urlErrors = present.filter((f) => !!f.url && f.status_code !== 200);
    if (urlErrors.length > 0) {
      return (
        <p className="error-text" id="data_error">
          Individual files cannot be retrieved from the URLs for the following URL upload files.
          Please check that the URLs are valid, publically accessible, and point to individual file downloads:<br />
          {urlErrors.map((f) => f.upload_file_name).join(', ')}
        </p>
      );
    }
  } else if (review) {
    return <p className="error-text" id="data_error">Files are required</p>;
  }
  return false;
};
