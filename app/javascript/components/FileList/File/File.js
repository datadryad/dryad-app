import React from 'react';

const file = (props) => {
    return (
        <tr>
            <th scope='row'>{props.file.name}</th>
            <td className='c-uploadtable__status'>{props.file.status}</td>
            <td><a href={props.file.url}>{props.file.url}</a></td>
            <td>{props.file.typeId}</td>
            <td>{props.file.sizeKb}</td>
            <td><a href="#!" onClick={props.click}>Remove</a></td>
        </tr>
    )
}

export default file;