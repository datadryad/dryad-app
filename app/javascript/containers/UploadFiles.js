import React from 'react';
import axios from 'axios';
import Evaporate from 'evaporate';
import AWS from 'aws-sdk';

import UploadType from '../components/UploadType/UploadType';
import ModalUrl from "../components/Modal/ModalUrl";
import FileList from "../components/FileList/FileList";
import FailedUrlList from "../components/FailedUrlList/FailedUrlList";
import ConfirmSubmit from "../components/ConfirmSubmit/ConfirmSubmit";
import classes from './UploadFiles.module.css';

import '../../../stash/stash_engine/app/assets/javascripts/stash_engine/resources.js';


/**
 * Constants
 */
const ActiveRecordTypeToFileType = {
    'StashEngine::SoftwareFile': 'software',
    'StashEngine::DataFile': 'data',
    'StashEngine::Supplemental': 'supplemental'
}

class UploadFiles extends React.Component {
    state = {
        upload_type: [
            {
                type: 'data', logo: '../../../images/logo_dryad.svg', alt: 'Dryad', name: 'Data',
                description: 'Example 1, example 2, example 3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs' },
            {
                type: 'software', logo: '../../../images/logo_zenodo.svg', alt: 'Zenodo', name: 'Software',
                description: 'Example 1, example 2, example 3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs' },
            {
                type: 'supplemental', logo: '../../../images/logo_zenodo.svg', alt: 'Zenodo',
                name: 'Supplemental Information', description: 'Example 1, example 2, example 3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'
            }
        ],
        chosenFiles: [],
        submitButtonFilesDisabled: true,
        submitButtonUrlsDisabled: true,
        showModal: false,
        urls: null,
        // TODO: workaround to deal with manifest file types when making request.
        //  See better way: maybe when clicking in URL button for an Upload Type,
        //  send the type information to the modal somehow. And when submitting carry on
        //  that information and add to request URL.
        currentManifestFileType: null,
        failedUrls: []
    };

    componentDidMount() {
        const files = [];
        files['valid_urls'] = this.props.file_uploads;
        files['invalid_urls'] = [];
        this.updateManifestFiles(files);
    }

    addFilesHandler = (event, type) => {
        const newFiles = [...event.target.files];
        newFiles.map((file) => {
            // This differentiates computer user chosen files from manifest ones.
            // The manifest file id's are the id's from the objects created in db.
            // Other than that this is used to the S3 presign upload process
            file.id = generateQuickId();

            // file.sanitized_name = file_sanitize(file.name);
            file.status = 'Pending';
            file.url = null;
            file.type_ = type;
            file.sizeKb = formatSizeUnits(file.size);
        });
        this.updateFileList(newFiles);
    }

    uploadFilesHandler = () => {
        const config = {
            aws_key: this.props.app_config_s3.table.key,
            bucket: this.props.app_config_s3.table.bucket,
            awsRegion: this.props.app_config_s3.table.region,
            signerUrl: `/stash/data_file/presign_upload/${this.props.resource_id}`,
            awsSignatureVersion: "4",
            computeContentMd5: true,
            cryptoMd5Method: data => { return AWS.util.crypto.md5(data, 'base64'); },
            cryptoHexEncodedHash256: data => { return AWS.util.crypto.sha256(data, 'hex'); }
        }
        Evaporate.create(config).then(this.uploadFileToS3);
    }

    uploadFileToS3 = evaporate => {
        const addConfig = {
            name: '37fb70ac-1/data/' + this.state.chosenFiles[0].name,  //TODO: get the path from method
            file: this.state.chosenFiles[0],
            contentType: this.state.chosenFiles[0].type,
            progress: progressValue => {
                document.getElementById(
                    `progressbar_${this.state.chosenFiles[0].id}`
                ).value = progressValue;
            },
            // cancelled: function () {
            //     allDone.reject();
            // },
            error: function (msg) {
                console.log(msg);
            },
            complete: (_xhr, awsKey) => {
                const csrf_token = document.querySelector('[name=csrf-token]');
                if (csrf_token)  // there isn't csrf token when running Capybara tests
                    axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;
                axios.post(
                    '/stash/data_file/upload_complete/' + this.props.resource_id,
                    {
                        resource_id: this.props.resource_id,
                        name: this.state.chosenFiles[0].name,
                        size: this.state.chosenFiles[0].size,
                        type: this.state.chosenFiles[0].type,
                        original: this.state.chosenFiles[0].name
                    })
                    .then(response => {
                        console.log(response);
                        const chosenFiles = this.state.chosenFiles;
                        chosenFiles[0].status = 'New';
                        this.setState({chosenFiles: chosenFiles});
                    })
                    .catch(error => console.log(error));
            }
        }
        // console.log('Este é o s3_directory: ' + '37fb70ac-1/data/' + this.state.chosenFiles[0].name); //DB

        // Before start uploading change file status cel to a progress bar
        const status_cel = document.getElementById(`status_${this.state.chosenFiles[0].id}`);
        status_cel.innerText = '';
        const node = document.createElement('progress');
        const progressBar = status_cel.appendChild(node);
        progressBar.setAttribute('id', `progressbar_${this.state.chosenFiles[0].id}`)
        progressBar.setAttribute('value', '');

        evaporate.add(addConfig)
            .then(
                awsObjectKey => console.log('File successfully uploaded to: ', awsObjectKey),
                reason => console.log('File did not upload successfully: ', reason)
            );
    }

