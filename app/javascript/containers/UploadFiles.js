import React from 'react';
import axios from 'axios';
import Evaporate from 'evaporate';
import AWS from 'aws-sdk';
import sanitize from '../lib/sanitize_filename';

import UploadType from '../components/UploadType/UploadType';
import ModalUrl from "../components/Modal/ModalUrl";
import FileList from "../components/FileList/FileList";
import FailedUrlList from "../components/FailedUrlList/FailedUrlList";
import ConfirmSubmit from "../components/ConfirmSubmit/ConfirmSubmit";
import LoadingSpinner from "../components/LoadingSpinner/LoadingSpinner";
import classes from './UploadFiles.module.css';

// TODO: check if this is the best way to refer to stash_engine files.
import '../../../stash/stash_engine/app/assets/javascripts/stash_engine/resources.js';


/**
 * Constants
 */
const RailsActiveRecordToUploadType = {
    'StashEngine::DataFile': 'data',
    'StashEngine::SoftwareFile': 'software',
    'StashEngine::SuppFile': 'supp'
}
const AllowedUploadFileTypes = {
    'data': 'data',
    'software': 'sfw',
    'supp': 'supp'
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
                type: 'supp', logo: '../../../images/logo_zenodo.svg', alt: 'Zenodo',
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
        failedUrls: [],
        loading: false
    };

    componentDidMount() {
        const files = this.props.file_uploads;
        const transformed = this.transformData(files);
        this.setState({chosenFiles: transformed});
    }

    addFilesHandler = (event, uploadType) => {
        const newFiles = this.discardAlreadyChosenByName([...event.target.files], uploadType);
        newFiles.map(file => {
            file.sanitized_name = sanitize(file.name);
            file.status = 'Pending';
            file.url = null;
            file.uploadType = uploadType;
            file.manifest = false;
            file.sizeKb = formatSizeUnits(file.size);
        });
        this.updateFileList(newFiles);
    }

    uploadFilesHandler = () => {
        const config = {
            aws_key: this.props.app_config_s3.table.key,
            bucket: this.props.app_config_s3.table.bucket,
            awsRegion: this.props.app_config_s3.table.region,
            // Assign any first signerUrl, but it changes for each upload file type
            // when call evaporate object add method bellow
            signerUrl: `/stash/data_file/presign_upload/${this.props.resource_id}`,
            awsSignatureVersion: "4",
            computeContentMd5: true,
            cryptoMd5Method: data => { return AWS.util.crypto.md5(data, 'base64'); },
            cryptoHexEncodedHash256: data => { return AWS.util.crypto.sha256(data, 'hex'); }
        }
        Evaporate.create(config).then(this.uploadFileToS3);
    }

    uploadFileToS3 = evaporate => {
        this.state.chosenFiles.map((file, index) => {
            if (file.status === 'Pending') {
                //TODO: Certify if file.uploadType has an entry in AllowedUploadFileTypes
                const evaporateUrl =
                    `${this.props.s3_dir_name}/${AllowedUploadFileTypes[file.uploadType]}/${file.sanitized_name}`;
                const addConfig = {
                    name: evaporateUrl,
                    file: file,
                    contentType: file.type,
                    progress: progressValue => {
                        document.getElementById(
                            `progressbar_${index}`
                        ).setAttribute('value', progressValue);
                    },
                    error: function (msg) {
                        console.log(msg);
                    },
                    complete: (_xhr, awsKey) => {
                        const csrf_token = document.querySelector('[name=csrf-token]');
                        if (csrf_token)  // there isn't csrf token when running Capybara tests
                            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;
                        axios.post(
                            `/stash/${file.uploadType}_file/upload_complete/${this.props.resource_id}`,
                            {
                                resource_id: this.props.resource_id,
                                name: file.sanitized_name,
                                size: file.size,
                                type: file.type,
                                original: file.name
                            })
                            .then(response => {
                                console.log(response);
                                this.setFileUploadComplete(response.data.new_file, index);
                            })
                            .catch(error => console.log(error));
                    }
                }
                // Before start uploading, change file status cel to a progress bar
                this.changeStatusToProgressBar(index);

                const signerUrl = `/stash/${file.uploadType}_file/presign_upload/${this.props.resource_id}`;
                evaporate.add(addConfig, {signerUrl: signerUrl})
                    .then(
                        awsObjectKey => console.log('File successfully uploaded to: ', awsObjectKey),
                        reason => console.log('File did not upload successfully: ', reason)
                    );
            }
        })

    }

    getPendingFiles = () => {
        return this.state.chosenFiles.filter((file) => {
            return file.status === 'Pending';
        });
    }

    setFileUploadComplete = (file, index) => {
        const chosenFiles = this.state.chosenFiles;
        chosenFiles[index].id = file.id;
        chosenFiles[index].status = 'New';
        this.setState({chosenFiles: chosenFiles});
    }

    changeStatusToProgressBar = (chosenFilesIndex) => {
        const status_cel = document.getElementById(`status_${chosenFilesIndex}`);
        status_cel.innerText = '';
        const node = document.createElement('progress');
        const progressBar = status_cel.appendChild(node);
        progressBar.setAttribute('id', `progressbar_${chosenFilesIndex}`);
        progressBar.setAttribute('value', '');
    }

    updateManifestFiles = (files) => {
        this.updateFailedUrls(files['invalid_urls']);

        if (!files['valid_urls'].length) return;
        let successfulUrls = files['valid_urls'];
        if (this.state.chosenFiles.length) {
            successfulUrls = this.discardAlreadyChosenById(successfulUrls);
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
        if (!this.state.chosenFiles.length) {
            this.setState({chosenFiles: files});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(files);
            this.setState({chosenFiles: chosenFiles});
        }
    }

    removeFileHandler = (fileIndex) => {
        let chosenFiles = [...this.state.chosenFiles];
        if (chosenFiles[fileIndex].status !== 'Pending') {
            this.removeFile(chosenFiles[fileIndex]);
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

        const urlsObject = {
            url: this.discardFilesAlreadyChosen(this.state.urls, this.state.currentManifestFileType)
        };
        if (urlsObject['url'].length) {
            this.setState({loading: true});
            const typeFilePartialRoute = this.state.currentManifestFileType + '_file';
            axios.post(`/stash/${typeFilePartialRoute}/validate_urls/${this.props.resource_id}`, urlsObject)
                .then(response => {
                    this.updateManifestFiles(response.data);
                    this.setState({urls: null, loading: false});
                })
                .catch(error => console.log(error));
        }
    };

    discardFilesAlreadyChosen = (urls, uploadType) => {
        let filesAlreadySelected = this.state.chosenFiles.filter(file => {
            return file.uploadType === uploadType;
        });
        if (!filesAlreadySelected.length) return urls;

        urls = urls.split('\n');
        const final_urls = [...urls];

        for (let i = 0; i < urls.length; i++) {
            for (let j = 0; j < filesAlreadySelected.length; j++) {
                if (urls[i].includes(filesAlreadySelected[j].name)) {
                    const index = final_urls.indexOf(urls[i]);
                    final_urls.splice(index, 1);
                }
            }
        }

        return final_urls.join('\n');
    }

    transformData = (files) => {
        return files.map(file => ({
            ...file,
            sanitized_name: file.upload_file_name,
            status: 'New',  // TODO: correctly define the status based on status in database
            uploadType: RailsActiveRecordToUploadType[file.type],
            sizeKb: formatSizeUnits(file.upload_file_size)
        }))
    }

    /**
     * The controller returns data with the successfully inserted manifest
     * files into the table. Check for the files already added to this.state.chosenFiles.
     * @param files
     * @returns {[]}
     */
    discardAlreadyChosenById = (files) => {
        const idsAlready = this.state.chosenFiles.map(item => item.id);
        return files.filter(file => {
            return !idsAlready.includes(file.id);
        });
    }

    // TODO: maybe merge this with discardAlreadyChosenById
    discardAlreadyChosenByName = (files, uploadType) => {
        let filesAlreadySelected = this.state.chosenFiles.filter(file => {
            return file.uploadType === uploadType;
        });
        filesAlreadySelected = filesAlreadySelected.map(file => file.sanitized_name);

        return files.filter(file => {
            return !filesAlreadySelected.includes(file.name);
        });
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

    removeFile = (file) => {
        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running Capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;

        axios.patch(`/stash/${file.uploadType}_files/${file.id}/destroy_manifest`)
            .then(response => {
                console.log(response.data);
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
                    {this.state.loading ? <LoadingSpinner /> : null}
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
                    {this.state.loading ? <LoadingSpinner /> : <p>No files have been selected.</p>}
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
