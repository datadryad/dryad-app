import React from 'react';

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
      <input
        id="data"
        type="file"
        onClick={(e) => { e.target.value = null; }}
        onChange={(e) => changed(e, 'data')}
        aria-errormessage="data_error"
        multiple
      />
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
