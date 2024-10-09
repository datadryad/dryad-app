import React from 'react';
import {
  maxFiles, maxSize, maxZenodo, formatSizeUnits,
} from './maximums';

export {default} from './UploadFiles';

export const filesCheck = (files) => {
  if (files.length > 0) {
    const present = files.filter((f) => f.file_state !== 'deleted');
    const data = present.filter((f) => f.type === 'StashEngine::DataFile');
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
