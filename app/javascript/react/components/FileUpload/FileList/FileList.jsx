/* eslint-disable react/no-array-index-key */
// TODO: We should revisit and try to replace the array index with the actual unique database id.  However I tried and it
// breaks everything right now.
import React from 'react';

import File from './File/File';
import BadList from './BadList/BadList';

const file_list = (props) => (
  <div>
    <h2 className="o-heading__level2" id="filelist_id">Files</h2>
    <BadList chosenFiles={props.chosenFiles} />
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
        {props.chosenFiles.map((file, index) => (
          <File
            key={index}
            clickRemove={() => props.clickedRemove(index)}
            clickValidationReport={() => props.clickedValidationReport(index)}
            file={file}
            index={index}
            removingIndex={props.removingIndex}
          />
        ))}
      </tbody>
    </table>
  </div>
);

export default file_list;
