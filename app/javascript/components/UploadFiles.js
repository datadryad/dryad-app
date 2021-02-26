import React from "react"
// import PropTypes from "prop-types"
import UploadType from './UploadType/UploadType'
import FilesList from "./FilesList/FilesList";
import classes from './UploadFiles.module.css';

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
        chosenFiles: null
    };

    uploadFilesHandler = (event, typeId) => {
        const newFiles = [...event.target.files];
        newFiles.map((file) => {
            file.typeId = typeId;
            file.sizeKb = (file.size / 1024).toFixed(1).toString() + ' kb';
        });
        if (!this.state.chosenFiles) {
            this.setState({chosenFiles: newFiles});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(newFiles);
            this.setState({chosenFiles: chosenFiles});
        }
    }

    render () {
        let chosenFiles;
        if (this.state.chosenFiles) {
            chosenFiles = (
                <FilesList files={this.state.chosenFiles} />
            )
        } else {
            chosenFiles = <p>No files chosen yet.</p>
        }

        return (
            <div className={classes.UploadFiles}>
                <h1>Upload Files</h1>
                This is the resource: {this.props.resource_id}
                <p>Data is curated and preserved at Dryad. Software and supplemental information are preserved at Zenodo.</p>
                {this.state.upload_type.map((upload_type, index) => {
                    return <UploadType
                        changed={(event) => this.uploadFilesHandler(event, upload_type.id)}
                        id={upload_type.id}
                        name={upload_type.name}
                        description={upload_type.description}
                        buttonFiles={upload_type.buttonFiles}
                        buttonURLs={upload_type.buttonURLs} />
                })}
                {chosenFiles}
            </div>
        );
    }

}

// UploadFiles.propTypes = {
//   greeting: PropTypes.string
// };
export default UploadFiles
