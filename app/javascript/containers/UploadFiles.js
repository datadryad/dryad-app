import React from "react";
import axios from 'axios';

import UploadType from '../components/UploadType/UploadType';
import ModalUrl from "../components/Modal/ModalUrl";
import FileList from "../components/FileList/FileList";
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
        this.updateFileList(newFiles);
    }

    updateManifestFiles = (data) => {
        if (this.state.chosenFiles) {
            data = this.discardAlreadyChosen(data);
        }
        const newFiles = this.transformData(data);
        this.updateFileList(newFiles);
    }

    formatFileSize = (fileSize) => {
        return (fileSize / 1000).toFixed(2).toString() + ' kB';
    }

    updateFileList = (files) => {
        if (!this.state.chosenFiles){
            this.setState({chosenFiles: files});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(files);
            this.setState({chosenFiles: chosenFiles});
        }
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

    showModal = () => {
        this.setState({showModal: true});
    };

    hideModal = () => {
        this.setState({showModal: false});
    }

    submitUrlsHandler = (event) => {
        event.preventDefault();
        this.hideModal();

        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;

        const urlsObject = {url: this.state.urls};
        axios.post('/stash/file_upload/validate_urls/' + this.props.resource_id, urlsObject)
            .then(resp => {
                this.updateManifestFiles(resp.data);
            })
            .catch(error => console.log(error));
    };

    /**
     * The controller returned data consists of an array of UrlValidator
     * upload_attributes objects. Select only the attributes consistent with
     * this.state.chosenFiles attributes.
     * @param data
     * @returns {[]}
     */
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

    /**
     * The controller returns data with the successfully inserted manifest
     * files into the table. Check for the files already added to this.state.chosenFiles.
     * @param data
     * @returns {[]}
     */
    discardAlreadyChosen = (data) => {
        const chosenFiles = [...this.state.chosenFiles];
        const idsAlready = chosenFiles.map(item => item.id);
        data = data.filter(file => {
            return !idsAlready.includes(file.id);
        })

        return data;
    }

    onChangeUrls = (event) => {
        this.setState({urls: event.target.value})
    }

    buildFileList = () => {
        if (this.state.chosenFiles) {
            return (
                <div>
                    <FileList chosenFiles={this.state.chosenFiles} clicked={this.deleteFileHandler} />
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
            return (
                <div>
                    <h1 className={classes.FileTitle}>Files</h1>
                    <p>No files have been selected.</p>
                </div>
            )
        }
    }

    buildModal = () => {
        if (this.state.showModal) {
            return <ModalUrl
                submitted={this.submitUrlsHandler}
                changedUrls={this.onChangeUrls}
                clicked={this.hideModal} />
        } else {
            return null;
        }
    }

    render () {
        let chosenFiles = this.buildFileList();
        let modalURL = this.buildModal();

        return (
            <div className={classes.UploadFiles}>
                <h1>Upload Files</h1>
                {/*<p>Resource: {this.props.resource_id}</p>*/}
                <p>Data is curated and preserved at Dryad. Software and supplemental information are preserved at Zenodo.</p>
                {this.state.upload_type.map((upload_type) => {
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

export default UploadFiles;
