import React from 'react';
import classes from './UploadType.module.css';

const upload_type = (props) => {
    return (
        <div className={classes.UploadType}>
            <h1 className={classes.UploadTypeTitle}>{props.name}</h1>
            <p className={classes.UploadTypeDescription}>{props.description}</p>
            <button>{props.buttonFiles}</button>
            <button>{props.buttonURLs}</button>
        </div>
    );
};

export default upload_type;