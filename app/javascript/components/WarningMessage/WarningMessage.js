import React from 'react';

import classes from './WarningMessage.module.css';

const warning_message = (props) => {
    return (
        <div className={classes.WarningText}>
            <p>{props.message}</p>
        </div>
    )
}

export default warning_message;