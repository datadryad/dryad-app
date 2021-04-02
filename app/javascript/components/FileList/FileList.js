import React from "react";

import File from "./File/File";

const file_list = (props) => {
    return (
        <div>
            <h2 className="o-heading__level2">Files</h2>
            <table className="c-uploadtable">
                <thead>
                <tr>
                    <th scope="col">Filename</th>
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