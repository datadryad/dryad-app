import React from "react";

const file = (props) => {
    return (
        <tr>
            <td>{props.file.name}</td>
            <td>Pending</td>
            <td/>
            <td>{props.file.typeId}</td>
            <td>{props.file.sizeKb}</td>
            <td><a href="#" onClick={props.click}>Remove</a></td>
        </tr>
    )
}

export default file;