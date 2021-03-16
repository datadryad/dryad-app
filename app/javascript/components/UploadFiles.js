import React from "react";
import axios from 'axios';
// import PropTypes from "prop-types"
import UploadType from './UploadType/UploadType';
import File from "./File/File";
import ModalUrl from "./Modal/ModalUrl";
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
        chosenFiles: null,
        submitButtonDisabled: true,
        showModal: false,
        urls: null
    };

    uploadFilesHandler = (event, typeId) => {
        const newFiles = [...event.target.files];
        newFiles.map((file) => {
            file.id = null;
            file.status = 'Pending';
            file.url = null;
            file.typeId = typeId;
            file.sizeKb = this.formatFileSize(file.size);
        });
        if (!this.state.chosenFiles) {
            this.setState({chosenFiles: newFiles});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(newFiles);
            this.setState({chosenFiles: chosenFiles});
        }
        console.log(this.state.chosenFiles); //DB
    }

    formatFileSize = (fileSize) => {
        return (fileSize / 1024).toFixed(1).toString() + ' kb';
    }

    deleteFileHandler = (fileIndex) => {
        let chosenFiles = [...this.state.chosenFiles];
        chosenFiles.splice(fileIndex, 1);
        if (chosenFiles.length === 0) {
            this.setState({chosenFiles: null});
        } else {
            this.setState({chosenFiles: chosenFiles});
        }
    }

    toggleCheckedConfirm = (event) => {
        this.setState({submitButtonDisabled: !event.target.checked});
    }

    showModal = (upload_type_id) => {
        this.setState({showModal: true});
    };

    hideModal = () => {
        this.setState({showModal: false});
    }

    submitUrlsHandler = (event) => {
        event.preventDefault();
        this.hideModal();

        const urlsObject = {url: this.state.urls}
        const token = document.querySelector('[name=csrf-token]').content

        axios.defaults.headers.common['X-CSRF-TOKEN'] = token

        axios.post('/stash/file_upload/validate_urls/' + this.props.resource_id, urlsObject)
            .then(resp => {
                this.updateManifestFiles(resp.data);
            })
            .catch(error => console.log(error));
    };

    updateManifestFiles = (data) => {
        console.log(data);  //DB
        const newChosenFiles = this.discardAlreadyChosen(data);
        const newFiles = this.transformData(newChosenFiles);
        if (!this.state.chosenFiles){
            this.setState({chosenFiles: newFiles});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(newFiles);
            this.setState({chosenFiles: chosenFiles});
        }
    }

    transformData = (data) => {
        const transformed = []
        data.map(file => {
            transformed.push({
                id: file.id, name: file.original_filename,
                status: 'New', url: file.url,
                typeId: 'D/S/Su', sizeKb: this.formatFileSize(file.upload_file_size)
            })
        })

        return transformed;
    }

    discardAlreadyChosen = (data) => {
        if (this.state.chosenFiles) {
            const chosenFiles = [...this.state.chosenFiles];
            const idsAlready = chosenFiles.map(item => item.id);
            console.log(idsAlready);  //DB
            data = data.filter(file => {
                return !idsAlready.includes(file.id);
            })
            console.log(data);  //DB
        }

        return data;
    }

    onChangeUrls = (event) => {
        this.setState({urls: event.target.value})
    }

    render () {
        let chosenFiles;
        if (this.state.chosenFiles) {
            chosenFiles = (
                <div>
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
                        {this.state.chosenFiles.map((file, index) => {
                            return <File
                                click={() => this.deleteFileHandler(index)}
                                file={file}
                            />
                        })}
                        </tbody>
                    </table>
                    </div>
                    <div>
                        <input
                            type="checkbox" id="confirm_not_personal_health" className={classes.ConfirmPersonalHealth}
                            onChange={(event) => this.toggleCheckedConfirm(event)}
                        />
                        <label htmlFor="confirm_not_personal_health">
                            <span className={classes.MandatoryField}>{'\u00A0\u00A0\u00A0\u00A0'}* </span>
                            I confirm that no Personal Health Information or
                            Sensitive Data are being uploaded with this submission.
                        </label>
                        <input
                            className={classes.UploadFilesSubmit} type="submit" value="Upload pending files"
                            disabled={this.state.submitButtonDisabled}
                        />
                    </div>
                </div>
            )
        } else {
            chosenFiles = (
                <div>
                    <h1 className={classes.FileTitle}>Files</h1>
                    <p>No files have been selected.</p>
                </div>
            )
        }

        let modalURL;
        if (this.state.showModal) {
            modalURL = <ModalUrl
                submitted={this.submitUrlsHandler}
                changedUrls={this.onChangeUrls}
                clicked={this.hideModal} />
        } else {
            modalURL = null;
        }

        return (
            <div className={classes.UploadFiles}>
                <h1>Upload Files</h1>
                {/*<p>Resource: {this.props.resource_id}</p>*/}
                <p>Data is curated and preserved at Dryad. Software and supplemental information are preserved at Zenodo.</p>
                {this.state.upload_type.map((upload_type, index) => {
                    return <UploadType
                        changed={(event) => this.uploadFilesHandler(event, upload_type.id)}
                        clicked={() => this.showModal(upload_type.id)}
                        id={upload_type.id}
                        name={upload_type.name}
                        description={upload_type.description}
                        buttonFiles={upload_type.buttonFiles}
                        buttonURLs={upload_type.buttonURLs} />
                })}
                {chosenFiles}
                {modalURL}
            </div>
        );
    }

}

// UploadFiles.propTypes = {
//   greeting: PropTypes.string
// };
export default UploadFiles
