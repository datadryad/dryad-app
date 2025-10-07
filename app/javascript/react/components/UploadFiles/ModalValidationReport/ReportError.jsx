import React, {useState} from 'react';
import {ExitIcon} from '../../ExitButton';
import ReportTable from './ReportTable';

function getRowPositions(reportError) {
  return Object.keys(reportError.data)
    .map((item) => parseInt(item, 10))
    .sort((a, b) => a - b);
}

function ReportError(props) {
  const {reportError} = props;
  const [visibleRowsCount, setVisibleRowsCount] = useState(10);
  const rowPositions = getRowPositions(reportError);

  return (
    <div className="result">
      {/* Heading */}
      <div style={{display: 'flex', alignItems: 'baseline', gap: '.5ch'}}>
        <h2>
          {reportError.name}
        </h2>
        <span className="count" style={{marginRight: '2ch'}}>x {reportError.count}</span>
        <a
          target="_blank"
          href={`/data_check_guide#${reportError.name.toLowerCase().replace(' ', '-')}`}
          title={`Help with ${reportError.name} alerts`}
          rel="noreferrer"
          style={{fontSize: '1rem'}}
        >
          <i className="fa fa-question-circle" aria-hidden="true" style={{marginRight: '.25ch'}} />
          <em style={{marginRight: '.25ch'}}>What does this mean?</em><ExitIcon />
        </a>
      </div>

      {/* Error details */}
      <div>
        <div className="error-details">
          {reportError.description && (
            <div className="error-description">
              <div>{reportError.description}</div>
            </div>
          )}
          <div className="error-list">
            <p className="error-list-heading">The full list of error messages:</p>
            <ul>
              {reportError.messages.map((message, index) => {
                const key = message + reportError.messages.slice(0, index).filter((m) => m === message).length;
                return <li key={key}>{message}</li>;
              })}
            </ul>
          </div>
        </div>
      </div>

      {/* Table view */}
      {!['source-error'].includes(reportError.type) && (
        <div className="table-view">
          <div className="inner">
            <ReportTable
              reportError={reportError}
              visibleRowsCount={visibleRowsCount}
              rowPositions={rowPositions}
            />
          </div>
        </div>
      )}

      {/* Show more */}
      {visibleRowsCount < rowPositions.length && (
        <button
          type="button"
          className="show-more"
          onClick={() => setVisibleRowsCount(visibleRowsCount + 10)}
        >
          Show more <span className="icon-keyboard_arrow_down" />
        </button>
      )}
    </div>
  );
}

export default ReportError;
