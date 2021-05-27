import React from 'react';

import ellipsize from '../../../lib/string_patch';

import classes from './File.module.css';

const TabularCheckStatus = {
    'checking': 'Checking...',
    'issues_found': 'Issues found',
    'passed': 'Passed',
    'na': 'N/A'
}

const statusCss = (status) => {
    switch (status) {
        case TabularCheckStatus['checking']:
            return classes.Blinking
        case TabularCheckStatus['passed']:
            return classes.Passed
        default:
            return null
    }
}

const file = (props) => {
    return (
        <tr>
            <th scope='row'>{props.file.sanitized_name}</th>
            <td id={`status_${props.index}`} className='c-uploadtable__status'>{props.file.status}</td>
            <td><span className={statusCss(props.file.tabularCheckStatus)}>
                {props.file.tabularCheckStatus === TabularCheckStatus['issues_found']
                    ? <a href="#">{props.file.tabularCheckStatus}</a>
                    : props.file.tabularCheckStatus}
            </span></td>
            <td><a href={props.file.url} title={props.file.url}>
                {props.file.url ? ellipsize(props.file.url) : props.file.url}
            </a></td>
            <td>{props.file.uploadType}</td>
            <td>{props.file.sizeKb}</td>
            { props.removingIndex !== props.index ?
                <td><a href="#!" onClick={props.click}>Remove</a></td> :
                <td style={{padding: 0, width: '74px'}}>
                    <div>
                        <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
                    </div>
                </td> }
        </tr>
    )
}

export default file;