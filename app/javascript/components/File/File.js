import React from "react";

const file = (props) => {
    return (
        <tr>
            <td>{props.file.name}</td>
            <td>{props.file.status}</td>
            <td>{props.file.url}</td>
            <td>{props.file.typeId}</td>
            <td>{props.file.sizeKb}</td>
            <td><a href="#" onClick={props.click}>Remove</a></td>
        </tr>
    )
}

export default file;