    updateManifestFiles = (files) => {
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
        if (!urls.length) return;
        this.includeErrorMessages(urls);
        let failedUrls = [...this.state.failedUrls];
        failedUrls = failedUrls.concat(urls);
        this.setState({failedUrls: failedUrls});
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

    updateFileList = (files) => {
        if (!this.state.chosenFiles.length){
            this.setState({chosenFiles: files});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(files);
            this.setState({chosenFiles: chosenFiles});
        }
    }

    removeFileHandler = (fileIndex) => {
        let chosenFiles = [...this.state.chosenFiles];
        if (! (chosenFiles[fileIndex] instanceof File)) {
            this.removeManifestFileHandler(chosenFiles[fileIndex]);
        }
        // TODO: change this! Only remove if removed in backend.
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

    showModal = (uploadType) => {
        this.setState({showModal: true});
        this.setState({currentManifestFileType: uploadType});
    };

    hideModal = (event) => {
        if (event.type === 'submit' || event.type === 'click'
            || (event.type === 'keydown' && event.keyCode === 27)) {
            this.setState({submitButtonUrlsDisabled: true})
            this.setState({showModal: false});
            this.setState({currentManifestFileType: null})
        }
    }

    submitUrlsHandler = (event) => {
        event.preventDefault();
        this.hideModal(event);
        this.toggleCheckedUrls(event);

        if (!this.state.urls) return;

        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running Capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;

        const urlsObject = {url: this.state.urls};
        const typeFilePartialRoute = this.state.currentManifestFileType + '_file';
        axios.post(`/stash/${typeFilePartialRoute}/validate_urls/${this.props.resource_id}`, urlsObject)
            .then(response => {
                this.updateManifestFiles(response.data);
                this.setState({urls: null});
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
                type_: ActiveRecordTypeToFileType[file.type],
                sizeKb: formatSizeUnits(file.upload_file_size)
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

    removeManifestFileHandler = (file) => {
        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running Capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;

        const typeFilePartialRoute = file.type_ + '_files';
        axios.patch(`/stash/${typeFilePartialRoute}/${file.id}/destroy_error`)
            .then(response => {
                console.log(response.status);
            })
            .catch(error => console.log(error));
    }

    removeFailedUrlHandler = (index) => {
        const failedUrls = this.state.failedUrls.filter((url, urlIndex) => {
            return urlIndex !== index;
        })
        this.setState({failedUrls: failedUrls});
    }

    buildFileList = () => {
        if (this.state.chosenFiles.length) {
            return (
                <div>
                    <FileList chosenFiles={this.state.chosenFiles} clickedRemove={this.removeFileHandler} />
                    <ConfirmSubmit
                        id='confirm_to_validate_files'
                        buttonLabel='Upload pending files'
                        disabled={this.state.submitButtonFilesDisabled}
                        changed={this.toggleCheckedFiles}
                        clicked={this.uploadFilesHandler} />
                </div>
            )
        } else {
            return (
                <div>
                    <h2 className="o-heading__level2">Files</h2>
                    <p>No files have been selected.</p>
                </div>
            )
        }
    }

    buildModal = () => {
        if (this.state.showModal) {
            document.addEventListener('keydown', this.hideModal);
            return <ModalUrl
                submitted={this.submitUrlsHandler}
                changedUrls={this.onChangeUrls}
                clickedClose={this.hideModal}
                disabled={this.state.submitButtonUrlsDisabled}
                changed={this.toggleCheckedUrls}
            />
        } else {
            document.removeEventListener('keydown', this.hideModal);
            return null;
        }
    }

    render () {
        let failedUrls = this.buildFailedUrlList();
        let chosenFiles = this.buildFileList();
        let modalURL = this.buildModal();

        return (
            <div className={classes.UploadFiles}>
                {modalURL}
                <h1 className="o-heading__level1">
                    Upload Your Files <span className="t-upload__heading-optional">(optional)</span>
                </h1>
                <p>Data is curated and preserved at Dryad. Software and supplemental information are preserved at Zenodo.</p>
                <div className="c-uploadwidgets">
                    {this.state.upload_type.map((upload_type) => {
                        return <UploadType
                            key={upload_type.type}
                            changed={(event) => this.addFilesHandler(event, upload_type.type)}
                            clicked={() => this.showModal(upload_type.type)}
                            type={upload_type.type}
                            logo={upload_type.logo}
                            name={upload_type.name}
                            description={upload_type.description}
                            buttonFiles={upload_type.buttonFiles}
                            buttonURLs={upload_type.buttonURLs} />
                    })}
                </div>
                {failedUrls}
                {chosenFiles}
            </div>
        );
    }

}

export default UploadFiles;
