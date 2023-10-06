import React from 'react';
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

class File extends React.Component {
  state = {removing: false};

  clickRemove = () => {
    this.setState({removing: true});
    this.props.clickRemove(this.props.file.id);
  };

  getTabularInfo = () => {
    const {removing} = this.state;
    if (removing) return 'Removing...';

    const {file, clickValidationReport} = this.props;
    switch (file.tabularCheckStatus) {
    case TabularCheckStatus.checking:
      return (
        <>
          <i className="fa fa-circle-o-notch fa-spin" aria-hidden="true" />
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
        <div style={{display: 'flex', alignItems: 'center'}}>
          <div className="c-alert--error-icon">
            <button
              className="o-button__plain-text5"
              onClick={clickValidationReport}
              type="button"
              style={{padding: '10px'}}
            >
              View {jsReport?.report?.stats?.errors} alerts
            </button>
          </div>
        </div>
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

  render() {
    const tabularInfo = this.getTabularInfo();
    const {removing} = this.state;
    const {file} = this.props;
    return (
      <tr>
        <th scope="row">{file.sanitized_name}</th>
        <td id={`status_${file.id}`} className="c-uploadtable__status">{file.status}</td>
        <td>
          <span className={statusCss(file.tabularCheckStatus)}>
            {tabularInfo}
          </span>
        </td>
        <td>
          {file.url && (
            <a href={file.url} title={file.url}>
              {ellipsize(file.url)}
            </a>
          )}
        </td>
        <td>{capitalize(file.uploadType)}</td>
        <td className="c-uploadtable-size">{file.sizeKb}</td>
        <td>
          {removing ? (
            <i className="fa fa-circle-o-notch fa-spin" aria-hidden="true" />
          ) : (
            <button onClick={this.clickRemove} type="button" className="c-upload__button">
              Remove
            </button>
          )}
        </td>
      </tr>
    );
  }
}

export default File;
