import React from 'react';

import ellipsize from '../../../lib/string_patch';

const file = (props) => {
    return (
        <tr>
            <th scope='row'>{props.file.sanitized_name}</th>
            <td id={`status_${props.index}`} className='c-uploadtable__status'>{props.file.status}</td>
            <td><a href={props.file.url} title={props.file.url}>{props.file.url ? ellipsize(props.file.url) : props.file.url}</a></td>
            <td>{props.file.uploadType}</td>
            <td>{props.file.sizeKb}</td>
            <td><a href="#!" onClick={props.click}>Remove</a></td>
        </tr>
    )
}

export default file;