/* eslint-disable no-restricted-syntax */
import React from 'react';
import ReportError from './ReportError';

import './frictionless-components.css';

function getReportErrors(task) {
  const reportErrors = {};
  for (const error of task.errors) {
    const header = task.resource.schema.fields.map((field) => field.name);

    // Prepare reportError
    let reportError = reportErrors[error.code];
    if (!reportError) {
      reportError = {
        count: 0,
        code: error.code,
        name: error.name,
        tags: error.tags,
        description: error.description,
        header,
        messages: [],
        data: {},
      };
    }

    // Prepare cells
    let data = reportError.data[error.rowPosition || 0];
    if (!data) {
      const values = error.cells || error.labels || [];
      data = {values, errors: new Set()};
    }

    // Ensure blank row
    if (error.code === 'blank-row') {
      data.values = header.map(() => '');
    }

    // Ensure missing cell
    if (error.code === 'missing-cell') {
      data.values[error.fieldPosition - 1] = '';
    }

    // Add row errors
    if (error.fieldPosition) {
      data.errors.add(error.fieldPosition);
    } else if (data.values) {
      data.errors = new Set(data.values.map((_, index) => index + 1));
    }

    // Save reportError
    reportError.count += 1;
    reportError.messages.push(error.message);
    reportError.data[error.rowPosition || 0] = data;
    reportErrors[error.code] = reportError;
  }

  return reportErrors;
}

function HandleReport(jsReport) {
  const {report} = jsReport;
  if (report) {
    if (typeof report === 'string') return <div className="error">{report}</div>;
    if (report.tasks) {
      const reportErrors = getReportErrors(report.tasks[0]);
      return (
        <div className="frictionless-components-report">
          {report.stats.errors === 10 && (
            <p>The report shows the maximum of 10 alerts. More alerts may appear if these 10 are corrected and the file is re-uploaded.</p>
          )}
          {Object.values(reportErrors).map((reportError) => (
            <ReportError key={reportError.code} reportError={reportError} />
          ))}
        </div>
      );
    }
  }
  return null;
}

const ModalValidationReport = React.forwardRef(({file, clickedClose}, ref) => {
  const jsReport = file?.frictionless_report?.report ? JSON.parse(file.frictionless_report.report) : {};
  return (
    <dialog
      className="modalDialog extra-wide"
      ref={ref}
    >
      <div className="c-uploadmodal__header">
        <h1 className="c-datasets-heading__heading o-heading__level1">
          Formatting report: {file?.sanitized_name}
        </h1>
        <button
          className="button-close-modal"
          aria-label="close"
          type="button"
          onClick={clickedClose}
        />
      </div>
      <p>
        This report has been generated by our tabular data checker.
        Please{' '}
        <a href="/stash/data_check_guide" target="_blank">review the alerts<span className="screen-reader-only"> (opens in new window)</span></a>
        {' '}and, if desired, correct and re-upload the file:
      </p>
      <ol>
        <li>Review the local copy of your file and make any desired changes.</li>
        <li>
          To replace the file, close this dialog, and click &quot;Remove&quot; in the
          {' '}<em>Actions</em> column to delete the current upload.
        </li>
        <li>
          Re-upload the corrected file using the &quot;Choose files&quot; or &quot;Enter URLs&quot; button.
        </li>
      </ol>
      {file && <HandleReport {...jsReport} />}
      <p>
        You can choose to proceed to the final page of the submission form without editing your file.
        A curator may contact you with options to improve the organization, readability, and/or accessibility of your dataset.
      </p>
      <p style={{textAlign: 'right'}}>
        <button type="button" className="o-button__plain-text2" onClick={clickedClose}>Close</button>
      </p>
    </dialog>
  );
});

export default ModalValidationReport;
