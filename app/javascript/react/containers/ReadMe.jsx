import React, {
  useRef, useState, useEffect, useCallback,
} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {Editor} from '@toast-ui/react-editor';
import {debounce} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../lib/utils';
import subsubPlugin from '../../lib/subsup_plugin';

import '@toast-ui/editor/dist/toastui-editor.css';
import '../../lib/toastui-editor.css';

export default function ReadMe({dcsDescription, updatePath, readmeUrl}) {
  const editorRef = useRef();
  const [initialValue, setInitialValue] = useState(null);

  const saveDescription = () => {
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    if (initialValue !== editorRef.current.getInstance().getMarkdown()) {
      const data = {
        authenticity_token,
        description: {
          description: editorRef.current.getInstance().getMarkdown(),
          resource_id: dcsDescription.resource_id,
          id: dcsDescription.id,
        },
      };
      showSavingMsg();
      axios.patch(updatePath, data, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
        .then(() => {
          showSavedMsg();
        });
    }
  };

  const checkDescription = useCallback(debounce(saveDescription, 4000), []);

  const importFile = (e) => {
    const [file] = e.target.files;
    const reader = new FileReader();
    reader.addEventListener('load', () => {
      const {result} = reader;
      editorRef.current.getInstance().setMarkdown(result);
    });
    if (file) reader.readAsText(file);
    // allow replacement uploads
    e.target.value = null;
  };

  useEffect(async () => {
    if (dcsDescription.description) {
      setInitialValue(dcsDescription.description);
    } else if (readmeUrl) {
      const response = await fetch(readmeUrl);
      const value = await response.text();
      setInitialValue(value);
      setInitialValue(editorRef.current.getInstance().getMarkdown());
    }
  }, [dcsDescription, readmeUrl]);

  return (
    <>
      <h1 className="o-heading__level1" style={{marginBottom: '1rem'}}>Prepare README file</h1>
      <div className="o-admin-columns">
        <div className="o-admin-left" style={{minWidth: '400px', flexGrow: 2}}>
          <p style={{marginTop: 0}}>Your Dryad submission must be accompanied by a README file, to help others use
          and understand your dataset.
          </p>
          <p>Your README should contain the details needed to interpret and reuse your data,
          including abbreviations and codes, file descriptions, and information about any necessary software.
          </p>
          <p>The editor below is pre-filled with a template to help you get started.</p>
          <p style={{textAlign: 'center', marginBottom: 0}}>
            <a href="/stash/best_practices#describe-your-dataset-in-a-readme-file" target="_blank">
              <i className="fa fa-file-text-o" aria-hidden="true" style={{marginRight: '1ch'}} />Learn about README files
              <span className="screen-reader-only"> (opens in new window)</span>
            </a>
          </p>
        </div>
        <div className="o-admin-right cedar-container" style={{minWidth: '400px', flexShrink: 2}}>
          <h2 className="o-heading__level2">Already have a README file?</h2>
          <p>If you already have a README file in <a href="https://www.markdownguide.org/" target="_blank" rel="noreferrer">markdown format<span className="screen-reader-only"> (opens in new window)</span></a> for your dataset, you can import it here.
          This will replace our template in the editor.
          </p>
          <div style={{textAlign: 'center'}}>
            <label
              style={{display: 'inline-block'}}
              htmlFor="readme_upload"
              aria-label="Upload README file"
              className="o-button__plain-text2"
            >Import README
            </label>
            <input
              id="readme_upload"
              className="c-choose__input-file"
              type="file"
              accept="text/x-markdown,text/markdown,.md"
              onChange={importFile}
            />
          </div>
        </div>
      </div>
      {initialValue ? (
        <Editor
          ref={editorRef}
          autofocus={false}
          initialEditType="wysiwyg"
          initialValue={initialValue}
          height="95vh"
          toolbarItems={[
            ['heading', 'bold', 'italic', 'strike'],
            ['hr', 'quote', 'link'],
            ['ul', 'ol', 'indent', 'outdent'],
            ['table', 'code', 'codeblock'],
          ]}
          plugins={[subsubPlugin]}
          useCommandShortcut
          onChange={checkDescription}
          onBlur={saveDescription}
        />
      ) : (
        <p style={{display: 'flex', alignItems: 'center'}}>
          <img src="../../../images/spinner.gif" alt="Loading spinner" style={{height: '1.5rem', marginRight: '.5ch'}} />
          Loading your README file
        </p>
      )}
    </>
  );
}

ReadMe.propTypes = {
  dcsDescription: PropTypes.object.isRequired,
  updatePath: PropTypes.string.isRequired,
  readmeUrl: PropTypes.string.isRequired,
};
