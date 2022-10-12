import React from 'react';

import File from './File';
import BadList from './BadList';

const file_list = ({chosenFiles, clickedRemove, clickedValidationReport}) => (
  <div>
    <h2 className="o-heading__level2" id="filelist_id">Files</h2>
    <BadList chosenFiles={chosenFiles} />
    <table className="c-uploadtable">
      <thead>
        <tr>
          <th scope="col">Filename</th>
          <th scope="col">Status</th>
          <th scope="col">Tabular Data Check</th>
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
);

export default file_list;
