import React from "react";

import File from "./File/File";
import classes from "./FileList.module.css";

const file_list = (props) => {
    return (
        <div>
            <h1 className={classes.FileTitle}>Files</h1>
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
                {props.chosenFiles.map((file, index) => {
                    return <File
                        key={index}
                        click={() => props.clicked(index)}
                        file={file}
                    />
                })}
                </tbody>
            </table>
        </div>
    )
}

export default file_list;