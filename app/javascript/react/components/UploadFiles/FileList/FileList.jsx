import React from 'react';
import {formatSizeUnits} from '../../../../lib/utils';
import File from './File';
import BadList from './BadList';

const file_list = ({
  config, chosenFiles, renameFile, clickedRemove, clickedValidationReport, totalSize,
}) => (
  <>
    <BadList chosenFiles={chosenFiles} />
    <div className="c-uploadtable-header">
      <h3 className="o-heading__level3" id="filelist_id">Selected files</h3>
      <p>Total size:{' '}
        <span
          className={totalSize > config.large_file_size ? 'overage' : ''}
          title={totalSize > config.large_file_size
            ? `Total file size is greater than ${formatSizeUnits(config.large_file_size)}. Overages will be charged.` : null}
        >
          {formatSizeUnits(totalSize)}
        </span>
      </p>
    </div>
    <div className="table-wrapper c-uploadtable-wrapper" role="region" aria-labelledby="filelist_id">
      <table className="c-uploadtable">
        <thead>
          <tr>
            <th scope="col" id="filename_label">Filename</th>
            <th scope="col">Status</th>
            <th scope="col">Tabular data check</th>
            <th scope="col">Download</th>
            <th scope="col">Type</th>
            <th scope="col">Size</th>
            <th scope="col">Remove</th>
          </tr>
        </thead>
        <tbody>
          {chosenFiles.map((file) => (
            <File
              key={file.id + file.sanitized_name}
              renameFile={renameFile}
              clickRemove={clickedRemove}
              clickValidationReport={() => clickedValidationReport(file)}
              file={file}
            />
          ))}
        </tbody>
      </table>
    </div>
  </>
);

export default file_list;
