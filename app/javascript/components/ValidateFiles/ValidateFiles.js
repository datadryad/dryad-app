import React from 'react';

const validate_files = (props) => {
    let checkConfirm;
    if (props.checkConfirmed) {
        checkConfirm =
            <div>
                <input id={props.id} type="checkbox" name="confirm_to_upload" onChange={props.changed} />
                <label className="c-input__required-note" htmlFor={props.id}>I confirm that no
                    Personal Health Information or Sensitive Data are being uploaded with this submission.</label>
            </div>
    }
    return (
        <div>
            {checkConfirm}
            <input type="submit" id="validate_files" //TODO: Define id for each ConfirmSubmit instance
                   className="c-uploadmodal__button-validate o-button__submit"
                   disabled={props.disabled}
                   value={props.buttonLabel}
                   onClick={props.clicked} />
        </div>
    )
}

export default validate_files;