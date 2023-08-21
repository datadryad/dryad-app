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

export default function ReadMe({dcsDescription, updatePath, fileContent}) {
  const editorRef = useRef();
  const [initialValue, setInitialValue] = useState(null);
  const [loaded, setLoaded] = useState(false);
  const [status, setStatus] = useState('');

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

  const menuFocus = (e) => {
    setStatus(`${e.currentTarget.getAttribute('aria-label')} selected from formatting menu.
      Use down to expand options. Use left and right to move between menus. Exit menu with tab.`);
  };

  const menuEnter = (e) => {
    switch (e.keyCode) {
    case 37: // left
      if (e.target.previousElementSibling) {
        e.target.setAttribute('tabindex', -1);
        e.target.previousElementSibling.setAttribute('tabindex', 0);
        e.target.previousElementSibling.focus();
      }
      break;
    case 38: // up
      if (e.target.getAttribute('role', 'menuitem')) {
        e.target.setAttribute('tabindex', -1);
        e.target.parentElement.setAttribute('tabindex', 0);
        e.target.parentElement.setAttribute('aria-expanded', false);
        e.target.parentElement.focus();
      }
      break;
    case 39: // right
      if (e.target.nextElementSibling) {
        e.target.setAttribute('tabindex', -1);
        e.target.nextElementSibling.setAttribute('tabindex', 0);
        e.target.nextElementSibling.focus();
      }
      break;
    case 40: // down
      e.target.setAttribute('aria-expanded', true);
      e.target.firstElementChild.setAttribute('tabindex', 0);
      e.target.firstElementChild.focus();
      break;
    default:
    }
  };

  const buttonFocus = (e) => {
    setStatus(`Use enter to engage ${e.currentTarget.getAttribute('aria-label')}.
      Use left and right to move between options. Use up to collapse options. Exit formatting menu with tab.`);
  };

  const tabClick = (e) => {
    if ([49, 13].includes(e.keyCode)) e.currentTarget.click();
  };

  // Improve accessibility
  useEffect(() => {
    if (editorRef.current) {
      const rootEl = editorRef.current.getRootElement();
      rootEl.querySelectorAll('*[contenteditable]').forEach((text) => {
        text.setAttribute('role', 'textbox');
        text.setAttribute('tabindex', 0);
        text.setAttribute('aria-labelledby', 'readme-label');
      });
      const toolbar = rootEl.querySelector('.toastui-editor-toolbar');
      toolbar.setAttribute('role', 'menubar');
      toolbar.setAttribute('aria-label', 'Formatting menu');
      toolbar.setAttribute('aria-describedby', 'menu-status');
      toolbar.querySelectorAll('.toastui-editor-toolbar-group').forEach((menu, i) => {
        const labels = ['Text style', 'Inserts', 'Lists &amp; indents', 'Code &amp; Tables'];
        menu.setAttribute('role', 'menu');
        menu.setAttribute('aria-expanded', 'false');
        menu.setAttribute('aria-label', labels[i]);
        menu.setAttribute('tabindex', i === 0 ? 0 : -1);
        menu.querySelectorAll('button').forEach((button) => {
          button.setAttribute('role', 'menuitem');
          button.setAttribute('tabindex', -1);
          button.addEventListener('focus', buttonFocus);
        });
        menu.addEventListener('focus', menuFocus);
        menu.addEventListener('blur', () => setStatus(''));
        menu.addEventListener('keydown', menuEnter);
      });
      rootEl.querySelectorAll('.toastui-editor-mode-switch .tab-item').forEach((tab) => {
        tab.setAttribute('role', 'button');
        tab.setAttribute('aria-label', `Switch editor to ${tab.innerText} mode`);
        tab.setAttribute('tabindex', tab.classList.contains('active') ? -1 : 0);
        tab.addEventListener('keydown', tabClick);
        tab.addEventListener('click', (e) => {
          const sibling = e.target.nextElementSibling ? e.target.nextElementSibling : e.target.previousElementSibling;
          e.target.setAttribute('tabindex', -1);
          sibling.setAttribute('tabindex', 0);
        });
      });
    }
  }, [loaded]);

  useEffect(async () => {
    if (dcsDescription.description) {
      setInitialValue(dcsDescription.description);
    } else if (fileContent) {
      setInitialValue(fileContent);
    } else {
      const response = await fetch('/docs/README.md');
      const value = await response.text();
      setInitialValue(value);
      setInitialValue(editorRef.current.getInstance().getMarkdown());
    }
  }, [dcsDescription]);

  return (
    <>
      <h1 className="o-heading__level1" style={{marginBottom: '1rem'}} id="readme-label">Prepare README file</h1>
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
        <form id="readme_editor">
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
            onLoad={() => setLoaded(true)}
            onChange={checkDescription}
            onBlur={saveDescription}
          />
        </form>
      ) : (
        <p style={{display: 'flex', alignItems: 'center'}}>
          <img src="../../../images/spinner.gif" alt="Loading spinner" style={{height: '1.5rem', marginRight: '.5ch'}} />
          Loading README template
        </p>
      )}
      <p className="screen-reader-only" role="status" aria-live="polite" id="menu-status">{status}</p>
    </>
  );
}

ReadMe.propTypes = {
  dcsDescription: PropTypes.object.isRequired,
  updatePath: PropTypes.string.isRequired,
  fileContent: PropTypes.string,
};
