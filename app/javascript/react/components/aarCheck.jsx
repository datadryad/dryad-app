import React from 'react';

function aarCheck(previous, step, preview) {
  const [last] = previous?.action_reports?.slice(-1) || [];
  const {report} = last || {};
  if (preview) {
    if (report?.[step]) {
      const previewSec = preview.querySelector(`section[aria-label="${step}"]`);
      if (previewSec.querySelector('ins, del, .ins, .del')) {
        return false;
      }
      return <p className="error-text">{report[step]}</p>;
    }
  }
  return false;
}

export default aarCheck;
