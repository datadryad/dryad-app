import React from 'react';

function ReportTable(props) {
  const {reportError, visibleRowsCount, rowPositions} = props;
  const isHeaderVisible = reportError.tags.includes('#row');
  let afterFailRowPosition = 1;
  if (rowPositions[rowPositions.length - 1]) {
    afterFailRowPosition = rowPositions[rowPositions.length - 1] + 1;
  } else {
    afterFailRowPosition = 2;
  }
  return (
    <table className="table table-sm" style={{display: 'table'}}>
      <tbody>
        {reportError.header && isHeaderVisible && (
          <tr className="before-fail">
            <td className="text-center">1</td>
            {reportError.header.map((label, index) => {
              const key = label + reportError.header.slice(0, index).filter((l) => l === label).length;
              return <td key={key}>{label}</td>;
            })}
          </tr>
        )}
        {rowPositions.map(
          (rowPosition, index) => {
            const key = rowPosition + rowPositions.slice(0, index).filter((p) => p === rowPosition).length;
            return (index < visibleRowsCount && (
              <tr key={key}>
                <td className="result-row-index">{rowPosition || 1}</td>
                {reportError.data[rowPosition].values.map((value, innerIndex) => {
                  const innerKey = value + reportError.data[rowPosition].values.slice(0, innerIndex).filter((v) => v === value).length;
                  return (
                    <td
                      key={innerKey}
                      className={reportError.data[rowPosition].errors.has(innerIndex + 1) ? 'fail' : ''}
                    >
                      {value}
                    </td>
                  );
                })}
              </tr>
            ));
          },
        )}
        <tr className="after-fail">
          <td className="result-row-index">{afterFailRowPosition}</td>
          {reportError.header && reportError.header.map((_, index) => <td key={index} /> /* eslint-disable-line */ )}
        </tr>
      </tbody>
    </table>
  );
}

export default ReportTable;
