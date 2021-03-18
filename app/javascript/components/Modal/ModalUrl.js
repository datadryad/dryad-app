import React from 'react';
import classes from './ModalUrl.module.css';

const modal_url = (props) => {
    return (
        <div className={classes.ModalUrl}>
            <section className={classes.ModalUrlMain}>
                {props.children}
                <h1 className={classes.ModalUrlTitle}>Enter data file URLs</h1>
                <p>Upload data from a URL on an external server (e.g., Box, Dropbox, lab server). The total size of data files cannot exceed 300 GB.</p>
                <form onSubmit={props.submitted}>
                    <textarea id="location_urls" name="file_urls" rows="15" cols="100" onChange={props.changedUrls} />
                    <br/><br/><br/>
                    <input id="confirm_to_validate"
                        type="checkbox" className={classes.ConfirmPersonalHealth}
                    />
                    <label htmlFor="confirm_not_personal_health_url">
                        <span className={classes.MandatoryField}>{'\u00A0\u00A0\u00A0\u00A0'}* </span>
                        I confirm that no Personal Health Information or
                        Sensitive Data are being uploaded with this submission.
                    </label>
                    <div>
                        <input id="validate_files" className={classes.ValidateUrls} type="submit" value="Validate files" />
                        <button className={classes.CloseButton} onClick={props.clicked}>Close</button>
                    </div>
                </form>
            </section>
        </div>
    );
}

export default modal_url;