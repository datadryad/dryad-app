import React from 'react';

import classes from './Url.module.css';

const url = (props) => {
    return (
        <div className={classes.ManifestItem}>
            <div className={classes.ManifestUrl}>{props.url.url}</div>
            <div className={classes.ManifestError}>{props.url.error_message}</div>
            <div className={classes.ManifestAction}>
                <a className={classes.ManifestAction} href="#" onClick={props.click}>Edit</a>
                <a className={classes.ManifestAction} href="#" onClick={props.click}>Remove</a>
            </div>
        </div>
    )
}

export default url;