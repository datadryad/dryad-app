import React from 'react';

const validate_files = (props) => {
  let checkConfirm;
  if (props.checkConfirmed) {
    checkConfirm = (
      <div>
        <input id={props.id} type="checkbox" name="confirm_to_upload" onChange={props.changed} checked={!props.disabled} />
        <strong style={{color: 'red'}}> *</strong>
        <label htmlFor={props.id}>
          I confirm that no personal health information or sensitive data are being uploaded with this submission.
        </label>
      </div>
    );
  }
  return (
    <div>
      <p>Data archived in Dryad are publicly available, and any human subjects data or species data must be
        properly anonymized and prepared under applicable legal and ethical guidelines. Please see our
      {' '}<a href="/docs/HumanSubjectsData.pdf">human subjects guidance<span className="pdfIcon" role="img" aria-label=" (PDF)" /></a> and
      {' '}<a href="/docs/EndangeredSpeciesData.pdf">species conservation guidance<span className="pdfIcon" role="img" aria-label=" (PDF)" /></a>.
      </p>
      {checkConfirm}
      <input
        type="submit"
        id="validate_files"
        className="c-uploadmodal__button-validate o-button__submit"
        disabled={props.disabled}
        value={props.buttonLabel}
        onClick={props.clicked}
      />
    </div>
  );
};

export default validate_files;
