import React from 'react';
import classes from './ConfirmSubmit.module.css';
const confirm_submit = (props) => {
    return (
        <div>
            <input
                type="checkbox" id={props.id} className={classes.ConfirmPersonalHealth}
                onChange={props.changed} />
            <label htmlFor={props.id}>
                <span className={classes.MandatoryField}>{'\u00A0\u00A0\u00A0\u00A0'}* </span>
                I confirm that no Personal Health Information or
                Sensitive Data are being uploaded with this submission.
            </label>
            <input
                className={classes.Submit} type="submit" id="validate_files" value={props.buttonLabel}
                disabled={props.disabled} />
        </div>
    )
}

export default confirm_submit;