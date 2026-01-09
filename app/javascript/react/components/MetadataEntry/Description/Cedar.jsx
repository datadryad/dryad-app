/* eslint-disable no-nested-ternary */
import React, {
  useState, useRef, useEffect, useCallback,
} from 'react';
import moment from 'moment';
import axios from 'axios';
import {isEqual} from 'lodash';
import {ExitIcon} from '../../ExitButton';
import {showSavingMsg, showSavedMsg} from '../../../../lib/utils';

export default function Cedar({resource, setResource, templates}) {
  const [template, setTemplate] = useState(null);
  const [metadata, setMetadata] = useState(null);
  const [currMeta, setCurrMeta] = useState(null);

  const templateRef = useRef(template);
  const del = useRef(null);
  const dialog = useRef(null);
  const editor = useRef(null);
  const popupWatcher = useRef(null);
  const formObserver = useRef(null);
  const editorLoaded = useRef(null);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const unloadEditor = () => {
    if (editorLoaded.current) {
      editorLoaded.current.disconnect();
      editorLoaded.current = null;
    }
  };

  useEffect(() => {
    const json = resource.cedar_json || {};
    if (json.json) {
      setTemplate(templates.find((t) => t.id === json.template_id));
      setMetadata(json.json);
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

  // Save & set saved content
  useEffect(() => {
    if (currMeta && !isEqual(currMeta, metadata)) {
      showSavingMsg();
      const saveJson = {authenticity_token, template_id: template.id, json: JSON.stringify(currMeta)};
      axios.post(
        `/cedar/save/${resource.id}`,
        saveJson,
        {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
      ).then((data) => {
        setMetadata(currMeta);
        setResource((r) => ({...r, cedar_json: data.data}));
      });
      showSavedMsg();
    }
  }, [currMeta, metadata]);

  useEffect(() => {
    if (!isEqual(template, templateRef.current)) {
      if (template === null) {
        axios.delete(
          `/cedar/save/${resource.id}`,
          {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
        ).then(() => {
          setMetadata(null);
          setResource((r) => ({...r, cedar_json: null}));
        });
        if (templates.length === 1) setTemplate(templates[0]);
      }
    }
    templateRef.current = template;
  }, [template]);

  useEffect(() => {
    if (templates.length === 1) setTemplate(templates[0]);
  }, [templates]);

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
    editor.current.loadConfigFromURL(`/cedar/config?template=${template.id}`);
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
      if (dialog.current.querySelector('script')) {
        modalSetup();
      } else {
        const script = document.createElement('script');
        script.src = '/cedar-embeddable-editor/cedar-embeddable-editor.js?1-5-0';
        script.async = true;
        script.onload = () => modalSetup();
        dialog.current.appendChild(script);
      }
      dialog.current.dataset.template = template.id;
    }
    dialog.current.showModal();
  };

  if (!templates) return null;

  const {id: resource_id} = resource;

  return (
    <div className="cedar-container">
      <h3 className="o-heading__level3">Standardized metadata</h3>
      <p>Fill out a <a href="https://metadatacenter.org/" target="_blank" rel="noreferrer">standardized metadata form<ExitIcon /></a> for your discipline to make your data more useful to others.</p>
      <div>
        {metadata && template ? (
          <div style={{display: 'flex', alignItems: 'center'}}>
            <p style={{padding: '8px', border: 'thin solid #777', backgroundColor: '#fff'}}>
              <strong>{template.title}</strong><br />
              {resource.cedar_json.updated_at && `Last modified ${moment(resource.cedar_json.updated_at).local().format('H:mmA, MM/DD/YYYY')}`}
            </p>
            <button
              aria-haspopup="dialog"
              aria-controls="cedarDialog"
              disabled={!template}
              type="button"
              onClick={() => openModal()}
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
          templates.length === 1
            ? template && (
              <button type="button" className="o-button__add" onClick={() => openModal()}>
              Add metadata form: <strong>{template.title}</strong>
              </button>
            ) : (
              <>
                <label className="c-input__label" htmlFor={`cedar__${resource_id}`}>Choose a metadata form
                </label>
                <select
                  id={`cedar__${resource_id}`}
                  className="c-input__select"
                  name="cedarTemplate"
                  onChange={(e) => {
                    const t = e.currentTarget;
                    setTemplate(t.value ? {id: t.value, title: t.options[t.selectedIndex].label} : null);
                  }}
                >
                  <option key="0" value="" label="Select a relevant form" />
                  {templates.map((tm) => (<option key={tm.id} value={tm.id} label={tm.title} />))}
                </select>
                <button disabled={!template} type="button" className="o-button__add" onClick={() => openModal()}>
                Add metadata form
                </button>
              </>
            )
        )}
      </div>
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
