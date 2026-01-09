/* eslint-disable no-restricted-syntax */
import React from 'react';
import ReportError from './ReportError';

function getReportErrors(task) {
  const reportErrors = {};
  for (const error of task.errors) {
    const header = task.resource ? task.resource.schema.fields.map((field) => field.name) : task.labels;

    // Prepare reportError
    let reportError = reportErrors[error.type || error.code];
    if (!reportError) {
      reportError = {
        count: 0,
        type: error.type || error.code,
        name: error.title || error.name,
        tags: error.tags,
        description: error.description,
        header,
        messages: [],
        data: {},
      };
    }

    // Prepare cells
    let data = reportError.data[error.rowNumber || error.rowPosition || 0];
    if (!data) {
      const values = error.cells || error.labels || [];
      data = {values, errors: new Set()};
    }

    // Ensure blank row
    if (error.type === 'blank-row' || error.code === 'blank-row') {
      data.values = header.map(() => '');
    }

    // Ensure missing cell
    if (error.type === 'missing-cell') {
      data.values[error.fieldNumber - 1] = '';
    } else if (error.code === 'missing-cell') {
      data.values[error.fieldPosition - 1] = '';
    }

    // Add row errors
    if (error.fieldNumber) {
      data.errors.add(error.fieldNumber);
    } else if (error.fieldPosition) {
      data.errors.add(error.fieldPosition);
    } else if (data.values) {
      data.errors = new Set(data.values.map((_, index) => index + 1));
    }

    // Save reportError
    reportError.count += 1;
    reportError.messages.push(error.message);
    reportError.data[error.rowNumber || error.rowPosition || 0] = data;
    reportErrors[error.type || error.code] = reportError;
  }

  return reportErrors;
}

function FrictionlessReport({tdc_report}) {
  const {report} = tdc_report;
  if (report) {
    if (typeof report === 'string') return <div className="c-alert--error-lite">{report}</div>;
    if (report.tasks) {
      const reportErrors = getReportErrors(report.tasks[0]);
      return (
        <div className="frictionless-components-report">
          {report.stats.errors === 10 && (
            <p>The report shows the maximum of 10 alerts. More alerts may appear if these 10 are corrected and the file is re-uploaded.</p>
          )}
          {Object.values(reportErrors).map((reportError) => (
            <ReportError key={reportError.type} reportError={reportError} />
          ))}
        </div>
      );
    }
  }
  return null;
}

export default FrictionlessReport;
