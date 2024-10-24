import React from 'react';

import File from './File';
import BadList from './BadList';

const file_list = ({
  chosenFiles, clickedRemove, clickedValidationReport, totalSize,
}) => (
  <>
    <BadList chosenFiles={chosenFiles} />
    <div className="c-uploadtable-header">
      <h3 className="o-heading__level3" id="filelist_id">Selected files</h3>
      <p>Total size: {totalSize}</p>
    </div>
    <div className="table-wrapper c-uploadtable-wrapper" role="region" aria-labelledby="filelist_id">
      <table className="c-uploadtable">
        <thead>
          <tr>
            <th scope="col">Filename</th>
            <th scope="col">Status</th>
            <th scope="col">Tabular data check</th>
            <th scope="col">URL</th>
            <th scope="col">Type</th>
            <th scope="col">Size</th>
            <th scope="col">Actions</th>
          </tr>
        </thead>
        <tbody>
          {chosenFiles.map((file) => (
            <File
              key={file.id}
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
