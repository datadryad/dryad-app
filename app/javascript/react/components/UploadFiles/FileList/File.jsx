import React, {useState} from 'react';
import moment from 'moment';
import ellipsize from '../../../../lib/string_patch';
import classes from './File.module.css';

export const TabularCheckStatus = {
  checking: 'Checking...',
  issues: 'View alerts',
  noissues: 'Passed',
  na: 'Too large for validation',
  error: "Couldn't read tabular data",
};

const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);

const statusCss = (status) => {
  switch (status) {
  case 'Pending':
    return classes.Blinking;
  case TabularCheckStatus.checking:
    return classes.Blinking;
  case TabularCheckStatus.noissues:
    return classes.Passed;
  case TabularCheckStatus.error:
    return classes.Passed;
  default:
    return '';
  }
};

function S3Check({file}) {
  if (file.file_state === 'copied' || file.uploaded) {
    return (
      <div className="c-uploadtable-time">
        {moment(file.upload_updated_at || file.updated_at).format('YYYY/MM/DD H:mm')} <i className="fas fa-check" role="img" aria-label="complete" />
      </div>
    );
  }
  return (
    <div className="error-text c-uploadtable-time">Upload error! Remove and retry</div>
  );
}

export default function File({file, clickRemove, clickValidationReport}) {
  const [removing, setRemoving] = useState(false);

  const removeClick = () => {
    setRemoving(true);
    clickRemove(file.id);
  };

  const getTabularInfo = () => {
    if (removing) return null;
    switch (file.tabularCheckStatus) {
    case TabularCheckStatus.checking:
      return (
        <>
          <i className="fas fa-circle-notch fa-spin" aria-hidden="true" />
          <span className="screen-reader-only">Validating...</span>
        </>
      );
    case TabularCheckStatus.issues: {
      let jsReport = '';
      try {
        jsReport = JSON.parse(file.frictionless_report.report);
      } catch (e) {
        // console.log(e);
      }
      return (
        <button
          className="o-button__plain-textlink"
          onClick={clickValidationReport}
          aria-haspopup="dialog"
          type="button"
        >
          <i
            className="fa-solid fa-triangle-exclamation"
            style={{color: '#fff2ce', marginRight: '.5ch'}}
            role="img"
            aria-label="Has alerts"
          />
          View {jsReport?.report?.stats?.errors} alerts
        </button>
      );
    }
    case TabularCheckStatus.na:
      if (file.sanitized_name?.match(/csv$|xls$|xlsx$|json$/)) {
        return file.tabularCheckStatus;
      }
      return '';
    default:
      return file.tabularCheckStatus;
    }
  };

  const tabularInfo = getTabularInfo();
  return (
    <tr>
      <th scope="row">{file.sanitized_name}</th>
      <td id={`status_${file.id}`} className={`c-uploadtable__status ${statusCss(file.status)}`}>
        {file.status === 'Uploaded' ? (
          <S3Check file={file} />
        ) : file.status}
      </td>
      <td className={statusCss(file.tabularCheckStatus)}>
        {tabularInfo}
      </td>
      <td>
        {file.url && (
          <a href={file.url} title={file.url}>
            {ellipsize(file.url)}
          </a>
        )}
        {!file.url && file.uploaded && (
          <a
            href={`/downloads/pre_submit/${file.id}`}
            title={`Download from ${file.uploadType === 'data' ? 'Dryad' : 'Zenodo'}`}
            target="_blank"
            rel="noreferrer"
          >
            {file.sanitized_name}
          </a>
        )}
      </td>
      <td>{capitalize(file.uploadType)}</td>
      <td className="c-uploadtable-size">{file.sizeKb}</td>
      <td>
        {removing ? (
          <i className="fas fa-circle-notch fa-spin" aria-hidden="true" />
        ) : (
          <button onClick={removeClick} type="button" className="o-button__plain-textlink" aria-label="Remove file">
            <i className="fas fa-trash-can" aria-hidden="true" style={{marginRight: '.5ch'}} />
          </button>
        )}
      </td>
    </tr>
  );
}
