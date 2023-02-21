import React from 'react';

import '@cdl-dryad/frictionless-components/lib/styles';
import classes from './ModalValidationReport.module.css';

const ModalValidationReport = React.forwardRef(({file, clickedClose}, ref) => (
  <dialog
    className="c-uploadmodal"
    style={{
      position: 'fixed',
      width: '60%',
      maxWidth: '950px',
      minWidth: '220px',
    }}
    ref={ref}
  >
    <div className="c-uploadmodal__header">
      <h1 className="o-heading__level1">
        Formatting report: {file?.sanitized_name}
      </h1>
      <button
        className={classes.CloseButton}
        aria-label="close"
        type="button"
        onClick={clickedClose}
      />
    </div>
    <p>
      This report has been generated by our tabular data checker. Please review the following alerts and, if desired, correct and re-upload the file:
    </p>
    <ol>
      <li>Review the local copy of your file and make any desired changes.</li>
      <li>
        If you would like to replace the file, close this dialog, and click &quot;Remove&quot; in the
        {' '}<em>Actions</em> column to delete the current file.
      </li>
      <li>
        Re-upload the corrected file using the &quot;Choose files&quot; or &quot;Enter URLs&quot; button above.
      </li>
    </ol>
    <div id="validation_report" />
    <p>
      You can choose to proceed to the final page of the submission form without editing your file.
      At curation stage, if there are questions about how your data is presented, a curator will contact
      you with options to improve the organization, readability, and/or reuse of your dataset.
    </p>
    <button type="button" onClick={clickedClose}>Close</button>
  </dialog>
));

export default ModalValidationReport;
