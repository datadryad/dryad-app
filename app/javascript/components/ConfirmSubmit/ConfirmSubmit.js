import React from 'react';
import classes from './ConfirmSubmit.module.css';
const confirm_submit = (props) => {
    return (
        <div>
            <input
                type="checkbox" className={classes.ConfirmPersonalHealth}
                onChange={props.changed} />
            <label htmlFor="confirm_not_personal_health">
                <span className={classes.MandatoryField}>{'\u00A0\u00A0\u00A0\u00A0'}* </span>
                I confirm that no Personal Health Information or
                Sensitive Data are being uploaded with this submission.
            </label>
            <input
                className={classes.Submit} type="submit" value={props.buttonLabel}
                disabled={props.disabled} />
        </div>
    )
}

export default confirm_submit;