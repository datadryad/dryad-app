import React from 'react';
import {formatSizeUnits} from '../../../lib/utils';

export {default} from './UploadFiles';
export {default as FilesPreview} from './FilesPreview';

export const filesCheck = (files, admin, maximums) => {
  const {files: maxFiles, zenodo_size: maxZenodo, merritt_size: maxSize} = maximums;
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
    if (data.length > maxFiles) {
      return (
        <p className="error-text" id="data_error">A maximum of {maxFiles} data files can be uploaded per submission. Remove files to proceed</p>
      );
    }
    if (admin !== 'superuser' && data.reduce((sum, f) => sum + f.upload_file_size, 0) > maxSize) {
      return (
        <p className="error-text" id="data_error">
        Total data file uploads are limited to {formatSizeUnits(maxSize)} per submission. Remove data files to proceed
        </p>
      );
    }
    if (software.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p className="error-text" id="software_error">
        Total software file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Remove software files to proceed
        </p>
      );
    }
    if (software.length > maxFiles) {
      return (
        <p className="error-text" id="data_error">
          A maximum of {maxFiles} software files can be uploaded per submission. Remove software files to proceed
        </p>
      );
    }
    if (supp.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p className="error-text" id="supp_error">
        Total supplemental file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Remove supplemental files to proceed
        </p>
      );
    }
    if (supp.length > maxFiles) {
      return (
        <p className="error-text" id="data_error">
          A maximum of {maxFiles} supplemental files can be uploaded per submission. Remove files to proceed
        </p>
      );
    }
    const urlErrors = present.filter((f) => !!f.url && f.status_code !== 200);
    if (urlErrors.length > 0) {
      return (
        <p className="error-text" id="data_error">
          Files cannot be retrieved from the URLs for the following URL uploads.
          Please remove them and try again, ensuring the URLs are valid, publically accessible, and point to individual files:<br />
          {urlErrors.map((f) => f.upload_file_name).join(', ')}
        </p>
      );
    }
    const uploadErrors = data.filter((f) => !f.dl_url && f.status === 'Uploaded');
    if (uploadErrors.length > 0) {
      return (
        <p className="error-text" id="data_error">
          There was an error with the following upload{uploadErrors.length > 1 && 's'}. Please remove them and try again:<br />
          {uploadErrors.map((f) => f.upload_file_name).join(', ')}
        </p>
      );
    }
    return false;
  }
  return <p className="error-text" id="data_error">Files are required</p>;
};
