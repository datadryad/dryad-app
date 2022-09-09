/* eslint-disable */
/* TODO: Come back to this and fix.  This is a large file and will probably generate hundreds of warnings.
   Right now it is only showing      "60:11  error  Parsing error: Unexpected token =" (line number might be slightly off).
   From experience, as soon as this one issue is resolved then it will release a giant flood of other errors.
 */

import React from 'react';
import axios from 'axios';
import Evaporate from 'evaporate';
import AWS from 'aws-sdk';
import sanitize from '../../../lib/sanitize_filename';

import UploadType from '../../components/FileUpload/UploadType/UploadType';
import ModalUrl from '../../components/FileUpload/Modal/ModalUrl';
import ModalValidationReport from "../../components/FileUpload/ModalValidationReport/ModalValidationReport";
import FileList from '../../components/FileUpload/FileList/FileList';
import FailedUrlList from '../../components/FileUpload/FailedUrlList/FailedUrlList';
import ValidateFiles from "../../components/FileUpload/ValidateFiles/ValidateFiles";
import Instructions from '../../components/FileUpload/Instructions/Instructions';
import WarningMessage from '../../components/FileUpload/WarningMessage/WarningMessage';
import "@cdl-dryad/frictionless-components/dist/frictionless-components.css"

// TODO: check if this is the best way to refer to stash_engine files.
import '../../../../../app/assets/javascripts/stash_engine/resources.js';

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
const Messages = {
    'fileAlreadySelected': 'A file of the same type is already in the table, and was not added.',
    'filesAlreadySelected': 'Some files of the same type are already in the table, and were not added.'
}
const ValidTabular = {
    'extensions': ['csv', 'xls', 'xlsx'],
    'mime_types': ['text/csv', 'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
}
export const TabularCheckStatus = {
    'checking': 'Checking...',
    'issues': 'View Issues',
    'noissues': 'Passed',
    'na': 'Too Large For Validation',
    'error': "Couldn't Read Tabular Data"
}

export const displayAriaMsg = (msg) => {
    const el = document.getElementById('aria-info');
    const content = document.createTextNode(msg);
    el.innerHTML = '';
    el.appendChild(content);
}

class UploadFiles extends React.Component {
    state = {
        upload_type: [
            {
                type: 'data', logo: '../../../images/logo_dryad.svg', alt: 'Dryad',
                name: 'Data', description: 'Required: README', description2: 'e.g., csv, fasta',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs' },
            {
                type: 'software', logo: '../../../images/logo_zenodo.svg', alt: 'Zenodo',
                name: 'Software', description: 'e.g., code packages, scripts',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs' },
            {
                type: 'supp', logo: '../../../images/logo_zenodo.svg', alt: 'Zenodo',
                name: 'Supplemental Information', description: 'e.g., figures, supporting tables',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'
            }
        ],
        chosenFiles: [],
        submitButtonFilesDisabled: true,
        submitButtonUrlsDisabled: true,
        showModal: false,
        showValidationReportModal: false,
        urls: null,
        // TODO: workaround to deal with manifest file types when making request.
        //  See better way: maybe when clicking in URL button for an Upload Type,
        //  send the type information to the modal somehow. And when submitting carry on
        //  that information and add to request URL.
        currentManifestFileType: null,
        validationReportIndex: null,
        failedUrls: [],
        loading: false,
        removingIndex: null,
        warningMessage: null,
        validating: null,
        // This is for polling for completion for Frictionless being validated
        // Since this is not a hooks component, use the old way as demonstrated at
        // https://blog.bitsrc.io/polling-in-react-using-the-useinterval-custom-hook-e2bcefda4197
        pollingCount: 0,
        pollingDelay: 10000,
    };

    componentDidMount() {
        const files = this.props.file_uploads;
        const transformed = this.transformData(files);
        const withTabularCheckStatus = this.updateTabularCheckStatus(transformed);
        this.setState({chosenFiles: withTabularCheckStatus});
        this.addCsrfToken();
        this.interval = null; // may be set interval later
    }

    // I don't think this is needed and is only good for detecing changes between refreshes, I don't think we're
    // changing the interval, but might be useful if we are
    componentDidUpdate(prevProps, prevState, snapshot) {
        if (this.interval && prevState.pollingDelay !== this.state.pollingDelay) {
            clearInterval( this.interval );
            this.interval = setInterval(this.tick, this.state.pollingDelay);
        }
    }

    // clear interval before navigating away
    componentWillUnmount() {
        if (this.interval){
            clearInterval(this.interval);
        }
    }

    // this is a tick for polling of frictionless reports had results put into database
    tick = () => {
        this.setState({
            pollingCount: this.state.pollingCount + 1
        });
        console.log("polling for updates", this.state.pollingCount);

        // these are files with remaining checks
        const toCheck = this.state.chosenFiles.filter((f) =>
            (f?.id && f?.status == 'Uploaded' && f?.tabularCheckStatus == TabularCheckStatus['checking'] ) );

        console.log(toCheck);

        if(this.state.pollingCount > 500 || toCheck.length < 1 || this.state.validating == false){
            clearInterval(this.interval);
            this.interval = null;
            this.setState({validating: false});
            this.setState({pollingCount: 0});
            return;
        }

        axios.get(
            `/stash/generic_file/check_frictionless/${this.props.resource_id}`,
            { params: { file_ids: toCheck.map(file => file.id) } }
        ).then(response => {
            // this.setState({validating: false});
            const transformed = this.transformData(response.data);
            const files = this.simpleTabularCheckStatus(transformed);
            this.updateAlreadyChosenById(files);
            // now need to possibly turn validating to false and turn off timer if all are validated
        }).catch(error => console.log(error));
    }

    transformData = (files) => {
        return files.map(file => ({
            ...file,
            sanitized_name: file.upload_file_name,
            status: 'Uploaded',
            uploadType: RailsActiveRecordToUploadType[file.type],
            sizeKb: formatSizeUnits(file.upload_file_size),
        }))
    }

    // updates only based on the state of the actual report and not this.state.validating
    simpleTabularCheckStatus = (files) => {
        return files.map(file => ({
            ...file,
            tabularCheckStatus: this.setTabularCheckStatus(file)
        }));
    }

    // updates to checking (if during validation phase) or n/a or a status based on frictionless report from database
    updateTabularCheckStatus = (files) => {
        if (this.state.validating) {
            return files.map(file => ({...file, tabularCheckStatus: TabularCheckStatus['checking']}));
        } else {
            return this.simpleTabularCheckStatus(files);
        }
    }

    // set status based on contents of frictionless report
    setTabularCheckStatus = (file) => {
        if (!this.isValidTabular(file)) {
            return TabularCheckStatus['na'];
        } else if (file.frictionless_report) {
            return TabularCheckStatus[file.frictionless_report.status]
        }
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
            case 481:
                return '<a href="/stash/web_crawling" target="_blank">Crawling of HTML files</a> isn\'t supported.';
            case 500: case 501: case 502: case 503: case 504: case 505: case 506:
            case 507: case 508: case 509: case 510: case 511:
                return 'Encountered a remote server error while retrieving the request.';
        }
    }

    addCsrfToken = () => {
        const csrf_token = document.querySelector('[name=csrf-token]');
        if (csrf_token)  // there isn't csrf token when running Capybara tests
            axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;
    }

    // checks the file list if any files are pending and if so returns true (or false)
    hasPendingFiles = () => {
        return this.getPendingFiles().length > 0;
    }

    addFilesHandler = (event, uploadType) => {
        displayAriaMsg("Your files were added and are pending upload.");
        this.setState({warningMessage: null, submitButtonFilesDisabled: true});
        const newFiles = this.discardFilesAlreadyChosen([...event.target.files], uploadType);
        // TODO: make a function?; future: unify adding file attributes
        newFiles.map(file => {
            file.sanitized_name = sanitize(file.name);
            file.status = 'Pending';
            file.url = null;
            file.uploadType = uploadType;
            file.manifest = false;
            file.upload_file_size = file.size;
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
            signerUrl: `/stash/generic_file/presign_upload/${this.props.resource_id}`,
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
                        axios.post(
                            `/stash/${file.uploadType}_file/upload_complete/${this.props.resource_id}`,
                            {
                                resource_id: this.props.resource_id,
                                name: file.sanitized_name,
                                size: file.size,
                                type: file.type,
                                original: file.name
                            }).then(response => {
                                console.log(response);
                                this.updateFileData(response.data.new_file, index);
                                this.isValidTabular(this.state.chosenFiles[index]) ?
                                    this.validateFrictionlessLambda([this.state.chosenFiles[index]]) :
                                    null;
                            }).catch(error => console.log(error));
                    }
                }
                // Before start uploading, change file status cell to a progress bar
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

    updateFileData = (file, index) => {
        const chosenFiles = this.state.chosenFiles;
        chosenFiles[index].id = file.id;
        chosenFiles[index].sanitized_name = file.upload_file_name;
        chosenFiles[index].status = 'Uploaded';
        this.setState({chosenFiles: chosenFiles});
        displayAriaMsg(`${file.original_filename} finished uploading`);
    }

    changeStatusToProgressBar = (chosenFilesIndex) => {
        const statusCel = document.getElementById(`status_${chosenFilesIndex}`);
        statusCel.innerText = '';
        const node = document.createElement('progress');
        const progressBar = statusCel.appendChild(node);
        progressBar.setAttribute('id', `progressbar_${chosenFilesIndex}`);
        progressBar.setAttribute('value', '0');
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
        const tabularFiles = newManifestFiles.filter(file => this.isValidTabular(file));
        this.validateFrictionless(tabularFiles);
    }

    validateFrictionless = (files) => {
        this.setState({validating: true});
        files = this.updateTabularCheckStatus(files);
        this.updateAlreadyChosenById(files);
        axios.post(
            `/stash/generic_file/validate_frictionless/${this.props.resource_id}`,
            {file_ids: files.map(file => file.id)}
        ).then(response => {
            this.setState({validating: false});
            const transformed = this.transformData(response.data);
            files = this.updateTabularCheckStatus(transformed);
            this.updateAlreadyChosenById(files);
        }).catch(error => console.log(error));
    }

    // I'm not sure why this is plural since only one file at a time is passed in, maybe because of some of the
    // other methods it uses which rely on a collection
    validateFrictionlessLambda = (files) => {
        this.setState({validating: true});
        // sets file object to have tabularCheckStatus: TabularCheckStatus['checking']} || n/a or status based on report
        files = this.updateTabularCheckStatus(files);
        // I think these are files that are being uploaded now????  IDK what it means.
        this.updateAlreadyChosenById(files);
        // post to the method to trigger frictionless validation in AWS Lambda
        axios.post(
            `/stash/generic_file/trigger_frictionless/${this.props.resource_id}`,
            {file_ids: files.map(file => file.id)}
        ).then(response => {
            console.log("validateFrictionlessLambda RESPONSE", response);
            if (!this.interval){
                // start polling for report updates if not polling already
                this.interval = setInterval(this.tick, this.state.pollingDelay);
            }
        }).catch(error => console.log(error));
    }

    updateAlreadyChosenById = (filesToUpdate) => {
        const chosenFiles = [...this.state.chosenFiles];
        let index;
        filesToUpdate.forEach((fileToUpdate) => {
            index = chosenFiles.findIndex(file => file.id === fileToUpdate.id);
            chosenFiles[index] = fileToUpdate;
        })
        this.setState({chosenFiles: chosenFiles});
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

    updateFileList = (files) => {
        this.labelNonTabular(files);
        if (!this.state.chosenFiles.length) {
            this.setState({chosenFiles: files});
        } else {
            let chosenFiles = [...this.state.chosenFiles];
            chosenFiles = chosenFiles.concat(files);
            this.setState({chosenFiles: chosenFiles});
        }
    }

    hasPlainTextTabular = (files) => {
        return files.some(file => {
            return file.sanitized_name.split('.').pop() === 'csv'
                || file.upload_content_type === 'text/csv';
        });
    }

    labelNonTabular = (files) => {
        files.map(file => {
            file.tabularCheckStatus = this.isValidTabular(file) ? null : TabularCheckStatus['na']
        });
    }

    isValidTabular = (file) => {
        return (ValidTabular['extensions'].includes(file.sanitized_name.split('.').pop())
            || ValidTabular['mime_types'].includes(file.upload_content_type))
            && (file.upload_file_size <= this.props.frictionless.size_limit);
    }

    removeFileHandler = (index) => {
        this.setState({warningMessage: null});
        const file = this.state.chosenFiles[index];
        if (file.status !== 'Pending') {
            this.setState({removingIndex: index});
            axios.patch(`/stash/${file.uploadType}_files/${file.id}/destroy_manifest`)
                .then(response => {
                    console.log(response.data);
                    this.setState({removingIndex: null});
                    this.removeFileLine(index);
                })
                .catch(error => console.log(error));
        } else {
            this.removeFileLine(index);
        }
        displayAriaMsg(`${file.sanitized_name} removed`);
    }

    removeFileLine = (index) => {
        let chosenFiles = [...this.state.chosenFiles];
        chosenFiles.splice(index, 1);
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

    showModalHandler = (uploadType) => {
        this.setState({showModal: true, currentManifestFileType: uploadType});
    };

    hideModal = (event) => {
        if (event.type === 'submit' || event.type === 'click'
            || (event.type === 'keydown' && event.keyCode === 27)) {
            this.setState({
                submitButtonUrlsDisabled: true,
                showModal: false,
                currentManifestFileType: null
            })
        }
    }

    hideModalValidationReport = (event) => {
        this.setState({showValidationReportModal: false, validationReportIndex: null});
    }

    showModalValidationReportHandler = (index) => {
        this.setState({showValidationReportModal: true, validationReportIndex: index});
    }

    submitUrlsHandler = (event) => {
        this.setState({warningMessage: null});
        event.preventDefault();
        this.hideModal(event);
        this.toggleCheckedUrls(event);

        if (!this.state.urls) return;

        const urlsObject = {
            url: this.discardUrlsAlreadyChosen(this.state.urls, this.state.currentManifestFileType)
        };
        if (urlsObject['url'].length) {
            this.setState({loading: true});
            const typeFilePartialRoute = this.state.currentManifestFileType + '_file';
            axios.post(`/stash/${typeFilePartialRoute}/validate_urls/${this.props.resource_id}`, urlsObject)
                .then(response => {
                    this.updateManifestFiles(response.data);
                })
                .catch(error => console.log(error))
                .finally(() => this.setState({urls: null, loading: false}));
        }
    };

    discardUrlsAlreadyChosen = (urls, uploadType) => {
        urls = urls.split('\n');
        // Remove excess of newlines
        urls = urls.filter(url => url);

        const filenames = urls.map(url => url.split('/').pop());
        const newFilenames = this.discardAlreadyChosenByName(filenames, uploadType);
        if (filenames.length === newFilenames.length) return urls.join('\n');

        const newUrls = urls.filter(url => {
            return newFilenames.some(filename => url.includes(filename));
        });

        const countRepeated = urls.length - newUrls.length;
        this.setWarningRepeatedFile(countRepeated);
        return newUrls.join('\n');
    }

    /**
     * The controller returns data with the successfully inserted manifest
     * files into the table. Check for the files already added to this.state.chosenFiles.
     * @param files
     * @returns {[]}
     */
    discardAlreadyChosenById = (files) => {
        const idsAlready = this.state.chosenFiles.map(file => file.id);
        return files.filter(file => {
            return !idsAlready.includes(file.id);
        });
    }

    discardFilesAlreadyChosen = (files, uploadType) => {
        const filenames = files.map(file => file.name);
        const newFilenames = this.discardAlreadyChosenByName(filenames, uploadType);
        if (filenames.length === newFilenames.length) return files;

        const newFiles = files.filter(file => {
            return newFilenames.includes(file.name);
        });

        const countRepeated = files.length - newFiles.length;
        this.setWarningRepeatedFile(countRepeated);
        return newFiles;
    }

    discardAlreadyChosenByName = (filenames, uploadType) => {
        let filesAlreadySelected = this.state.chosenFiles.filter(file => {
            return file.uploadType === uploadType;
        });
        if (!filesAlreadySelected.length) return filenames;

        const filenamesAlreadySelected = filesAlreadySelected.map(file => file.sanitized_name);
        return filenames.filter(filename => {
            return !filenamesAlreadySelected.includes(sanitize(filename));
        })
    }

    setWarningRepeatedFile = (countRepeated) => {
        if (countRepeated < 0) return;
        if (countRepeated === 0) {
            this.setState({warningMessage: null});
        }
        let message;
        if (countRepeated === 1) message = Messages['fileAlreadySelected'];
        if (countRepeated > 1) message = Messages['filesAlreadySelected'];
        this.setState({warningMessage: message});
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

    removeFailedUrlHandler = (index) => {
        const failedUrls = this.state.failedUrls.filter((url, urlIndex) => {
            return urlIndex !== index;
        })
        this.setState({failedUrls: failedUrls});
    }

    buildFileList = (removingIndex) => {
        if (this.state.chosenFiles.length) {
            return (
                <div>
                    <FileList
                        chosenFiles={this.state.chosenFiles}
                        clickedRemove={this.removeFileHandler}
                        clickedValidationReport={this.showModalValidationReportHandler}
                        removingIndex={removingIndex} />
                    { this.state.loading ?
                        <div className="c-upload__loading-spinner">
                            <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
                        </div> : null }
                    {this.state.warningMessage ? <WarningMessage message={this.state.warningMessage} /> : null}
                    {this.hasPendingFiles() ?
                        <ValidateFiles
                            id='confirm_to_validate_files'
                            buttonLabel='Upload pending files'
                            checkConfirmed={true}
                            disabled={this.state.submitButtonFilesDisabled}
                            changed={this.toggleCheckedFiles}
                            clicked={this.uploadFilesHandler}/>
                        : null}
                </div>
            )
        } else {
            return (
                <div>
                    <h2 className="o-heading__level2">Files</h2>
                    { this.state.loading ?
                        <div className="c-upload__loading-spinner">
                            <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
                        </div> : <p>No files have been selected.</p> }
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
                clickedClose={this.hideModal} />
        } else {
            document.removeEventListener('keydown', this.hideModal);
            return null;
        }
    }

    buildValidationReportModal = () => {
        if (this.state.showValidationReportModal) {
            return <ModalValidationReport
                file={this.state.chosenFiles[this.state.validationReportIndex]}
                report={this.state.chosenFiles[this.state.validationReportIndex].frictionless_report.report}
                clickedClose={this.hideModalValidationReport} />
        } else {
            return null;
        }
    }

    render () {
        const failedUrls = this.buildFailedUrlList();
        const chosenFiles = this.buildFileList(this.state.removingIndex);
        const modalURL = this.buildModal();
        const modalValidationReport = this.buildValidationReportModal();

        return (
            <div className="c-upload">
                {modalURL}
                {modalValidationReport}
                <h1 className="o-heading__level1">
                    Upload Your Files
                </h1>
                <Instructions />
                <div className="c-uploadwidgets">
                    {this.state.upload_type.map((upload_type) => {
                        return <UploadType
                            key={upload_type.type}
                            changed={(event) => this.addFilesHandler(event, upload_type.type)}
                            // triggers change to reset file uploads to null before onChange to allow files to be added again
                            clickedFiles={(event) => event.target.value = null}

                            clickedModal={() => this.showModalHandler(upload_type.type)}
                            type={upload_type.type}
                            logo={upload_type.logo}
                            alt={upload_type.alt}
                            name={upload_type.name}
                            description={upload_type.description}
	     		    description2={upload_type.description2}
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
