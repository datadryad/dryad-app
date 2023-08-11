import React from 'react';
import axios from 'axios';
import Evaporate from 'evaporate';
import AWS from 'aws-sdk';
import ReactDOM from 'react-dom';
import {render} from '@cdl-dryad/frictionless-components/lib/render';
import {Report} from '@cdl-dryad/frictionless-components/lib/components/Report';
import sanitize from '../../../lib/sanitize_filename';

import {
  UploadType, ModalUrl, ModalValidationReport, FileList, TabularCheckStatus, FailedUrlList, ValidateFiles, Instructions, WarningMessage,
} from '../../components/FileUpload';
import '@cdl-dryad/frictionless-components/dist/frictionless-components.css';

/**
 * Constants
 */
const maxFiles = 1000;
const RailsActiveRecordToUploadType = {
  'StashEngine::DataFile': 'data',
  'StashEngine::SoftwareFile': 'software',
  'StashEngine::SuppFile': 'supp',
};
const AllowedUploadFileTypes = {
  data: 'data',
  software: 'sfw',
  supp: 'supp',
};
const Messages = {
  fileReadme: 'Please prepare your README on the previous page',
  fileAlreadySelected: 'A file of the same name is already in the table, and was not added.',
  filesAlreadySelected: 'Some files of the same name are already in the table, and were not added.',
  tooManyFiles: `You may not upload more than ${maxFiles} individual files.`,
};
const ValidTabular = {
  extensions: ['csv', 'tsv', 'xls', 'xlsx', 'json', 'xml'],
  mime_types: ['text/csv', 'text/tab-separated-values', 'application/vnd.ms-excel', 'text/xml',
    'application/xml', 'application/json', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ],
};
const upload_types = [
  {
    type: 'data',
    logo: '../../../images/logo_dryad.svg',
    alt: 'Dryad',
    name: 'Data',
    description: 'e.g., csv, xsl, fasta',
    buttonFiles: 'Choose files',
    buttonURLs: 'Enter URLs',
  },
  {
    type: 'software',
    logo: '../../../images/logo_zenodo.svg',
    alt: 'Zenodo',
    name: 'Software',
    description: 'e.g., code packages, scripts',
    buttonFiles: 'Choose files',
    buttonURLs: 'Enter URLs',
  },
  {
    type: 'supp',
    logo: '../../../images/logo_zenodo.svg',
    alt: 'Zenodo',
    name: 'Supplemental information',
    description: 'e.g., figures, supporting tables',
    buttonFiles: 'Choose files',
    buttonURLs: 'Enter URLs',
  },
];

export const displayAriaMsg = (msg) => {
  const el = document.getElementById('aria-info');
  const content = document.createTextNode(msg);
  el.innerHTML = '';
  el.appendChild(content);
};

const formatSizeUnits = (bytes) => {
  if (bytes === 1) {
    return '1 byte';
  } if (bytes < 1000) {
    return `${bytes} B`;
  }

  const units = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  for (let i = 0; i < units.length; i += 1) {
    if (bytes / 10 ** (3 * (i + 1)) < 1) {
      return `${(bytes / 10 ** (3 * i)).toFixed(2)} ${units[i]}`;
    }
  }
  return true;
};

const transformData = (files) => files.map((file) => ({
  ...file,
  sanitized_name: file.upload_file_name,
  status: 'Uploaded',
  uploadType: RailsActiveRecordToUploadType[file.type],
  sizeKb: formatSizeUnits(file.upload_file_size),
}));

const getErrorMessage = (url) => {
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
  // case 500: case 501: case 502: case 503: case 504: case 505: case 506: case 507: case 508: case 509: case 510: case 511:
  default:
    return 'Encountered a remote server error while retrieving the request.';
  }
};

const addCsrfToken = () => {
  const csrf_token = document.querySelector('[name=csrf-token]');
  if (csrf_token) { // there isn't csrf token when running Capybara tests
    axios.defaults.headers.common['X-CSRF-TOKEN'] = csrf_token.content;
  }
};

