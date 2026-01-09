import React, {useState} from 'react';
import moment from 'moment';
import ellipsize from '../../../../lib/string_patch';

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
    return 'font-weight: bold;';
  case TabularCheckStatus.checking:
    return 'font-weight: bold;';
  case TabularCheckStatus.noissues:
    return '';
  case TabularCheckStatus.error:
    return '';
  default:
    return '';
  }
};

function S3Check({file}) {
  if (file.file_state === 'copied' || file.uploaded) {
    return (
      <div className="c-uploadtable-time">
        {moment(file.upload_updated_at || file.updated_at).format('YYYY/MM/DD H:mm')}{' '}
        <i className="fas fa-check" role="img" aria-label="complete" title="Upload complete" />
      </div>
    );
  }
  return (
    <div className="error-text c-uploadtable-time">Upload error! Remove and retry</div>
  );
}

export default function File({
  file, renameFile, clickRemove, clickValidationReport,
}) {
  const filename = file.sanitized_name.replace(/\.[^/.]+$/, '');
  const ext = file.sanitized_name.match(/\.[0-9a-z]+$/i)?.[0] || '';
  const [removing, setRemoving] = useState(false);
  const [newName, setNewName] = useState(filename);
  const [rename, setRename] = useState(false);

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
            style={{color: '#e9ab00', marginRight: '.5ch'}}
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
      <th scope="row">
        {rename ? (
          <form className="input-line" style={{alignItems: 'center', flexWrap: 'nowrap'}}>
            <div className="input-line" style={{alignItems: 'center', gap: 0, flexWrap: 'nowrap'}}>
              <textarea
                className="c-input__text"
                aria-label={`Rename file ${file.sanitized_name}`}
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
              />
              <span style={{whiteSpace: 'nowrap'}}>{ext}</span>
            </div>
            <button
              type="button"
              className="o-button__plain-textlink"
              onClick={() => renameFile(file.id, `${newName}${ext}`.trim())}
              aria-label={`Save new name for ${file.sanitized_name}`}
              title="Save"
            ><i className="fas fa-save" aria-hidden="true" />
            </button>
            <button
              type="button"
              className="o-button__plain-textlink"
              onClick={() => {
                setRename(false);
                setNewName(filename);
              }}
              aria-label={`Cancel name change for ${file.sanitized_name}`}
              title="Cancel"
            ><i className="fas fa-times" aria-hidden="true" />
            </button>
          </form>
        ) : (
          <span className="input-line">
            {file.sanitized_name}
            {file.uploaded && (
              <button
                type="button"
                className="o-button__plain-textlink"
                onClick={() => setRename(true)}
                aria-label={`Rename file ${file.sanitized_name}`}
                title="Rename file"
              ><i className="fas fa-pencil" aria-hidden="true" />
              </button>
            )}
          </span>
        ) }
      </th>
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
