import React from "react";
import classes from './FilesList.module.css';

const files_list = (props) => {
    return (
        <div>
            <h1>Files</h1>
            <table>
                <thead>
                <tr>
                    <th>Filename</th>
                    <th>Status</th>
                    <th>URL</th>
                    <th>Type</th>
                    <th>Size</th>
                    <th>Actions</th>
                </tr>
                </thead>
                <tbody>
                    {props.files.map((file) => {
                        return (
                            <tr>
                                <td>{file.name}</td>
                                <td>Pending</td>
                                <td/>
                                <td>{file.typeId}</td>
                                <td>{file.sizeKb}</td>
                                <td>Remove</td>
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </div>
    )
}

export default files_list;