/* eslint-disable no-nested-ternary */
import React, {
  useState, useRef, useEffect, useCallback,
} from 'react';
import {Form, Formik} from 'formik';
import moment from 'moment';
import {isEqual} from 'lodash';
import {showSavingMsg, showSavedMsg} from '../../../../lib/utils';

export default function Cedar({
  resource, setResource, editorUrl, templates, singleTemplate = null,
}) {
  const [template, setTemplate] = useState(singleTemplate);
  const [csrf, setCsrf] = useState(null);
  const [metadata, setMetadata] = useState(null);
  const [currMeta, setCurrMeta] = useState(null);
  const [updated, setUpdated] = useState(undefined);

  const formRef = useRef(null);
  const templateRef = useRef(template);
  const del = useRef(null);
  const dialog = useRef(null);
  const editor = useRef(null);
  const popupWatcher = useRef(null);
  const formObserver = useRef(null);
  const editorLoaded = useRef(null);

  const unloadEditor = () => {
    if (editorLoaded.current) {
      editorLoaded.current.disconnect();
      editorLoaded.current = null;
    }
  };

  useEffect(() => {
    setCsrf(document.querySelector("meta[name='csrf-token']")?.getAttribute('content'));
    const json = resource.cedar_json ? JSON.parse(resource.cedar_json) : {};
    if (json.template) {
      setTemplate(json.template);
      setMetadata(json.metadata);
      setUpdated(json.updated);
    }
    return () => {
      if (popupWatcher.current) {
        popupWatcher.current.disconnect();
        popupWatcher.current = null;
      }
      if (formObserver.current) {
        formObserver.current.disconnect();
        formObserver.current = null;
      }
      unloadEditor();
    };
  }, []);

  const getInfo = () => {
    const time = new Date().toISOString();
    const {id: resource_id} = resource;
    const info = {
      template, resource_id, csrf, updated: time,
    };
    return info;
  };

  // Save & set saved content
  useEffect(() => {
    if (currMeta && !isEqual(currMeta, metadata)) {
      showSavingMsg();
      const info = getInfo();
      const wrappedMeta = {info, metadata: currMeta};
      const xhr = new XMLHttpRequest();
      xhr.open('POST', '/cedar-save');
      xhr.setRequestHeader('Accept', 'application/json');
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify(wrappedMeta, null, 2));
      setUpdated(info.updated);
      setMetadata(currMeta);
      setResource((r) => ({...r, cedar_json: JSON.stringify({template, updated: info.updated, metadata: currMeta})}));
      if (editor.current) editor.current.templateInfo = info;
      showSavedMsg();
    }
  }, [currMeta, metadata]);

  useEffect(() => {
    if (!isEqual(template, templateRef.current)) {
      if (template === null) {
        const xhr = new XMLHttpRequest();
        const info = getInfo();
        xhr.open('POST', '/cedar-save');
        xhr.setRequestHeader('Accept', 'application/json');
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.send(JSON.stringify({info, metadata: null}, null, 2));
        setCurrMeta(null);
        setUpdated(null);
        setMetadata(null);
        setResource((r) => ({...r, cedar_json: null}));
        if (singleTemplate) setTemplate(singleTemplate);
      }
    }
    templateRef.current = template;
  }, [template]);

  useEffect(() => {
    if (singleTemplate) setTemplate(singleTemplate);
  }, [singleTemplate]);

  // Save form content when changed
  const checkSave = () => {
    const currentMetadata = JSON.parse(JSON.stringify(editor.current.currentMetadata));
    if (!isEqual(currentMetadata, currMeta)) {
      setCurrMeta(currentMetadata);
    }
  };

  const setRef = useCallback((el) => {
    if (el?.id === 'cedarDialog') {
      dialog.current = el;

      // Move the cdk-overlay-container into the modal for rendering above dialog
      popupWatcher.current = new MutationObserver(() => {
        const popups = document.querySelector('body > .cdk-overlay-container');
        if (popups) dialog.current.append(popups);
      });

      // Check form content when touched
      formObserver.current = new MutationObserver((changes) => {
        changes.forEach((change) => {
          const {target: {classList}} = change;
          if (classList.contains('ng-touched')) checkSave();
        });
      });

      popupWatcher.current.observe(document.body, {childList: true});
      formObserver.current.observe(dialog.current, {subtree: true, attributeFilter: ['class']});
    }
    if (el?.id === 'deleteCedarDialog') del.current = el;
    if (el?.id === 'cedarEditor') editor.current = el;
  }, []);

  const modalSetup = () => {
    const {id: resource_id} = resource;
    editor.current.loadConfigFromURL(`/cedar-config?template=${template.id}`);
    editor.current.templateInfo = {
      template, resource_id, csrf, updated,
    };
    editor.current.dataset.template = template.id;
    // restore metadata
    unloadEditor();
    editorLoaded.current = new MutationObserver(() => {
      const app = document.querySelector('app-cedar-embeddable-metadata-editor');
      if (app && !!metadata) {
        editor.current.instanceObject = metadata;
        unloadEditor();
      }
    });
    editorLoaded.current.observe(editor.current, {childList: true});
  };

  const openModal = () => {
    if (!template && !template.id) {
      console.log('Cannot open modal unless a template is selected.');
      return;
    }
    if (dialog.current?.dataset.template !== template.id) {
      if (editorUrl) {
        if (dialog.current.querySelector('script')) {
          modalSetup();
        } else {
          const script = document.createElement('script');
          script.src = editorUrl;
          script.async = true;
          script.onload = () => modalSetup();
          dialog.current.appendChild(script);
        }
        dialog.current.dataset.template = template.id;
      }
    }
    dialog.current.showModal();
  };

  if (!editorUrl) return null;
  if (!templates) return null;

  const {id: resource_id} = resource;

  return (
    <div className="cedar-container">
      <h3 className="o-heading__level3">Standardized metadata</h3>
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
                <button
                  aria-haspopup="dialog"
                  aria-controls="cedarDialog"
                  disabled={!template}
                  type="submit"
                  className="o-button__plain-text2"
                  style={{margin: '0 1rem'}}
                >
                  Edit form
                </button>
                <button
                  type="button"
                  className="o-button__remove"
                  aria-haspopup="dialog"
                  aria-controls="deleteCedarDialog"
                  onClick={() => del.current.showModal()}
                >
                  Delete form
                </button>
              </div>
            ) : (
              singleTemplate ? (
                <button disabled={!template} type="submit" className="o-button__add">
                  Add metadata form: <strong>{singleTemplate.title}</strong>
                </button>
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
                    {templates.map((templ) => (<option key={templ[0]} value={templ[0]} label={templ[1]} />))}
                  </select>
                  <button disabled={!template} type="submit" className="o-button__add">
                    Add metadata form
                  </button>
                </>
              )
            )}
          </Form>
        )}
      </Formik>
      <dialog className="modalDialog" id="cedarDialog" aria-modal="true" ref={setRef}>
        <div className="modalClose">
          <button aria-label="Close" type="button" onClick={() => dialog.current.close()} />
        </div>
        <div className="c-modal-content__cedar">
          <cedar-embeddable-editor id="cedarEditor" ref={setRef} />
        </div>
      </dialog>
      <dialog
        className="modalDialog"
        id="deleteCedarDialog"
        role="alertdialog"
        aria-labelledby="cedar-alert-title"
        aria-describedby="cedar-alert-desc"
        aria-modal="true"
        ref={setRef}
      >
        <div className="modalClose">
          <button aria-label="Close" type="button" onClick={() => del.current.close()} />
        </div>
        <div className="c-modal-content__normal">
          <h1 id="cedar-alert-title" className="mat-card-title">Confirm Deletion</h1>
          <p id="cedar-alert-desc">Are you sure you want to delete this form? All answers will be lost.</p>
          <button
            type="button"
            className="o-button__plain-text2"
            style={{marginRight: '16px'}}
            onClick={() => {
              setTemplate(null);
              del.current.close();
            }}
          >
            Delete Form
          </button>
          <button type="button" className="o-button__remove" onClick={() => del.current.close()}>Cancel</button>
        </div>
      </dialog>
    </div>
  );
}
