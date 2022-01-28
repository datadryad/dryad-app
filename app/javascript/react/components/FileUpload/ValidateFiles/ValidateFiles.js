/* eslint-disable jsx-a11y/label-has-associated-control */
// once again, eslint doesn't detect properly

import React from 'react';

const validate_files = (props) => {
  let checkConfirm;
  if (props.checkConfirmed) {
    checkConfirm = (
      <div>
        <input id={props.id} type="checkbox" name="confirm_to_upload" onChange={props.changed} checked={!props.disabled} />
        <strong style={{color: 'red'}}> *</strong>
        <label htmlFor={props.id}>
          I confirm that no Personal Health Information or Sensitive Data are being uploaded with this submission.
        </label>
      </div>
    );
  }
  return (
    <div>
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
