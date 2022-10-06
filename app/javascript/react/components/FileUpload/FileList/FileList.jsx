import React from 'react';

import File from './File';
import BadList from './BadList';

const file_list = ({
  chosenFiles, clickedRemove, clickedValidationReport, removingIndex,
}) => (
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
        {chosenFiles.map((file, index) => (
          <File
            key={JSON.stringify(file)}
            clickRemove={() => clickedRemove(index)}
            clickValidationReport={() => clickedValidationReport(index)}
            file={file}
            index={index}
            removingIndex={removingIndex}
          />
        ))}
      </tbody>
    </table>
  </div>
);

export default file_list;
