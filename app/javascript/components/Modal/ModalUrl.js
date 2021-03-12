import React from 'react';
import classes from './ModalUrl.module.css';

const modal_url = (props) => {
    return (
        <div className={classes.modalUrl}>
            <section className={classes.modalUrlMain}>
                {props.children}
                <h1>Enter data file URLs</h1>
                <p>Upload data from a URL on an external server (e.g., Box, Dropbox, lab server). The total size of data files cannot exceed 300 GB.</p>
                <textarea rows="15" cols="100" />
                <button type="button" onClick={props.validateUrls}>
                    Validate files
                </button>
            </section>
        </div>
    );
}

export default modal_url;