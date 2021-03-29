import React from "react";
import axios from 'axios';

import UploadType from '../components/UploadType/UploadType';
import ModalUrl from "../components/Modal/ModalUrl";
import FileList from "../components/FileList/FileList";
import FailedUrlList from "../components/FailedUrlList/FailedUrlList";
import ConfirmSubmit from "../components/ConfirmSubmit/ConfirmSubmit";
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
                id: 'supplemental', name: 'Supplemental Information', description: 'e.g., Example1, example2, example3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'
            }
        ],
        chosenFiles: [],
        submitButtonFilesDisabled: true,
        submitButtonUrlsDisabled: true,
        showModal: false,
        urls: null,
        failedUrls: []
    };

    componentDidMount() {
        const files = [];
        files['valid_urls'] = this.props.file_uploads;
        files['invalid_urls'] = [];
        this.updateManifestFiles(files);
    }

    uploadFilesHandler = (event, typeId) => {
        const newFiles = [...event.target.files];
        newFiles.map((file) => {
            // This differentiates computer user chosen files from manifest ones.
            // The manifest file id's are the id's from the objects created.
            file.id = null;
            file.status = 'Pending';
            file.url = null;
            file.typeId = typeId;
            file.sizeKb = this.formatFileSize(file.size);
        });
        this.updateFileList(newFiles);
    }

    updateManifestFiles = (files) => {
        if (files['invalid_urls'].length)
            this.updateFailedUrls(files['invalid_urls']);
        if (!files['valid_urls'].length) return;

        let successfulUrls = files['valid_urls'];
        if (this.state.chosenFiles.length) {
            successfulUrls = this.discardAlreadyChosen(successfulUrls);
        }
        const newManifestFiles = this.transformData(successfulUrls);
        this.updateFileList(newManifestFiles);
    }

    updateFailedUrls = (urls) => {
        this.includeIds(urls);
        this.includeErrorMessages(urls);
        this.setState({failedUrls: urls});
    }

    includeIds = (urls) => {
        urls.map((url, index) => {
            urls[index].id = index;
        })
    }

    includeErrorMessages = (urls) => {
        urls.map((url, index) => {
            urls[index].error_message = this.getErrorMessage(url);
        })
    }

    getErrorMessage = (url) => {
        switch (url.status_code) {
            case 200:
                return '';
            case 400:
                return 'The URL was not entered correctly. Be sure to use http:// or https:// to start all URLS';
            case 401:
                return 'The URL was not authorized for download.';
            case 403: case 404:
                return 'The URL was not found.';
            case 410:
                return 'The requested URL is no longer available.';
            case 411:
                return 'URL cannot be downloaded, please link directly to data file';
            case 414:
                return `The server will not accept the request, because the URL ${url} is too long.`;
            case 408: case 499:
                return 'The server timed out waiting for the request to complete.';
            case 409:
                return "You've already added this URL in this version.";
            case 500: case 501: case 502: case 503: case 504: case 505: case 506:
            case 507: case 508: case 509: case 510: case 511:
                return 'Encountered a remote server error while retrieving the request.';
        }
    }

    formatFileSize = (fileSize) => {
        return (fileSize / 1000).toFixed(2).toString() + ' kB';
    }

    updateFileList = (files) => {
        if (!this.state.chosenFiles.length){
            this.setState({chosenFiles: files});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(files);
            this.setState({chosenFiles: chosenFiles});
        }
    }

    deleteFileHandler = (fileIndex) => {
        let chosenFiles = [...this.state.chosenFiles];
        // id is null for files from file system by construction.
        // If it's there, the line corresponds to a manifest file,
        // and need to call the method to make ajax request and remove
        // in backend.
        if (chosenFiles[fileIndex].id) {
            this.removeManifestFileHandler(chosenFiles[fileIndex].id);
        }
        chosenFiles.splice(fileIndex, 1);
        if (!chosenFiles.length) {
            this.setState({chosenFiles: []});
        } else {
            this.setState({chosenFiles: chosenFiles});
        }
    }

    toggleCheckedFiles = (event) => {
        this.setState({submitButtonFilesDisabled: !event.target.checked});
    }

    toggleCheckedUrls = (event) => {
        this.setState({submitButtonUrlsDisabled: !event.target.checked});
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
        this.toggleCheckedUrls(event);

        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running Capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;

        const urlsObject = {url: this.state.urls};
        axios.post(`/stash/file_upload/validate_urls/${this.props.resource_id}`, urlsObject)
            .then(response => {
                this.updateManifestFiles(response.data);
            })
            .catch(error => console.log(error));
    };

    /**
     * The controller returned data consists of an array of UrlValidator
     * upload_attributes objects. Select only the attributes consistent with
     * this.state.chosenFiles attributes.
     * @param manifestFiles
     * @returns {[]}
     */
    transformData = (manifestFiles) => {
        const transformed = []
        manifestFiles.map(file => {
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
        this.setState({urls: event.target.value});
    }

    buildFailedUrlList = () => {
        if (this.state.failedUrls.length) {
            return (
                <FailedUrlList failedUrls={this.state.failedUrls} clicked={this.removeFailedUrlHandler} />
            )
        } else {
            return null;
        }
    }

    removeManifestFileHandler = (fileId) => {
        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running Capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;

        axios.patch(`/stash/file_uploads/${fileId}/destroy_error`)
            .then(response => {
                console.log(response.status);
            })
            .catch(error => console.log(error));
    }

    removeFailedUrlHandler = (urlId) => {
        const failedUrls = this.state.failedUrls.filter(url => {
            return url.id !== urlId;
        })
        this.setState({failedUrls: failedUrls});
    }

    buildFileList = () => {
        if (this.state.chosenFiles.length) {
            return (
                <div>
                    <FileList chosenFiles={this.state.chosenFiles} clicked={this.deleteFileHandler} />
                    <ConfirmSubmit
                        buttonLabel='Upload pending files'
                        disabled={this.state.submitButtonFilesDisabled}
                        changed={this.toggleCheckedFiles} />
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
                clicked={this.hideModal}
                buttonLabel='Validate Files'
                disabled={this.state.submitButtonUrlsDisabled}
                changed={this.toggleCheckedUrls}
                />
        } else {
            return null;
        }
    }

    render () {
        let failedUrls = this.buildFailedUrlList();
        let chosenFiles = this.buildFileList();
        let modalURL = this.buildModal();

        return (
            <div className={classes.UploadFiles}>
                <h1>Upload Files</h1>
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
                {failedUrls}
                {chosenFiles}
                {modalURL}
            </div>
        );
    }

}

export default UploadFiles;
