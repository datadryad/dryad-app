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
                    <th scope="col">Status</th>
                    <th scope="col">Tabular Data Check</th>
                    <th scope="col">URL</th>
                    <th scope="col">Type</th>
                    <th scope="col">Size</th>
                    <th scope="col">Actions</th>
                </tr>
                </thead>
                <tbody>
                {props.chosenFiles.map((file, index) => {
                    return <File
                        key={index}
                        clickRemove={() => props.clickedRemove(index)}
                        clickValidationReport={() => props.clickedValidationReport(index)}
                        file={file}
                        index={index}
                        removingIndex={props.removingIndex}
                    />
                })}
                </tbody>
            </table>
        </div>
    )
}

export default file_list;