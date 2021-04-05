import React from 'react';
import classes from './ConfirmSubmit.module.css';
const confirm_submit = (props) => {
    return (
        <div>
            <input id={props.id} type="checkbox" name="" onChange={props.changed} />
            <label className="c-input__required-note" htmlFor={props.id}>I confirm that no
                Personal Health Information or Sensitive Data are being uploaded with this submission.</label>
            <input type="submit" id="validate_files"
                   className="c-uploadmodal__button-validate o-button__submit"
                   disabled={props.disabled}
                   value={props.buttonLabel} />
        </div>
    )
}

export default confirm_submit;