const changeStatusToProgressBar = (chosenFileId) => {
  const statusCel = document.getElementById(`status_${chosenFileId}`);
  statusCel.innerText = '';
  const node = document.createElement('progress');
  const progressBar = statusCel.appendChild(node);
  progressBar.setAttribute('id', `progressbar_${chosenFileId}`);
  progressBar.setAttribute('value', '0');
};

class UploadFiles extends React.Component {
  state = {
    chosenFiles: [],
    submitButtonFilesDisabled: true,
    urls: null,
    // TODO: workaround to deal with manifest file types when making request.
    //  See better way: maybe when clicking in URL button for an Upload Type,
    //  send the type information to the modal somehow. And when submitting carry on
    //  that information and add to request URL.
    currentManifestFileType: null,
    validationReportFile: null,
    failedUrls: [],
    loading: false,
    warningMessage: null,
    validating: null,
    // This is for polling for completion for Frictionless being validated
    // Since this is not a hooks component, use the old way as demonstrated at
    // https://blog.bitsrc.io/polling-in-react-using-the-useinterval-custom-hook-e2bcefda4197
    pollingCount: 0,
    pollingDelay: 10000,
  };

  modalRef = React.createRef();

  modalValidationRef = React.createRef();

  componentDidMount() {
    const files = this.props.file_uploads;
    const transformed = transformData(files);
    const withTabularCheckStatus = this.updateTabularCheckStatus(transformed);
    this.setState({chosenFiles: withTabularCheckStatus});
    addCsrfToken();
    this.interval = null; // may be set interval later
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.interval && prevState.pollingDelay !== this.state.pollingDelay) {
      clearInterval(this.interval);
      this.interval = setInterval(this.tick, this.state.pollingDelay);
    }
  }

  // clear interval before navigating away
  componentWillUnmount() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  // this is a tick for polling of frictionless reports had results put into database
  tick = () => {
    const {pollingCount, chosenFiles} = this.state;
    this.setState({
      pollingCount: pollingCount + 1,
    }, () => console.log('polling for Frictionless report updates', pollingCount));

    // these are files with remaining checks
    const toCheck = chosenFiles.filter((f) => (f?.id && f?.status === 'Uploaded' && f?.tabularCheckStatus === TabularCheckStatus.checking));

    if (this.checkPollingDone(toCheck)) return;

    console.log(toCheck);

    axios.get(
      `/stash/generic_file/check_frictionless/${this.props.resource_id}`,
      {params: {file_ids: toCheck.map((file) => file.id)}},
    ).then((response) => {
      const transformed = transformData(response.data);
      const files = this.simpleTabularCheckStatus(transformed);
      this.updateAlreadyChosenById(files);
      const updatedFiles = chosenFiles.filter((f) => (f?.id && f?.status === 'Uploaded' && f?.tabularCheckStatus === TabularCheckStatus.checking));
      this.checkPollingDone(updatedFiles);
    }).catch((error) => console.log(error));
  };

  checkPollingDone = (filteredFiles) => {
    if (this.state.pollingCount > 60 || filteredFiles.length < 1 || !this.state.validating) {
      // 60 * 10000 = 600000 or 10 minutes
      clearInterval(this.interval);
      this.interval = null;
      this.setState({validating: false, pollingCount: 0}, () => {
        // Set any unchecked files as error after 10 minutes
        const files = this.simpleTabularCheckStatus(filteredFiles);
        this.updateAlreadyChosenById(files);
      });
      return true;
    }
    return false;
  };

  // updates only based on the state of the actual report and not this.state.validating
  simpleTabularCheckStatus = (files) => files.map((file) => ({
    ...file,
    tabularCheckStatus: this.setTabularCheckStatus(file),
  }));

  // updates to checking (if during validation phase) or n/a or a status based on frictionless report from database
  updateTabularCheckStatus = (files) => {
    if (this.state.validating) {
      return files.map((file) => ({...file, tabularCheckStatus: TabularCheckStatus.checking}));
    }
    return this.simpleTabularCheckStatus(files);
  };

  // set status based on contents of frictionless report
  setTabularCheckStatus = (file) => {
    if (!this.isValidTabular(file)) {
      return TabularCheckStatus.na;
    } if (file.frictionless_report) {
      return TabularCheckStatus[file.frictionless_report.status];
    }
    return TabularCheckStatus.error;
  };

  addFilesHandler = (event, uploadType) => {
    displayAriaMsg('Your files are being checked');
    this.setState({warningMessage: null, submitButtonFilesDisabled: true});
    const files = this.discardFilesAlreadyChosen([...event.target.files], uploadType);
    const fileCount = this.state.chosenFiles.length + files.length;
    if (fileCount > maxFiles) {
      this.setState({warningMessage: Messages.tooManyFiles});
    } else {
      displayAriaMsg('Your files were added and are pending upload.');
      // TODO: make a function?; future: unify adding file attributes
      const newFiles = files.map((file, index) => {
        file.id = `pending${this.state.chosenFiles.length + index}`;
        file.sanitized_name = sanitize(file.name);
        file.status = 'Pending';
        file.url = null;
        file.uploadType = uploadType;
        file.manifest = false;
        file.upload_file_size = file.size;
        file.sizeKb = formatSizeUnits(file.size);
        return file;
      });
      this.updateFileList(newFiles);
    }
  };

  uploadFilesHandler = () => {
    const config = {
      aws_key: this.props.app_config_s3.table.key,
      bucket: this.props.app_config_s3.table.bucket,
      awsRegion: this.props.app_config_s3.table.region,
      // Assign any first signerUrl, but it changes for each upload file type
      // when call evaporate object add method bellow
      signerUrl: `/stash/generic_file/presign_upload/${this.props.resource_id}`,
      awsSignatureVersion: '4',
      computeContentMd5: true,
      cryptoMd5Method: (data) => AWS.util.crypto.md5(data, 'base64'),
      cryptoHexEncodedHash256: (data) => AWS.util.crypto.sha256(data, 'hex'),
    };
    Evaporate.create(config).then(this.uploadFileToS3);
  };

  uploadFileToS3 = (evaporate) => {
    this.state.chosenFiles.map((file, index) => {
      if (file.status === 'Pending') {
        // TODO: Certify if file.uploadType has an entry in AllowedUploadFileTypes
        const evaporateUrl = `${this.props.s3_dir_name}/${AllowedUploadFileTypes[file.uploadType]}/${file.sanitized_name}`;
        const addConfig = {
          name: evaporateUrl,
          file,
          contentType: file.type,
          progress: (progressValue) => {
            document.getElementById(
              `progressbar_${file.id}`,
            ).setAttribute('value', progressValue);
          },
          error(msg) {
            console.log(msg);
          },
          complete: () => {
            axios.post(
              `/stash/${file.uploadType}_file/upload_complete/${this.props.resource_id}`,
              {
                resource_id: this.props.resource_id,
                name: file.sanitized_name,
                size: file.size,
                type: file.type,
                original: file.name,
              },
            ).then((response) => {
              console.log(response);
              this.updateFileData(response.data.new_file, index);
              if (this.isValidTabular(this.state.chosenFiles[index])) {
                this.validateFrictionlessLambda([this.state.chosenFiles[index]]);
              }
            }).catch((error) => console.log(error));
          },
        };
        // Before start uploading, change file status cell to a progress bar
        changeStatusToProgressBar(file.id);

        const signerUrl = `/stash/${file.uploadType}_file/presign_upload/${this.props.resource_id}`;
        evaporate.add(addConfig, {signerUrl})
          .then(
            (awsObjectKey) => console.log('File successfully uploaded to: ', awsObjectKey),
            (reason) => console.log('File did not upload successfully: ', reason),
          );
      }
      return true;
    });
  };

  updateFileData = (file, index) => {
    const {chosenFiles} = this.state;
    chosenFiles[index].id = file.id;
    chosenFiles[index].sanitized_name = file.upload_file_name;
    chosenFiles[index].status = 'Uploaded';
    this.setState({chosenFiles});
    displayAriaMsg(`${file.original_filename} finished uploading`);
  };

  updateManifestFiles = (files) => {
    this.updateFailedUrls(files.invalid_urls);

    if (!files.valid_urls.length) return;
    let successfulUrls = files.valid_urls;
    if (this.state.chosenFiles.length) {
      successfulUrls = this.discardAlreadyChosenById(successfulUrls);
    }
    const newManifestFiles = transformData(successfulUrls);
    this.updateFileList(newManifestFiles);
    const tabularFiles = newManifestFiles.filter((file) => this.isValidTabular(file));
    this.validateFrictionlessLambda(tabularFiles);
  };

  // I'm not sure why this is plural since only one file at a time is passed in, maybe because of some of the
  // other methods it uses which rely on a collection
  validateFrictionlessLambda = (f) => {
    this.setState({validating: true}, () => {
      // sets file object to have tabularCheckStatus: TabularCheckStatus['checking']} || n/a or status based on report
      const files = this.updateTabularCheckStatus(f);
      // I think these are files that are being uploaded now????  IDK what it means.
      this.updateAlreadyChosenById(files);
      // post to the method to trigger frictionless validation in AWS Lambda
      axios.post(
        `/stash/generic_file/trigger_frictionless/${this.props.resource_id}`,
        {file_ids: files.map((file) => file.id)},
      ).then((response) => {
        console.log('validateFrictionlessLambda RESPONSE', response);
        if (!this.interval) {
          // start polling for report updates if not polling already
          this.interval = setInterval(this.tick, this.state.pollingDelay);
        }
      }).catch((error) => console.log(error));
    });
  };

  updateAlreadyChosenById = (filesToUpdate) => {
    const {chosenFiles} = this.state;
    filesToUpdate.forEach((fileToUpdate) => {
      const index = chosenFiles.findIndex((file) => file.id === fileToUpdate.id);
      chosenFiles[index] = fileToUpdate;
    });
    this.setState({chosenFiles});
  };

  updateFailedUrls = (urls) => {
    if (!urls.length) return;
    urls.map((url) => {
      url.error_message = getErrorMessage(url);
      return url;
    });
    let {failedUrls} = this.state;
    failedUrls = failedUrls.concat(urls);
    this.setState({failedUrls});
  };

  updateFileList = (files) => {
    this.labelNonTabular(files);
    if (!this.state.chosenFiles.length) {
      this.setState({chosenFiles: files});
    } else {
      let {chosenFiles} = this.state;
      chosenFiles = chosenFiles.concat(files);
      this.setState({chosenFiles});
    }
  };

  /* hasPlainTextTabular = (files) => files.some((file) => file.sanitized_name.split('.').pop() === 'csv'
                || file.upload_content_type === 'text/csv'); */

  labelNonTabular = (files) => {
    files.map((file) => {
      file.tabularCheckStatus = this.isValidTabular(file) ? null : TabularCheckStatus.na;
      return file;
    });
  };

  isValidTabular = (file) => (ValidTabular.extensions.includes(file.sanitized_name.split('.').pop())
            || ValidTabular.mime_types.includes(file.upload_content_type))
            && (file.upload_file_size <= this.props.frictionless.size_limit);

  removeFileHandler = (id) => {
    this.setState({warningMessage: null});
    const file = this.state.chosenFiles.find((f) => f.id === id);
    if (file.status !== 'Pending') {
      axios.patch(`/stash/${file.uploadType}_files/${id}/destroy_manifest`)
        .then((response) => {
          console.log(response.data);
          this.removeFileLine(id);
        })
        .catch((error) => console.log(error));
    } else {
      this.removeFileLine(id);
    }
    displayAriaMsg(`${file.sanitized_name} removed`);
  };

  removeFileLine = (id) => {
    const {chosenFiles} = this.state;
    const removed = chosenFiles.filter((f) => f.id !== id);
    this.setState({chosenFiles: removed});
  };

  toggleCheckedFiles = (event) => {
    this.setState({submitButtonFilesDisabled: !event.target.checked});
  };

  /* toggleCheckedUrls = (event) => {
    this.setState({submitButtonUrlsDisabled: !event.target.checked});
  }; */

  showModalHandler = (uploadType) => {
    this.setState({currentManifestFileType: uploadType});
    this.modalRef.current.showModal();
    document.addEventListener('keydown', this.hideModal);
  };

  hideModal = (event) => {
    if (this.modalRef.current && (event.type === 'submit' || event.type === 'click'
            || (event.type === 'keydown' && event.keyCode === 27))) {
      this.modalRef.current.close();
      this.setState({
        // submitButtonUrlsDisabled: true,
        currentManifestFileType: null,
      });
      document.removeEventListener('keydown', this.hideModal);
    }
  };

  hideValidationReport = () => {
    this.modalValidationRef.current.close();
    const element = document.getElementById('validation_report');
    ReactDOM.unmountComponentAtNode(element);
    this.setState({validationReportFile: null});
  };

  showValidationReportHandler = (file) => {
    this.setState({validationReportFile: file}, () => {
      const element = document.getElementById('validation_report');
      const {report} = file ? file.frictionless_report : {};
      if (report) render(Report, JSON.parse(report), element);
      this.modalValidationRef.current.showModal();
    });
  };

  submitUrlsHandler = (event) => {
    this.setState({warningMessage: null});
    event.preventDefault();
    this.hideModal(event);
    // this.toggleCheckedUrls(event);

    if (!this.state.urls) return;

    const urlsObject = {
      url: this.discardUrlsAlreadyChosen(this.state.urls, this.state.currentManifestFileType),
    };
    if (urlsObject.url.length) {
      this.setState({loading: true});
      const typeFilePartialRoute = `${this.state.currentManifestFileType}_file`;
      axios.post(`/stash/${typeFilePartialRoute}/validate_urls/${this.props.resource_id}`, urlsObject)
        .then((response) => {
          this.updateManifestFiles(response.data);
        })
        .catch((error) => console.log(error))
        .finally(() => this.setState({urls: null, loading: false}));
    }
  };

  discardUrlsAlreadyChosen = (uris, uploadType) => {
    const urls = uris.split('\n').filter((url) => url);

    const filenames = urls.map((url) => url.split('/').pop());
    const newFilenames = this.discardAlreadyChosenByName(filenames, uploadType);
    if (filenames.length === newFilenames.length) return urls.join('\n');

    const newUrls = urls.filter((url) => newFilenames.some((filename) => url.includes(filename)));

    const countRepeated = urls.length - newUrls.length;
    this.setWarningRepeatedFile(countRepeated);
    return newUrls.join('\n');
  };

  /**
     * The controller returns data with the successfully inserted manifest
     * files into the table. Check for the files already added to this.state.chosenFiles.
     * @param files
     * @returns {[]}
     */
  discardAlreadyChosenById = (files) => {
    const idsAlready = this.state.chosenFiles.map((file) => file.id);
    return files.filter((file) => !idsAlready.includes(file.id));
  };

  discardFilesAlreadyChosen = (files, uploadType) => {
    const filenames = files.map((file) => file.name);
    const newFilenames = this.discardAlreadyChosenByName(filenames, uploadType);
    if (filenames.length === newFilenames.length) return files;

    const newFiles = files.filter((file) => newFilenames.includes(file.name));

    const countRepeated = files.length - newFiles.length;
    if (filenames.includes('README.md')) {
      this.setState({warningMessage: Messages.fileReadme});
    } else {
      this.setWarningRepeatedFile(countRepeated);
    }
    return newFiles;
  };

  discardAlreadyChosenByName = (filenames, uploadType) => {
    const filesAlreadySelected = this.state.chosenFiles.filter((file) => file.uploadType === uploadType
      || file.sanitized_name.toLowerCase() === 'readme.md');
    if (!filesAlreadySelected.length) return filenames;

    const filenamesAlreadySelected = filesAlreadySelected.map((file) => file.sanitized_name.toLowerCase());

    return filenames.filter((filename) => !filenamesAlreadySelected.includes(sanitize(filename).toLowerCase())
      && sanitize(filename).toLowerCase() !== 'readme.md');
  };

  setWarningRepeatedFile = (countRepeated) => {
    if (countRepeated < 0) return;
    if (countRepeated === 0) {
      this.setState({warningMessage: null});
    }
    let message;
    if (countRepeated === 1) message = Messages.fileAlreadySelected;
    if (countRepeated > 1) message = Messages.filesAlreadySelected;
    this.setState({warningMessage: message});
  };

  onChangeUrls = (event) => {
    this.setState({urls: event.target.value});
  };

  removeFailedUrlHandler = (index) => {
    let {failedUrls} = this.state;
    failedUrls = failedUrls.filter((url, urlIndex) => urlIndex !== index);
    this.setState({failedUrls});
  };

  // checks the file list if any files are pending and if so returns true (or false)
  hasPendingFiles = () => this.state.chosenFiles.filter((file) => file.status === 'Pending').length > 0;

  render() {
    const {
      failedUrls, chosenFiles, loading, warningMessage, validationReportFile,
    } = this.state;
    return (
      <div className="c-upload">
        <h1 className="o-heading__level1">
          Upload your files
        </h1>
        <Instructions />
        <div className="c-uploadwidgets">
          {upload_types.map((upload_type) => (
            <UploadType
              key={upload_type.type}
              changed={(event) => this.addFilesHandler(event, upload_type.type)}
              // triggers change to reset file uploads to null before onChange to allow files to be added again
              clickedFiles={(event) => { event.target.value = null; }}
              clickedModal={() => this.showModalHandler(upload_type.type)}
              type={upload_type.type}
              logo={upload_type.logo}
              alt={upload_type.alt}
              name={upload_type.name}
              description={upload_type.description}
              description2={upload_type.description2}
              buttonFiles={upload_type.buttonFiles}
              buttonURLs={upload_type.buttonURLs}
            />
          ))}
        </div>
        {failedUrls.length > 0 && <FailedUrlList failedUrls={failedUrls} clicked={this.removeFailedUrlHandler} />}
        {chosenFiles.length > 0 ? (
          <div>
            <FileList
              chosenFiles={chosenFiles}
              clickedRemove={this.removeFileHandler}
              clickedValidationReport={this.showValidationReportHandler}
              totalSize={formatSizeUnits(chosenFiles.reduce((s, f) => s + f.upload_file_size, 0) + this.props.readme_size)}
              readmeSize={formatSizeUnits(this.props.readme_size)}
            />
            {loading && (
              <div className="c-upload__loading-spinner">
                <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
              </div>
            )}
            {warningMessage && <WarningMessage message={warningMessage} />}
            {this.hasPendingFiles() && (
              <ValidateFiles
                id="confirm_to_validate_files"
                buttonLabel="Upload pending files"
                checkConfirmed
                disabled={this.state.submitButtonFilesDisabled}
                changed={this.toggleCheckedFiles}
                clicked={this.uploadFilesHandler}
              />
            )}
          </div>
        ) : (
          <div>
            <h2 className="o-heading__level2">Files</h2>
            {loading ? (
              <div className="c-upload__loading-spinner">
                <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
              </div>
            ) : <p>No files have been selected.</p> }
          </div>
        )}
        <ModalUrl
          ref={this.modalRef}
          submitted={this.submitUrlsHandler}
          changedUrls={this.onChangeUrls}
          clickedClose={this.hideModal}
        />
        <ModalValidationReport
          file={validationReportFile}
          ref={this.modalValidationRef}
          clickedClose={this.hideValidationReport}
        />
      </div>
    );
  }
}

export default UploadFiles;
