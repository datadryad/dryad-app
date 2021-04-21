import React from 'react';

const file = (props) => {
    return (
        <tr>
            <th scope='row'>{props.file.name}</th>
            <td id={`status_${props.index}`} className='c-uploadtable__status'>{props.file.status}</td>
            <td><a href={props.file.url}>{props.file.url}</a></td>
            <td>{props.file.uploadType}</td>
            <td>{props.file.sizeKb}</td>
            <td><a href="#!" onClick={props.click}>Remove</a></td>
        </tr>
    )
}

export default file;