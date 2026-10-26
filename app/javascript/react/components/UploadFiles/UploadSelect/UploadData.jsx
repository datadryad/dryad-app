import React from 'react';
import UploadInput from './UploadInput';

export default function UploadData({changed, clickedModal}) {
  const dragover = (e) => {
    e.preventDefault();
    document.getElementById('file_drop').classList.add('dragover');
  };
  const dragleave = () => {
    document.getElementById('file_drop').classList.remove('dragover');
  };
  return (
    <div id="file_drop" className="c-uploadwidget" onDragOver={dragover} onDrop={dragleave} onDragLeave={dragleave}>
      <UploadInput id="data" changed={(e) => changed(e, 'data')} errorId="data_error" />
      <h3>Upload files to Dryad</h3>
      <p>Drag and drop your files here, or:</p>
      <label htmlFor="data" aria-label="Upload data files" className="c-choose__input-file-label">Choose files</label>
      <button
        type="button"
        id="data_manifest"
        className="js-uploadmodal__button-show-modal"
        onClick={() => clickedModal('data')}
        aria-haspopup="dialog"
      >
        Enter URLs
      </button>
    </div>
  );
}
