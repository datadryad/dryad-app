import React from 'react';

export default function ActionRequired({previous}) {
  const [last] = previous?.action_reports?.slice(-1) || [];
  const {report} = last || {};
  if (report) {
    return (
      <div className="callout warn">
        <p role="heading" aria-level="2"><i className="fa fa-triangle-exclamation" /> Action required</p>
        <p style={{whiteSpace: 'pre', fontSize: '.98rem'}}>{report}</p>
      </div>
    );
  }
  return false;
}
