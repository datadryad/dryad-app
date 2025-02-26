import React from 'react';
import {Buffer} from 'buffer';
import {isText} from './textorbinary';

export default function ReadMeImport({title, setValue}) {
  const importFile = (e) => {
    const [file] = e.target.files;
    const reader = new FileReader();
    const readerX = new FileReader();
    reader.addEventListener('load', () => {
      const {result} = reader;
      // Test markdown
      const buffer = Buffer.from(new Uint8Array(result));
      if (isText(buffer)) {
        readerX.readAsText(file);
      } else {
        document.getElementById('readme_upload').setAttribute('aria-invalid', true);
        document.getElementById('bad-readme-modal').showModal();
      }
    });
    readerX.addEventListener('load', () => {
      const {result} = readerX;
      // Set markdown
      setValue(result);
    });
    if (file) reader.readAsArrayBuffer(file);
    // allow replacement uploads
    e.target.value = null;
  };

  return (
    <>
      <div style={{textAlign: 'center'}}>
        <input
          id="readme_upload"
          type="file"
          className="screen-reader-only"
          accept="text/x-markdown,text/markdown,.md"
          aria-errormessage="bad-readme-modal"
          aria-invalid="false"
          onChange={importFile}
        />
        <label
          style={{display: 'inline-block'}}
          htmlFor="readme_upload"
          aria-label="Upload README file"
          className="o-button__plain-text1"
        >
          <i className="fa fa-upload" aria-hidden="true" />{' '}{title || 'Import README'}
        </label>
      </div>
      <dialog id="bad-readme-modal" className="modalDialog" aria-modal="true">
        <div className="modalClose">
          <button
            aria-label="Close"
            type="button"
            onClick={() => {
              document.getElementById('bad-readme-modal').close();
              document.getElementById('readme_upload').setAttribute('aria-invalid', false);
            }}
          />
        </div>
        <div>
          <h1>File not accepted</h1>
          <p>Only <a href="https://www.markdownguide.org/">Markdown format</a> README imports are accepted.</p>
          <p>Have a different file type? Try copying and pasting the contents of your file into the editor!</p>
        </div>
      </dialog>
    </>
  );
}
