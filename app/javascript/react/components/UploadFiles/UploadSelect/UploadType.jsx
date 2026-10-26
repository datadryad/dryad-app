import React from 'react';
import License from './License';
import UploadInput from './UploadInput';

export default function UploadType(
  {
    name, description, type, changed, clickedModal, licenses, resource, setResource, current,
  },
) {
  const dragover = (e) => {
    e.preventDefault();
    document.getElementById(`${type}file_drop`).classList.add('dragover');
  };
  const dragleave = () => {
    document.getElementById(`${type}file_drop`).classList.remove('dragover');
  };
  return (
    <div>
      <div id={`${type}file_drop`} className="c-uploadwidget" onDragOver={dragover} onDrop={dragleave} onDragLeave={dragleave}>
        <UploadInput id={type} changed={changed} errorId={`${type}_error`} />
        <h4>
          <img src="../../../images/logo_zenodo.svg" alt="Zenodo" />
          {name}
        </h4>
        <p>{description}</p>
        <label htmlFor={type} aria-label={`upload ${type} files`} className="c-choose__input-file-label">Choose files</label>
        <button
          type="button"
          id={`${type}_manifest`}
          className="js-uploadmodal__button-show-modal"
          onClick={clickedModal}
          aria-haspopup="dialog"
        >
          Enter URLs
        </button>
      </div>
      {licenses.length === 1 ? (
        <p>{name} license: {licenses[0]}</p>
      ) : (
        <License current={current} license={resource.identifier.software_license} resourceId={resource.id} setResource={setResource} />
      )}
    </div>
  );
}
