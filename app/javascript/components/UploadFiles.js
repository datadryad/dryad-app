import React from "react"
// import PropTypes from "prop-types"
import UploadType from './UploadType/UploadType'
import classes from './UploadFiles.module.css';
import upload_type from "./UploadType/UploadType";

class UploadFiles extends React.Component {
    state = {
        upload_type: [
            {
                id: 'data', name: 'Data', description: 'eg., Spreadsheets, example1, example2',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'},
            {
                id: 'software', name: 'Software', description: 'e.g., Example1, example2, example3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'},
            {
                id: 'suplemental', name: 'Suplemental Information', description: 'e.g., Example1, example2, example3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'
            }
        ],
        areFiles: false
    };

    uploadFilesHandler = (event, typeId) => {
        console.log(event.target.files);
        this.setState({areFiles: true});
    }

    toggleTableHandler() {
        console.log('Table displayed!')
    }

    render () {
        let chosenFiles = null;
        if (this.state.areFiles) {
            chosenFiles = (
                <div>
                    <h1>Files</h1>
                    <table>
                        <th>
                            <td>Filename</td>
                            <td>Status</td>
                            <td>URL</td>
                            <td>Type</td>
                            <td>Actions</td>
                        </th>
                        <tr>
                            Here goes the table content
                        </tr>
                    </table>
                </div>
            )
        } else {
            chosenFiles = <p>Any files chosen yet.</p>
        }

        return (
            <div className={classes.UploadFiles}>
                <h1>Upload Files</h1>
                This is the resource: {this.props.resource_id}
                <p>Data is curated and preserved at Dryad. Software and supplemental information are preserved at Zenodo.</p>
                {this.state.upload_type.map((upload_type, index) => {
                    return <UploadType
                        // click={() => this.uploadFilesHandler(upload_type.id)}
                        changed={(event) => this.uploadFilesHandler(event, upload_type.id)}
                        id={upload_type.id}
                        name={upload_type.name}
                        description={upload_type.description}
                        buttonFiles={upload_type.buttonFiles}
                        buttonURLs={upload_type.buttonURLs} />
                })}
                <h1>Files to upload</h1>
                {chosenFiles}
            </div>
        );
    }

}

// UploadFiles.propTypes = {
//   greeting: PropTypes.string
// };
export default UploadFiles
