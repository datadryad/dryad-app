import React from 'react';
import {formatSizeUnits} from '../../../lib/utils';

export {default} from './UploadFiles';
export {default as FilesPreview} from './FilesPreview';

export const filesCheck = (resource, superuser, maximums) => {
  const {generic_files: files, identifier: {publication_date, new_upload_size_limit}} = resource;
  const {
    files: maxFiles, zenodo_size: maxZenodo, merritt_size: oldSize, upload_size: maxSize,
  } = maximums;
  if (files === undefined) return false;
  if (files.length > 0) {
    const data = files.filter((f) => f.type === 'StashEngine::DataFile');
    const software = files.filter((f) => f.type === 'StashEngine::SoftwareFile');
    const supp = files.filter((f) => f.type === 'StashEngine::SuppFile');
    if (!data.some((f) => !f.download_filename.includes('README'))) {
      return (
        <p className="error-text" id="data_error">Data files submitted to Dryad are required</p>
      );
    }
    if (!publication_date || publication_date > new Date('2025-03-12')) {
      if (data.length > maxFiles) {
        return (
          <p className="error-text" id="data_error">
          A maximum of {maxFiles} data files can be uploaded per dataset.
          To reduce the number, package (.zip, .tar.gz) related files locally, remove the individual files from this dataset, and upload the packages.
          </p>
        );
      }
      if (software.length > maxFiles) {
        return (
          <p className="error-text" id="software_error">
          A maximum of {maxFiles} software files can be uploaded per dataset.
          To reduce the number, package (.zip, .tar.gz) related files locally, remove the individual files from this dataset, and upload the packages.
          </p>
        );
      }
      if (supp.length > maxFiles) {
        return (
          <p className="error-text" id="supp_error">
          A maximum of {maxFiles} supplemental files can be uploaded per dataset.
          To reduce the number, package (.zip, .tar.gz) related files locally, remove the individual files from this dataset, and upload the packages.
          </p>
        );
      }
    } else if (files.length > 1000) {
      return (
        <p className="error-text" id="data_error">
        A maximum of 1000 files can be uploaded per dataset.
        To reduce the number, package (.zip, .tar.gz) related files locally, remove the individual files from this dataset, and upload the packages.
        </p>
      );
    }
    if (!new_upload_size_limit) {
      if (!superuser && data.reduce((sum, f) => sum + f.upload_file_size, 0) > oldSize) {
        return (
          <p className="error-text" id="data_error">
          Total data file uploads are limited to {formatSizeUnits(oldSize)} per submission. Compress or remove files to proceed
          </p>
        );
      }
    } else if (data.reduce((sum, f) => sum + f.upload_file_size, 0) > maxSize) {
      return (
        <p className="error-text" id="data_error">
        Total data file uploads are limited to {formatSizeUnits(maxSize)} per submission. Compress or remove files to proceed
        </p>
      );
    }
    if (software.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p className="error-text" id="software_error">
        Total software file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Compress or remove software files to proceed
        </p>
      );
    }
    if (supp.reduce((sum, f) => sum + f.upload_file_size, 0) > maxZenodo) {
      return (
        <p className="error-text" id="supp_error">
        Total supplemental file uploads are limited to {formatSizeUnits(maxZenodo)} per submission. Compress or remove supplemental files to proceed
        </p>
      );
    }
    const urlErrors = files.filter((f) => !!f.url && f.status_code !== 200);
    if (urlErrors.length > 0) {
      return (
        <p className="error-text" id="data_error">
          Files cannot be retrieved from the URLs for the following URL uploads.
          Please remove them and try again, ensuring the URLs are valid, publically accessible, and point to individual files:<br />
          {urlErrors.map((f) => f.download_filename).join(', ')}
        </p>
      );
    }
    const uploadErrors = data.filter((f) => !f.uploaded && (f.status === 'Uploaded' || f.file_state === 'created'));
    if (uploadErrors.length > 0) {
      return (
        <p className="error-text" id="data_error">
          There was an error with the following upload{uploadErrors.length > 1 && 's'}. Please remove them and try again:<br />
          {uploadErrors.map((f) => f.download_filename).join(', ')}
        </p>
      );
    }
    return false;
  }
  return <p className="error-text" id="data_error">Files are required</p>;
};
