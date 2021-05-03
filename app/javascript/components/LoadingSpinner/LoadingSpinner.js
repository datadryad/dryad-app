import React from 'react';
import classes from './LoadingSpinner.module.css';

const loading_spinner = () => {
    return (
        // TODO: was copied from the original location of the spinner.gif file to the public folder.
        //   Maybe there is another place to put it and another way to refer to the file.
        <img src="../../../images/spinner.gif" height="60" width="60"  alt="Loading spinner" className={classes.spinner} />
    )
}

export default loading_spinner;