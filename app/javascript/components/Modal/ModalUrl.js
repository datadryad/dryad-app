import React from 'react';
import classes from './ModalUrl.module.css';
import ConfirmSubmit from "../ConfirmSubmit/ConfirmSubmit";

const modal_url = (props) => {
    return (
        <div className={classes.ModalUrl}>
            <section className={classes.ModalUrlMain}>
                {props.children}
                <div className={classes.ModalHeader}>
                    <h1 className={classes.ModalUrlTitle}>Enter URLs</h1>
                    <button className={classes.CloseButton} onClick={props.clicked} />
                </div>
                <p>Upload data from a URL on an external server (e.g., Box, Dropbox, lab server). The total size of data files cannot exceed 300 GB.</p>
                <form onSubmit={props.submitted}>
                    <textarea id="location_urls" name="url" rows="15" cols="100" onChange={props.changedUrls} />
                    <br/><br/><br/>
                    <ConfirmSubmit
                        id='confirm_to_validate'
                        buttonLabel='Validate Files'
                        disabled={props.disabled}
                        changed={props.changed} />
                </form>
            </section>
        </div>
    );
}

export default modal_url;