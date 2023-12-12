import React, {
  useRef, useState, useEffect, useCallback,
} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {debounce} from 'lodash';
import MarkdownEditor from '../components/MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../lib/utils';

export default function ReadMe({
  dcsDescription, title, doi, updatePath, fileContent,
}) {
  const editorRef = useRef();
  const [initialValue, setInitialValue] = useState(null);
  const [replaceValue, setReplaceValue] = useState('');

  const saveDescription = (markdown) => {
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const data = {
      authenticity_token,
      description: {
        description: markdown,
        resource_id: dcsDescription.resource_id,
        id: dcsDescription.id,
      },
    };
    showSavingMsg();
    axios.patch(updatePath, data, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
      .then(() => {
        showSavedMsg();
      });
  };

  const checkDescription = useCallback(debounce(saveDescription, 900), []);

  const importFile = (e) => {
    const [file] = e.target.files;
    const reader = new FileReader();
    reader.addEventListener('load', () => {
      const {result} = reader;
      // Set markdown!
      setReplaceValue(result);
    });
    if (file) reader.readAsText(file);
    // allow replacement uploads
    e.target.value = null;
  };

  const fetchTemplate = async () => {
    const response = await fetch('/docs/README.md');
    const text = await response.text();
    const template = text.split('\n').slice(3).join('\n');
    const value = `# ${title}\n\n[${doi}](${doi})\n\n${template}`;
    setInitialValue(value);
  };

  useEffect(() => {
    if (dcsDescription.description) {
      setInitialValue(dcsDescription.description);
    } else if (fileContent) {
      setInitialValue(fileContent);
    } else {
      fetchTemplate();
    }
  }, []);

  return (
    <>
      <div className="c-autosave-header">
        <h1 className="o-heading__level1" style={{marginBottom: '1rem'}} id="readme-label">Prepare README file</h1>
        <div className="c-autosave__text saving_text" hidden>Saving&hellip;</div>
        <div className="c-autosave__text saved_text" hidden>All progress saved</div>
      </div>
      <div className="o-admin-columns">
        <div className="o-admin-left" style={{minWidth: '400px', flexGrow: 2}}>
          <p style={{marginTop: 0}}>
          Your Dryad submission must be accompanied by a README file, to help others use and understand your dataset.
          It should contain the details needed to interpret and reuse your data, including abbreviations and codes,
          file descriptions, and information about any necessary software.
          </p>
          <p>
            {!(dcsDescription.description || fileContent) && 'The editor below is pre-filled with a template for you to replace with your content. '}
            You can copy and paste formatted text into the editor, or enter markdown by clicking the &apos;Markdown&apos; tab.
          </p>
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
            <input
              id="readme_upload"
              className="c-choose__input-file"
              type="file"
              accept="text/x-markdown,text/markdown,.md"
              onChange={importFile}
            />
            <label
              style={{display: 'inline-block'}}
              htmlFor="readme_upload"
              aria-label="Upload README file"
              className="o-button__plain-text2"
            >Import README
            </label>
          </div>
        </div>
      </div>
      {initialValue ? (
        <MarkdownEditor
          ref={editorRef}
          id="readme_editor"
          initialValue={initialValue}
          replaceValue={replaceValue}
          onChange={checkDescription}
        />
      ) : (
        <p style={{display: 'flex', alignItems: 'center'}}>
          <img src="../../../images/spinner.gif" alt="Loading spinner" style={{height: '1.5rem', marginRight: '.5ch'}} />
          Loading README template
        </p>
      )}
    </>
  );
}

ReadMe.propTypes = {
  dcsDescription: PropTypes.object.isRequired,
  updatePath: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  doi: PropTypes.string.isRequired,
  fileContent: PropTypes.string,
};
