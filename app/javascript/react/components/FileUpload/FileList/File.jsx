import React from 'react';
import ellipsize from '../../../../lib/string_patch';
import classes from './File.module.css';

export const TabularCheckStatus = {
  checking: 'Checking...',
  issues: 'View Issues',
  noissues: 'Passed',
  na: 'Too Large For Validation',
  error: "Couldn't Read Tabular Data",
};

const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);

const statusCss = (status) => {
  switch (status) {
  case TabularCheckStatus.checking:
    return classes.Blinking;
  case TabularCheckStatus.noissues:
    return classes.Passed;
  case TabularCheckStatus.error:
    return classes.Passed;
  default:
    return null;
  }
};

function File(props) {
  let tabularInfo;

  if (props.removingIndex !== props.index) {
    switch (props.file.tabularCheckStatus) {
    case TabularCheckStatus.checking:
      tabularInfo = (
        <div>
          <img
            className="c-upload__spinner js-tabular-checking"
            src="../../../images/spinner.gif"
            alt="Validating spinner"
            style={{padding: 0, width: '2rem'}}
          />
        </div>
      );
      break;
    case TabularCheckStatus.issues: {
      let jsReport = '';
      try {
        jsReport = JSON.parse(props.file.frictionless_report.report);
      } catch (e) {
        // console.log(e);
      }
      tabularInfo = (
        <div style={{display: 'flex', alignItems: 'center'}}>
          <div className="c-alert--error-icon">
            <button
              className="o-button__plain-text5"
              onClick={props.clickValidationReport}
              type="button"
              style={{padding: '10px'}}
            >
              View {jsReport?.report?.stats?.errors} Issues
            </button>
          </div>
        </div>
      );
      break;
    }
    case TabularCheckStatus.na:
      if (props.file.sanitized_name?.match(/csv$|xls$|xlsx$|json$/)) {
        tabularInfo = props.file.tabularCheckStatus;
      } else {
        tabularInfo = '';
      }
      break;
    default:
      tabularInfo = props.file.tabularCheckStatus;
    }
  } else {
    tabularInfo = props.file.tabularCheckStatus;
  }

  return (
    <tr>
      <th scope="row">{props.file.sanitized_name}</th>
      <td id={`status_${props.index}`} className="c-uploadtable__status">{props.file.status}</td>
      <td>
        <span className={statusCss(props.file.tabularCheckStatus)}>
          {tabularInfo}
        </span>
      </td>
      <td>
        <a href={props.file.url} title={props.file.url}>
          {props.file.url ? ellipsize(props.file.url) : props.file.url}
        </a>
      </td>
      <td>{capitalize(props.file.uploadType)}</td>
      <td>{props.file.sizeKb}</td>
      { props.removingIndex !== props.index
        ? (
          <td>
            <button onClick={props.clickRemove} type="button" className="c-upload__button">
              Remove
            </button>
          </td>
        )
        : (
          <td style={{padding: 0, width: '74px'}}>
            <div>
              <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
            </div>
          </td>
        ) }
    </tr>
  );
}

export default File;
