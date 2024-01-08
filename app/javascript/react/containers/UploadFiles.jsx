import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import Evaporate from 'evaporate';
import AWS from 'aws-sdk';
import sanitize from '../../lib/sanitize_filename';
import {maxFiles, pollingDelay} from './maximums';

import {
  ModalUrl, ModalValidationReport, FileList, TabularCheckStatus, FailedUrlList, UploadSelect, ValidateFiles, WarningMessage, TrackChanges,
} from '../components/FileUpload';
/**
 * Constants
 */
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
  fileReadme: 'Please prepare your README on the previous page.',
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

export const displayAriaMsg = (msg) => {
  const el = document.getElementById('aria-info');
  const content = document.createTextNode(msg);
  el.innerHTML = '';
  el.appendChild(content);
};

const formatSizeUnits = (bytes) => {
  if (bytes < 1000) {
    return `${bytes} B`;
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
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

export default function UploadFiles({
  file_uploads, resource_id, frictionless, app_config_s3, s3_dir_name, readme_size, previous_version, file_note,
}) {
  const [chosenFiles, setChosenFiles] = useState([]);
  const [validating, setValidating] = useState([]);
  const [failedUrls, setFailedUrls] = useState([]);
  const [submitDisabled, setSubmitDisabled] = useState(true);
  const [loading, setLoading] = useState(false);
  const [urls, setUrls] = useState(null);
  const [manFileType, setManFileType] = useState(null);
  const [valFile, setValFile] = useState(null);
  const [warning, setWarning] = useState(null);
  const [pollingCount, setPollingCount] = useState(0);

  const modalRef = useRef(null);
  const modalValidationRef = useRef(null);
  const interval = useRef(null);

  const isValidTabular = (file) => (ValidTabular.extensions.includes(file.sanitized_name.split('.').pop())
            || ValidTabular.mime_types.includes(file.upload_content_type))
            && (file.upload_file_size <= frictionless.size_limit);

  const labelNonTabular = (files) => {
    files.map((file) => {
      file.tabularCheckStatus = isValidTabular(file) ? null : TabularCheckStatus.na;
      return file;
    });
  };

  // set status based on contents of frictionless report
  const setTabularCheckStatus = (file) => {
    if (!isValidTabular(file)) {
      return TabularCheckStatus.na;
    } if (file.frictionless_report) {
      return TabularCheckStatus[file.frictionless_report.status];
    }
    return TabularCheckStatus.error;
  };

  // updates only based on the state of the actual report and not this.state.validating
  const simpleTabularCheckStatus = (files) => files.map((file) => ({
    ...file,
    tabularCheckStatus: setTabularCheckStatus(file),
  }));

  // updates to checking (if during validation phase) or n/a or a status based on frictionless report from database
  const updateTabularCheckStatus = (files) => {
    if (validating.length) {
      return files.map((file) => ({...file, tabularCheckStatus: TabularCheckStatus.checking}));
    }
    return simpleTabularCheckStatus(files);
  };

  useEffect(() => {
    const files = file_uploads;
    const transformed = transformData(files);
    const withTabularCheckStatus = updateTabularCheckStatus(transformed);
    setChosenFiles(withTabularCheckStatus);
    addCsrfToken();
    interval.current = null; // may be set interval later
    return () => {
      // clear interval before navigating away
      if (interval.current) {
        clearInterval(interval.current);
      }
    };
  }, []);

  const updateAlreadyChosenById = (filesToUpdate) => {
    setChosenFiles((cf) => cf.map((f) => {
      const updateFile = filesToUpdate.find((u) => u.id === f.id);
      if (updateFile) {
        return updateFile;
      }
      return f;
    }));
  };

  const checkPollingDone = (filteredFiles) => {
    if (pollingCount > 60 || filteredFiles.length < 1 || !validating.length) {
      // 60 * 10000 = 600000 or 10 minutes
      clearInterval(interval.current);
      interval.current = null;
      setPollingCount(0);
      // Set any unchecked files as error after 10 minutes
      const files = simpleTabularCheckStatus(filteredFiles);
      updateAlreadyChosenById(files);
      return true;
    }
    return false;
  };

  useEffect(() => {
    if (pollingCount === 0) {
      setValidating([]);
      if (interval.current) {
        clearInterval(interval.current);
        interval.current = null;
      }
    } else {
      console.log('polling for Frictionless report updates', pollingCount);
      // these are files with remaining checks
      const toCheck = chosenFiles.filter((f) => (f?.id && f?.status === 'Uploaded' && f?.tabularCheckStatus === TabularCheckStatus.checking));

      if (checkPollingDone(toCheck)) return;

      axios.get(
        `/stash/generic_file/check_frictionless/${resource_id}`,
        {params: {file_ids: toCheck.map((file) => file.id)}},
      ).then((response) => {
        const transformed = transformData(response.data);
        const files = simpleTabularCheckStatus(transformed);
        updateAlreadyChosenById(files);
      }).catch((error) => console.log(error));
    }
  }, [pollingCount]);

  // this is a tick for polling of frictionless reports had results put into database
  const tick = () => {
    setPollingCount((p) => p + 1);
  };

  useEffect(() => {
    if (validating.length) {
      // sets file object to have tabularCheckStatus: TabularCheckStatus['checking']} || n/a or status based on report
      const files = updateTabularCheckStatus(validating);
      // I think these are files that are being uploaded now????  IDK what it means.
      updateAlreadyChosenById(files);
      // post to the method to trigger frictionless validation in AWS Lambda
      axios.post(
        `/stash/generic_file/trigger_frictionless/${resource_id}`,
        {file_ids: files.map((file) => file.id)},
      ).then(() => {
        if (!interval.current) {
          // start polling for report updates if not polling already
          interval.current = setInterval(tick, pollingDelay);
        }
      }).catch((error) => console.log(error));
    }
  }, [validating]);

  const setWarningRepeatedFile = (countRepeated) => {
    if (countRepeated < 0) return;
    if (countRepeated === 0) setWarning(null);
    if (countRepeated === 1) setWarning(Messages.fileAlreadySelected);
    if (countRepeated > 1) setWarning(Messages.filesAlreadySelected);
  };

  const discardAlreadyChosenById = (files) => {
    const idsAlready = chosenFiles.map((file) => file.id);
    return files.filter((file) => !idsAlready.includes(file.id));
  };

  const discardAlreadyChosenByName = (filenames, uploadType) => {
    const filesAlreadySelected = chosenFiles.filter((file) => file.uploadType === uploadType
      || (file.uploadType === 'data' && file.sanitized_name.toLowerCase() === 'readme.md'));
    if (!filesAlreadySelected.length) return filenames;

    const filenamesAlreadySelected = filesAlreadySelected.map((file) => file.sanitized_name.toLowerCase());

    return filenames.filter((filename) => !filenamesAlreadySelected.includes(sanitize(filename).toLowerCase())
      && sanitize(filename).toLowerCase() !== 'readme.md');
  };

  const discardFilesAlreadyChosen = (files, uploadType) => {
    const filenames = files.map((file) => file.name);
    const newFilenames = discardAlreadyChosenByName(filenames, uploadType);
    if (filenames.length === newFilenames.length) return files;

    const newFiles = files.filter((file) => newFilenames.includes(file.name));

    const countRepeated = files.length - newFiles.length;
    if (filenames.includes('README.md')) {
      setWarning(Messages.fileReadme);
    } else {
      setWarningRepeatedFile(countRepeated);
    }
    return newFiles;
  };

  const discardUrlsAlreadyChosen = (uris, uploadType) => {
    const handleUrls = uris.split('\n').filter((url) => url);

    const filenames = handleUrls.map((url) => url.split('/').pop());
    const newFilenames = discardAlreadyChosenByName(filenames, uploadType);
    if (filenames.length === newFilenames.length) return handleUrls.join('\n');

    const newUrls = handleUrls.filter((url) => newFilenames.some((filename) => url.includes(filename)));

    const countRepeated = handleUrls.length - newUrls.length;
    setWarningRepeatedFile(countRepeated);
    return newUrls.join('\n');
  };

  const updateFileList = (files) => {
    labelNonTabular(files);
    setChosenFiles((c) => [...c, ...files]);
  };

  const addFilesHandler = (event, uploadType) => {
    displayAriaMsg('Your files are being checked');
    setWarning(null);
    setSubmitDisabled(true);
    const files = discardFilesAlreadyChosen([...event.target.files], uploadType);
    const fileCount = chosenFiles.length + files.length;
    if (fileCount > maxFiles) {
      setWarning(Messages.tooManyFiles);
    } else {
      displayAriaMsg('Your files were added and are pending upload.');
      // TODO: make a function?; future: unify adding file attributes
      const newFiles = files.map((file, index) => {
        file.id = `pending${chosenFiles.length + index}`;
        file.sanitized_name = sanitize(file.name);
        file.status = 'Pending';
        file.url = null;
        file.uploadType = uploadType;
        file.manifest = false;
        file.upload_file_size = file.size;
        file.sizeKb = formatSizeUnits(file.size);
        return file;
      });
      updateFileList(newFiles);
    }
  };

  const uploadFileToS3 = (evaporate) => {
    chosenFiles.map((file, index) => {
      if (file.status === 'Pending') {
        // TODO: Certify if file.uploadType has an entry in AllowedUploadFileTypes
        const evaporateUrl = `${s3_dir_name}/${AllowedUploadFileTypes[file.uploadType]}/${file.sanitized_name}`;
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
              `/stash/${file.uploadType}_file/upload_complete/${resource_id}`,
              {
                resource_id,
                name: file.sanitized_name,
                size: file.size,
                type: file.type,
                original: file.name,
              },
            ).then((response) => {
              const {new_file} = response.data;
              setChosenFiles((cf) => cf.map((c, i) => {
                if (i === index) {
                  c.id = new_file.id;
                  c.sanitized_name = new_file.upload_file_name;
                  c.status = 'Uploaded';
                }
                return c;
              }));
              displayAriaMsg(`${file.original_filename} finished uploading`);
              if (isValidTabular(chosenFiles[index])) {
                setValidating((v) => [...v, chosenFiles[index]]);
              }
            }).catch((error) => console.log(error));
          },
        };
        // Before start uploading, change file status cell to a progress bar
        changeStatusToProgressBar(file.id);

        const signerUrl = `/stash/${file.uploadType}_file/presign_upload/${resource_id}`;
        evaporate.add(addConfig, {signerUrl})
          .then(
            (awsObjectKey) => console.log('File successfully uploaded to: ', awsObjectKey),
            (reason) => console.log('File did not upload successfully: ', reason),
          );
      }
      return true;
    });
  };

  const uploadFilesHandler = () => {
    const {key, bucket, region} = app_config_s3.table;
    const config = {
      aws_key: key,
      bucket,
      awsRegion: region,
      // Assign any first signerUrl, but it changes for each upload file type
      // when call evaporate object add method bellow
      signerUrl: `/stash/generic_file/presign_upload/${resource_id}`,
      awsSignatureVersion: '4',
      computeContentMd5: true,
      cryptoMd5Method: (data) => AWS.util.crypto.md5(data, 'base64'),
      cryptoHexEncodedHash256: (data) => AWS.util.crypto.sha256(data, 'hex'),
    };
    Evaporate.create(config).then(uploadFileToS3);
  };

  const updateManifestFiles = (files) => {
    if (files.invalid_urls?.length) {
      setFailedUrls((failed) => [...failed, ...files.invalid_urls]);
    }

    if (!files.valid_urls.length) return;
    let successfulUrls = files.valid_urls;
    if (chosenFiles.length) {
      successfulUrls = discardAlreadyChosenById(successfulUrls);
    }
    const newManifestFiles = transformData(successfulUrls);
    updateFileList(newManifestFiles);
    const tabularFiles = newManifestFiles.filter((file) => isValidTabular(file));
    setValidating((v) => [...v, ...tabularFiles]);
  };

  const removeFileHandler = (id) => {
    setWarning(null);
    const file = chosenFiles.find((f) => f.id === id);
    if (file.status !== 'Pending') {
      axios.patch(`/stash/${file.uploadType}_files/${id}/destroy_manifest`)
        .then(() => {
          setChosenFiles((cf) => cf.filter((f) => f.id !== id));
        })
        .catch((error) => console.log(error));
    } else {
      setChosenFiles((cf) => cf.filter((f) => f.id !== id));
    }
    displayAriaMsg(`${file.sanitized_name} removed`);
  };

  const hideModal = (event) => {
    if (modalRef.current && (event.type === 'submit' || event.type === 'click'
            || (event.type === 'keydown' && event.keyCode === 27))) {
      modalRef.current.close();
      setManFileType(null);
      document.removeEventListener('keydown', hideModal);
    }
  };

  const showModalHandler = (uploadType) => {
    setManFileType(uploadType);
    modalRef.current.showModal();
    document.addEventListener('keydown', hideModal);
  };

  useEffect(() => {
    if (valFile) {
      modalValidationRef.current.showModal();
    }
  }, [valFile]);

  const hideValidationReport = () => {
    modalValidationRef.current.close();
    setValFile(null);
  };

  const submitUrlsHandler = (event) => {
    setWarning(null);
    event.preventDefault();
    hideModal(event);

    if (!urls) return;

    const urlsObject = {url: discardUrlsAlreadyChosen(urls, manFileType)};

    if (urlsObject.url.length) {
      setLoading(true);
      const typeFilePartialRoute = `${manFileType}_file`;
      axios.post(`/stash/${typeFilePartialRoute}/validate_urls/${resource_id}`, urlsObject)
        .then((response) => {
          updateManifestFiles(response.data);
        })
        .catch((error) => console.log(error));
    }
  };

  const removeFailedUrlHandler = (index) => {
    setFailedUrls((failed) => failed.filter((url, urlIndex) => urlIndex !== index));
  };

  // checks the file list if any files are pending and if so returns true (or false)
  const hasPendingFiles = () => chosenFiles.filter((file) => file.status === 'Pending').length > 0;

  return (
    <div className="c-upload">
      <div className="c-autosave-header">
        <h1 className="o-heading__level1">Upload your files</h1>
        <div className="c-autosave__text saving_text" hidden>Saving&hellip;</div>
        <div className="c-autosave__text saved_text" hidden>All progress saved</div>
      </div>
      <UploadSelect changed={addFilesHandler} clickedModal={showModalHandler} />
      {failedUrls.length > 0 && <FailedUrlList failedUrls={failedUrls} clicked={removeFailedUrlHandler} />}
      {chosenFiles.length > 0 ? (
        <div>
          <FileList
            chosenFiles={chosenFiles}
            clickedRemove={removeFileHandler}
            clickedValidationReport={(file) => setValFile(file)}
            totalSize={formatSizeUnits(chosenFiles.reduce((s, f) => s + f.upload_file_size, 0) + readme_size)}
            readmeSize={formatSizeUnits(readme_size)}
          />
          {loading && (
            <div className="c-upload__loading-spinner">
              <img className="c-upload__spinner" src="../../../images/spinner.gif" alt="Loading spinner" />
            </div>
          )}
          {warning && <WarningMessage message={warning} />}
          {hasPendingFiles() && (
            <ValidateFiles
              id="confirm_to_validate_files"
              buttonLabel="Upload pending files"
              checkConfirmed
              disabled={submitDisabled}
              changed={(e) => setSubmitDisabled(!e.target.checked)}
              clicked={uploadFilesHandler}
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
      {(previous_version && chosenFiles.some((f) => f.status !== 'Pending' && f.file_state !== 'copied')) && (
        <TrackChanges id={resource_id} file_note={file_note} />
      )}
      <ModalUrl
        ref={modalRef}
        submitted={submitUrlsHandler}
        changedUrls={(e) => setUrls(e.target.value)}
        clickedClose={hideModal}
      />
      <ModalValidationReport
        file={valFile}
        ref={modalValidationRef}
        clickedClose={hideValidationReport}
      />
    </div>
  );
}
