import React, {useState, useRef, useEffect} from 'react';
import {Form, Formik} from 'formik';
import moment from 'moment';
import {isEqual} from 'lodash';
import {showSavingMsg, showSavedMsg} from '../../../lib/utils';

export default function Cedar({resource, appConfig}) {
  const [template, setTemplate] = useState(null);
  const [csrf, setCsrf] = useState(null);
  const [metadata, setMetadata] = useState(null);
  const [currMeta, setCurrMetta] = useState(null);
  const [updated, setUpdated] = useState(undefined);

  const formRef = useRef(null);

  let del = null;
  let dialog = null;
  let editor = null;
  let popupWatcher = null;
  let formObserver = null;
  let editorLoaded = null;

  useEffect(() => {
    setCsrf(document.querySelector("meta[name='csrf-token']")?.getAttribute('content'));
    const json = resource.cedar_json ? JSON.parse(resource.cedar_json) : {};
    if (json.template) {
      setTemplate(json.template);
      setMetadata(json.metadata);
      setUpdated(json.updated);
    }
    return () => {
      if (popupWatcher) {
        popupWatcher.disconnect();
        popupWatcher = null;
      }
      if (formObserver) {
        formObserver.disconnect();
        formObserver = null;
      }
      if (editorLoaded) {
        editorLoaded.disconnect();
        editorLoaded = null;
      }
    };
  }, []);

  // Save & set saved content
  useEffect(() => {
    if (!isEqual(currMeta, metadata)) {
      const time = new Date().toISOString();
      const {id: resource_id} = resource;
      const info = {
        template, resource_id, csrf, updated: time,
      };
      const wrappedMeta = {info, metadata: currMeta};
      const xhr = new XMLHttpRequest();
      xhr.open('POST', '/cedar-save');
      xhr.setRequestHeader('Accept', 'application/json');
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify(wrappedMeta, null, 2));
      setUpdated(time);
      setMetadata(currMeta);
      if (editor) editor.templateInfo = info;
    }
    showSavedMsg();
  }, [currMeta]);

  // Save form content when changed
  const checkSave = () => {
    const currentMetadata = JSON.parse(JSON.stringify(editor.currentMetadata));
    if (!isEqual(currentMetadata, currMeta)) {
      setCurrMetta(currentMetadata);
    }
  };

  const setRef = (el) => {
    if (el?.id === 'cedarDialog') {
      dialog = el;

      // Move the cdk-overlay-container into the modal for rendering above dialog
      popupWatcher = new MutationObserver(() => {
        const popups = document.querySelector('body > .cdk-overlay-container');
        if (popups) dialog.append(popups);
      });

      // Check form content when touched
      formObserver = new MutationObserver((changes) => {
        changes.forEach((change) => {
          const {target: {classList}} = change;
          if (classList.contains('ng-touched')) checkSave();
        });
      });

      popupWatcher.observe(document.body, {childList: true});
      formObserver.observe(dialog, {subtree: true, attributeFilter: ['class']});
    }
    if (el?.id === 'deleteCedarDialog') del = el;
    if (el?.id === 'cedarEditor') editor = el;
  };

  const deleteContent = () => {
    setTemplate(null);
    setCurrMetta(null);
  };

  const modalSetup = () => {
    const {id: resource_id} = resource;
    editor.loadConfigFromURL(`/cedar-config?template=${template.id}`);
    editor.templateInfo = {
      template, resource_id, csrf, updated,
    };
    editor.dataset.template = template.id;
    // restore metadata
    editorLoaded = new MutationObserver(() => {
      const app = document.querySelector('app-cedar-embeddable-metadata-editor');
      if (app && !!metadata) {
        editor.metadata = metadata;
        editorLoaded.disconnect();
        editorLoaded = null;
      }
    });
    editorLoaded.observe(editor, {childList: true});
  };

  const openModal = () => {
    showSavingMsg();
    if (!template && !template.id) {
      console.log('Cannot open modal unless a template is selected.');
      return;
    }
    if (dialog?.dataset.template !== template.id) {
      const {table: {editor_url}} = appConfig;
      if (editor_url) {
        const script = document.createElement('script');
        script.src = editor_url;
        script.async = true;
        script.onload = () => modalSetup();
        dialog.appendChild(script);
        dialog.dataset.template = template.id;
      }
    }
    dialog.showModal();
  };

  if (!appConfig) return null;
  const {table: {templates}} = appConfig;
  if (!templates) return null;
  const {id: resource_id} = resource;

  return (
    <div className="cedar-container">
      <h3 className="cedar-heading__level3">Standardized metadata</h3>
      <p>Fill out a standardized metadata form for your discipline to make your data more useful to others.</p>
      <Formik
        initialValues={{resource_id, authenticity_token: (csrf || '')}}
        innerRef={formRef}
        onSubmit={() => openModal()}
      >
        {(formik) => (
          <Form onSubmit={formik.handleSubmit}>
            {metadata && template ? (
              <div style={{display: 'flex', alignItems: 'center'}}>
                <p style={{padding: '8px', border: 'thin solid #777', backgroundColor: '#fff'}}>
                  <strong>{template.title}</strong><br />
                  {updated && `Last modified ${moment(updated).local().format('H:mmA, MM/DD/YYYY')}`}
                </p>
                <button disabled={!template} type="submit" className="o-button__plain-text2" style={{margin: '0 1rem'}}>
                  Edit form
                </button>
                <button type="button" className="o-button__remove" onClick={() => del.showModal()}>
                  Delete form
                </button>
              </div>
            ) : (
              <>
                <label className="c-input__label" htmlFor={`cedar__${resource_id}`}>Choose a metadata form
                </label>
                <select
                  id={`cedar__${resource_id}`}
                  className="c-input__text"
                  name="cedarTemplate"
                  onChange={(e) => {
                    const t = e.currentTarget;
                    setTemplate(t.value ? {id: t.value, title: t.options[t.selectedIndex].label} : null);
                  }}
                  onBlur={formik.handleBlur}
                >
                  <option key="0" value="" label="- Select one -" />
                  {templates.map((templ) => (<option key={templ[0]} value={templ[0]} label={templ[2]} />))}
                </select>
                <button disabled={!template} type="submit" className="o-button__add">
                  Add Metadata Form
                </button>
              </>
            )}
          </Form>
        )}
      </Formik>
      <dialog className="modalDialog" id="cedarDialog" ref={setRef}>
        <div className="modalClose">
          <button aria-label="Close" type="button" onClick={() => dialog.close()} />
        </div>
        <div className="c-modal-content__cedar">
          <cedar-embeddable-editor id="cedarEditor" ref={setRef} />
        </div>
      </dialog>
      <dialog className="modalDialog" id="deleteCedarDialog" ref={setRef}>
        <div className="modalClose">
          <button aria-label="Close" type="button" onClick={() => del.close()} />
        </div>
        <div className="c-modal-content__normal">
          <h1 className="mat-card-title">Confirm Deletion</h1>
          <p>Are you sure you want to delete this form? All answers will be lost.</p>
          <button
            type="button"
            className="o-button__plain-text2"
            style={{marginRight: '16px'}}
            onClick={() => {
              deleteContent();
              del.close();
            }}
          >
            Delete Form
          </button>
          <button type="button" className="o-button__remove" onClick={() => del.close()}>Cancel</button>
        </div>
      </dialog>
    </div>
  );
}
