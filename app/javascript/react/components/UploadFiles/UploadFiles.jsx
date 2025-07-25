import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import Evaporate from 'evaporate';
import {v4 as uuid} from 'uuid';
import AWS from 'aws-sdk';
import sanitize from '../../../lib/sanitize_filename';
import {formatSizeUnits} from '../../../lib/utils';
import {pollingDelay} from './pollingDelay';
import FailedUrlList from './FailedUrlList/FailedUrlList';
import FileList from './FileList/FileList';
import {TabularCheckStatus} from './FileList/File';
import ModalUrl from './ModalUrl';
import ModalValidationReport from './ModalValidationReport/ModalValidationReport';
import UploadData from './UploadSelect/UploadData';
import UploadSelect from './UploadSelect/UploadSelect';
import TrackChanges, {ChangeNote} from './TrackChanges';

/**
 * Constants
 */
const RailsActiveRecordToUploadType = {
  'StashEngine::DataFile': 'data',
  'StashEngine::SoftwareFile': 'software',
  'StashEngine::SuppFile': 'supp',
};
const UploadTypetoRailsActiveRecord = {
  data: 'StashEngine::DataFile',
  software: 'StashEngine::SoftwareFile',
  supp: 'StashEngine::SuppFile',
};
const AllowedUploadFileTypes = {
  data: 'data',
  software: 'sfw',
  supp: 'supp',
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

const transformData = (files) => files.map((file) => ({
  ...file,
  sanitized_name: file.download_filename,
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
  resource, setResource, previous, config_maximums, config_s3, config_payments, s3_dir_name, current,
}) {
  const [chosenFiles, setChosenFiles] = useState([]);
  const [validating, setValidating] = useState([]);
  const [failedUrls, setFailedUrls] = useState([]);
  const [loading, setLoading] = useState(false);
  const [urls, setUrls] = useState(null);
  const [manFileType, setManFileType] = useState(null);
  const [valFile, setValFile] = useState(null);
  const [warning, setWarning] = useState([]);
  const [pollingCount, setPollingCount] = useState(0);
  const [zenodo, setZenodo] = useState(false);

  const uploadRef = useRef(null);
  const modalRef = useRef(null);
  const modalValidationRef = useRef(null);
  const interval = useRef(null);

  const {files: maxFiles, merritt_size, upload_size} = config_maximums;
  const maxSize = resource.identifier.new_upload_size_limit ? upload_size : merritt_size;
  const Messages = {
    fileReadme: 'Please prepare your README on the README page.',
    fileAlreadySelected: 'A file of the same name is already in the table. The new file was not added.',
    filesAlreadySelected: 'Files of the same name are already in the table. New files were not added.',
    tooManyFiles: `You may not upload more than ${maxFiles} individual files of this type.`,
    filesTooBig: `You may not submit more than ${formatSizeUnits(maxSize)} of files.`,
    zeroSize: 'Zenodo does not accept files without content (0 B files)',
    // eslint-disable-next-line max-len
    rarTypeFiles: 'RAR files were not added. RAR is a proprietary compression format that cannot be opened universally. Please use an open-access format, such as TAR.GZ, 7Z, or ZIP.',
  };

  const changes = previous && chosenFiles.some((f) => f.uploadType === 'data' && f.status !== 'Pending' && f.file_state !== 'copied');
  const publishedChanges = resource.identifier.pub_state === 'published'
    && (changes || resource.descriptions?.find((d) => d.description_type === 'changelog'));

  const isValidTabular = (file) => (ValidTabular.extensions.includes(file.sanitized_name.split('.').pop())
            || ValidTabular.mime_types.includes(file.upload_content_type))
            && (file.upload_file_size <= config_maximums.frictionless);

  const labelNonTabular = (files) => files.map((file) => {
    file.tabularCheckStatus = isValidTabular(file) ? null : TabularCheckStatus.na;
    return file;
  });

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
      return files.reduce((arr, file) => {
        const cf = chosenFiles.find((c) => c.id === file.id);
        if (!cf.tabularCheckStatus) arr.push({...file, tabularCheckStatus: TabularCheckStatus.checking});
        return arr;
      }, []);
    }
    return simpleTabularCheckStatus(files);
  };

  useEffect(() => {
    if (chosenFiles.some((f) => f.uploadType !== 'data')) setZenodo(true);
    chosenFiles.forEach((f) => {
      if (f.status === 'Uploaded' && f.tabularCheckStatus === null) setValidating((v) => [...v, f]);
    });
    const generic_files = chosenFiles.map((f) => ({
      ...f,
      download_filename: f.sanitized_name,
      type: UploadTypetoRailsActiveRecord[f.uploadType],
    }));
    setResource((r) => ({...r, total_file_size: generic_files.reduce((s, f) => s + f.upload_file_size, 0), generic_files}));
  }, [chosenFiles]);

  useEffect(() => {
    const files = resource.generic_files;
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
        `/generic_file/check_frictionless/${resource.id}`,
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
        `/generic_file/trigger_frictionless/${resource.id}`,
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
    if (countRepeated === 0) return;
    if (countRepeated === 1) setWarning([Messages.fileAlreadySelected]);
    if (countRepeated > 1) setWarning([Messages.filesAlreadySelected]);
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

  const discardUnwantedFiles = (files, uploadType) => {
    const rarfile = (f) => f.type === 'application/vnd.rar' || f.name.endsWith('.rar');
    const zerofile = (f) => uploadType !== 'data' && !f.size;
    if (files.some((f) => rarfile(f))) {
      setWarning((w) => [...w, Messages.rarTypeFiles]);
    }
    if (files.some((f) => zerofile(f))) {
      setWarning((w) => [...w, Messages.zeroSize]);
    }
    return files.filter((f) => !rarfile(f) && !zerofile(f));
  };

  const discardFiles = (files, uploadType) => {
    setWarning([]);
    let newFiles = files;
    const filenames = files.map((file) => file.name);
    const newFilenames = discardAlreadyChosenByName(filenames, uploadType);
    if (filenames.length !== newFilenames.length) {
      newFiles = files.filter((file) => newFilenames.includes(file.name));
      const countRepeated = files.length - newFiles.length;
      setWarningRepeatedFile(countRepeated);
      if (filenames.includes('README.md')) setWarning((w) => [...w, Messages.fileReadme]);
    }
    newFiles = discardUnwantedFiles(newFiles, uploadType);
    return newFiles;
  };

  const discardUrls = (uris, uploadType) => {
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
    const labeled = labelNonTabular(files);
    setChosenFiles((c) => [...c, ...labeled]);
  };

  const uploadFileToS3 = (evaporate, fileList) => {
    fileList.map((file) => {
      if (file.status === 'Pending') {
        // TODO: Certify if file.uploadType has an entry in AllowedUploadFileTypes
        const evaporateUrl = `${s3_dir_name}/${AllowedUploadFileTypes[file.uploadType]}/${file.uuid}`;
        const addConfig = {
          name: evaporateUrl,
          file,
          xAmzHeadersAtInitiate: {
            'x-amz-storage-class': 'INTELLIGENT_TIERING',
          },
          contentType: file.type,
          progress: (progressValue) => {
            document.getElementById(
              `progressbar_${file.id}`,
            )?.setAttribute('value', progressValue);
          },
          error(msg) {
            console.log(msg);
          },
          complete: () => {
            axios.post(
              `/${file.uploadType}_file/upload_complete/${resource.id}`,
              {
                resource_id: resource.id,
                uuid: file.uuid,
                name: file.sanitized_name,
                size: file.size,
                type: file.type,
                original: file.name,
              },
            ).then((response) => {
              const {new_file} = response.data;
              setChosenFiles((cf) => cf.map((c) => {
                if (c.sanitized_name === new_file.download_filename
                  && UploadTypetoRailsActiveRecord[c.uploadType] === new_file.type) {
                  c.id = new_file.id;
                  c.status = 'Uploaded';
                  c.uploaded = new_file.uploaded;
                  c.file_state = new_file.file_state;
                  c.upload_file_name = new_file.upload_file_name;
                  c.download_filename = new_file.download_filename;
                }
                return c;
              }));
              displayAriaMsg(`${new_file.original_filename} finished uploading`);
            }).catch((error) => console.log(error));
          },
        };
        // Before start uploading, change file status cell to a progress bar
        changeStatusToProgressBar(file.id);

        const signerUrl = `/${file.uploadType}_file/presign_upload/${resource.id}`;
        evaporate.add(addConfig, {signerUrl})
          .then(
            (awsObjectKey) => console.log('File successfully uploaded to: ', awsObjectKey),
            (reason) => console.log('File did not upload successfully: ', reason),
          );
      }
      return true;
    });
  };

  const addFilesHandler = (event, uploadType) => {
    const timestamp = Date.now();
    displayAriaMsg('Your files are being checked');
    setWarning([]);
    const files = discardFiles([...event.target.files], uploadType);
    const fileCount = chosenFiles.filter((f) => f.uploadType === uploadType).length + files.length;
    if (chosenFiles.reduce((a, c) => a + c.upload_file_size, 0) + files.reduce((a, c) => a + c.size, 0) > maxSize) {
      setWarning([...warning, Messages.filesTooBig]);
    }
    if (fileCount > maxFiles) {
      setWarning([...warning, Messages.tooManyFiles]);
    } else {
      displayAriaMsg('Your files were added and are being uploaded.');
      // TODO: make a function?; future: unify adding file attributes
      const newFiles = files.map((file, index) => {
        file.id = `pending${timestamp + index / 1000}`;
        file.uuid = `${uuid()}.${file.name.split('.').pop()}`;
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
      const {key, bucket, region} = config_s3.table;
      // AWS transfers allow up to 10,000 parts per multipart upload, with a minimum of 5MB per part.
      let partSize = 5 * 1024 * 1024;
      const maxFSize = newFiles.reduce((p, c) => (p > c.size ? p : c.size), 0);
      if (maxFSize > 10000000000) partSize = 10 * 1024 * 1024;
      if (maxFSize > 100000000000) partSize = 30 * 1024 * 1024;
      if (maxFSize > 300000000000) partSize = 250 * 1024 * 1024;
      const config = {
        aws_key: key,
        bucket,
        awsRegion: region,
        // Assign any first signerUrl, but it changes for each upload file type
        // when call evaporate object add method bellow
        signerUrl: `/generic_file/presign_upload/${resource.id}`,
        awsSignatureVersion: '4',
        computeContentMd5: true,
        cryptoMd5Method: (data) => AWS.util.crypto.md5(data, 'base64'),
        cryptoHexEncodedHash256: (data) => AWS.util.crypto.sha256(data, 'hex'),
        partSize,
        maxConcurrentParts: 50,
      };
      Evaporate.create(config).then((ev) => uploadFileToS3(ev, newFiles));
    }
  };

  const updateManifestFiles = (files) => {
    if (files.invalid_urls?.length) {
      setFailedUrls((failed) => [...failed, ...files.invalid_urls]);
    }

    if (!files.valid_urls.length) return;
    let successfulUrls = files.valid_urls.map((f) => {
      f.uploaded = true;
      return f;
    });
    if (chosenFiles.length) {
      successfulUrls = discardAlreadyChosenById(successfulUrls);
    }
    const newManifestFiles = transformData(successfulUrls);
    updateFileList(newManifestFiles);
    const tabularFiles = newManifestFiles.filter((file) => isValidTabular(file));
    setValidating((v) => [...v, ...tabularFiles]);
  };

  const removeFileHandler = (id) => {
    setWarning([]);
    const file = chosenFiles.find((f) => f.id === id);
    if (file.status !== 'Pending') {
      axios.patch(`/${file.uploadType}_files/${id}/destroy_manifest`)
        .then(() => {
          setChosenFiles((cf) => cf.filter((f) => f.id !== id));
        })
        .catch((error) => console.log(error));
    } else {
      setChosenFiles((cf) => cf.filter((f) => f.id !== id));
    }
    displayAriaMsg(`${file.sanitized_name} removed`);
  };

  const renameFileHandler = (id, newname) => {
    setWarning([]);
    const file = chosenFiles.find((f) => f.id === id);
    const newfilename = sanitize(newname);
    if (file.status !== 'Pending') {
      axios.patch(`/${file.uploadType}_files/${id}/rename`, {resource_id: resource.id, newfilename})
        .then((data) => {
          if (data.data.error) {
            setWarning([data.data.error]);
          } else {
            const transformed = transformData([data.data]);
            setChosenFiles((cf) => cf.map((f) => (f.id === id ? transformed[0] : f)));
          }
        });
    }
    // displayAriaMsg(`${}`);
  };

  const hideModal = (event) => {
    if (modalRef.current && (event.type === 'submit' || event.type === 'click'
            || (event.type === 'keydown' && event.keyCode === 27))) {
      modalRef.current.close();
      setManFileType(null);
      document.removeEventListener('keydown', hideModal);
    }
  };

  useEffect(() => {
    if (manFileType) {
      modalRef.current.showModal();
      document.addEventListener('keydown', hideModal);
    }
  }, [manFileType]);

  const showModalHandler = (uploadType) => {
    setManFileType(uploadType);
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
    setWarning([]);
    event.preventDefault();
    hideModal(event);

    if (!urls) return;

    const urlsObject = {url: discardUrls(urls, manFileType)};

    if (urlsObject.url.length) {
      setLoading(true);
      const typeFilePartialRoute = `${manFileType}_file`;
      axios.post(`/${typeFilePartialRoute}/validate_urls/${resource.id}`, urlsObject)
        .then((response) => {
          updateManifestFiles(response.data);
          setLoading(false);
        })
        .catch((error) => console.log(error));
    }
  };

  const removeFailedUrlHandler = (index) => {
    setFailedUrls((failed) => failed.filter((url, urlIndex) => urlIndex !== index));
  };

  useEffect(() => {
    if (uploadRef.current) {
      const observer = new MutationObserver(() => {
        const pending = document.querySelector('*[id^="status_pending"]');
        const progress = document.querySelector('progress');
        if (!!pending || !!progress) {
          document.body.style.pointerEvents = 'none';
          uploadRef.current.style.pointerEvents = 'auto';
          document.getElementById('leave-warning').removeAttribute('hidden');
          document.getElementById('submission-help')?.querySelectorAll('button').forEach((b) => {
            b.setAttribute('disabled', 'true');
          });
        } else {
          document.body.style.pointerEvents = 'auto';
          document.getElementById('leave-warning').setAttribute('hidden', true);
          document.getElementById('submission-help')?.querySelectorAll('button').forEach((b) => {
            b.removeAttribute('disabled');
          });
        }
      });
      observer.observe(uploadRef.current, {subtree: true, childList: true});
    }
  }, [uploadRef.current]);

  return (
    <div ref={uploadRef}>
      <UploadData changed={addFilesHandler} clickedModal={showModalHandler} />
      <p style={{fontSize: '.98rem'}}>
        By uploading files to Dryad, you agree they will be licensed as{' '}
        <a href="https://creativecommons.org/publicdomain/zero/1.0/" target="_blank" rel="noreferrer">
          Public domain
          <span role="img" aria-label="CC0 (opens in new window)" style={{marginLeft: '.25ch'}}>
            <i className="fab fa-creative-commons" aria-hidden="true" />
            <i className="fab fa-creative-commons-zero" aria-hidden="true" />
          </span>
        </a>
      </p>
      <p style={{fontSize: '.98rem'}} hidden={zenodo}>
        Do you have files that require other licensing?{' '}
        <span
          className="o-link__primary"
          role="button"
          aria-expanded={zenodo}
          aria-controls="zenodo-widget"
          tabIndex="0"
          onClick={() => setZenodo(true)}
          onKeyDown={(e) => {
            if (['Enter', 'Space'].includes(e.key)) {
              setZenodo(true);
            }
          }}
        >
          + Add files for simultaneous publication at Zenodo
        </span>
      </p>
      <div id="zenodo-widget" hidden={!zenodo}>
        <p style={{fontSize: '.98rem'}}>
          Files that require other licensing can be published at Zenodo.
          The license for software (e.g. &apos;MIT&apos;, &apos;GNU&apos;) can be specified.
          <span
            className="o-link__primary"
            role="button"
            aria-expanded={zenodo}
            aria-controls="zenodo-widget"
            style={{marginLeft: '1ch'}}
            tabIndex="0"
            onClick={() => setZenodo(false)}
            onKeyDown={(e) => {
              if (['Enter', 'Space'].includes(e.key)) {
                setZenodo(false);
              }
            }}
          ><i className="fas fa-caret-up" aria-hidden="true" style={{marginRight: '.5ch'}} />Close
          </span>
        </p>
        <UploadSelect current={current} resource={resource} setResource={setResource} changed={addFilesHandler} clickedModal={showModalHandler} />
      </div>
      {failedUrls.length > 0 && <FailedUrlList failedUrls={failedUrls} clicked={removeFailedUrlHandler} />}
      <div role="alert">
        {warning.map((w) => <div className="callout warn" key={w}><p>{w}</p></div>)}
      </div>
      {chosenFiles.length > 0 ? (
        <>
          <FileList
            config={config_payments}
            chosenFiles={chosenFiles}
            renameFile={renameFileHandler}
            clickedRemove={removeFileHandler}
            clickedValidationReport={(file) => setValFile(file)}
            totalSize={chosenFiles.reduce((s, f) => s + f.upload_file_size, 0)}
          />
          {loading && (
            <p><i className="fas fa-spin fa-spinner" role="img" aria-label="Loading" /></p>
          )}
        </>
      ) : (
        <div>
          {loading ? (
            <p><i className="fas fa-spin fa-spinner" role="img" aria-label="Loading" /></p>
          ) : <div className="callout"><p>No files have been selected.</p></div> }
        </div>
      )}
      {publishedChanges && <TrackChanges resource={resource} setResource={setResource} />}
      {changes && !publishedChanges && <ChangeNote resource={resource} /> }
      <ModalUrl
        ref={modalRef}
        key={manFileType}
        submitted={submitUrlsHandler}
        changedUrls={(e) => setUrls(e.target.value)}
        clickedClose={hideModal}
      />
      <ModalValidationReport
        file={valFile}
        ref={modalValidationRef}
        clickedClose={hideValidationReport}
      />
      <div id="aria-info" className="screen-reader-only" aria-live="polite" aria-atomic="true" aria-relevant="additions text" />
      <div className="callout warn" role="status">
        <p id="leave-warning" hidden>
          <i className="fas fa-hourglass-start" aria-hidden="true" />
          Wait for file uploads to complete before leaving this page
        </p>
      </div>
    </div>
  );
}
