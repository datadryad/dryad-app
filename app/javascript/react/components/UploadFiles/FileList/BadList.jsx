import React from 'react';
import {ExitIcon} from '../../ExitButton';

// checks files to see if they have validation and also status
const filterForStatus = (status, files) => {
  const fns = files.map((file) => {
    if (!Object.prototype.hasOwnProperty.call(file, 'frictionless_report')) return null;

    if (file.frictionless_report?.status === status) return file.download_filename;

    return null;
  });

  // only return non-null
  return fns.filter((n) => n);
};

const makeAndString = (arr) => {
  if (arr.length === 0) return '';
  if (arr.length === 1) return arr[0];
  const firsts = arr.slice(0, arr.length - 1);
  const last = arr[arr.length - 1];
  return `${firsts.join(', ')} and ${last}`;
};

export default function BadList(props) {
  const errorFiles = filterForStatus('error', props.chosenFiles);
  const issueFiles = filterForStatus('issues', props.chosenFiles);
  if (errorFiles.length + issueFiles.length < 1) return (null);

  let errorMsg = '';
  let issueMsg = '';

  if (errorFiles.length > 0) {
    errorMsg = (
      <div className="callout warn" role="alert">
        <p>
          Our tabular data checker couldn&apos;t read tabular data from {makeAndString(errorFiles)}.
          If you expect them to have consistent tabular data, check that they are readable and formatted correctly.
        </p>
      </div>
    );
  }

  if (issueFiles.length > 0) {
    issueMsg = (
      <div className="callout warn" role="alert" style={{paddingBottom: '.75rem', marginBottom: '1em'}}>
        <p style={{marginBottom: '.5rem'}}>
          Inconsistencies found in the format and structure of {issueFiles.length} of your tabular data files
        </p>
        <div style={{backgroundColor: 'white', padding: '.75rem', fontSize: '.98rem'}}>
          <p style={{marginTop: 0}}>
            These inconsistencies can affect the usability of your data.{' '}
            <a href="/data_check_guide" target="_blank">
              Check our guide for more information<ExitIcon />
            </a>
            .
          </p>
          <p>A detailed report is available for each file. To address the identified alerts:</p>
          <ol style={{marginBottom: 0}}>
            <li>
              Click the link in the <em>Tabular data check</em> column to see what has been highlighted for your review.
            </li>
            <li>Review the local copy of your file and make any desired changes.</li>
            <li>
              If you would like to replace the file, click the button in the <em>Remove</em> column to delete the current upload.
            </li>
            <li>
              Re-upload the corrected file using the &quot;Choose files&quot; or &quot;Enter URLs&quot; button above.
            </li>
          </ol>
        </div>
      </div>
    );
  }

  return (
    <>
      {errorMsg}
      {issueMsg}
    </>
  );
}
