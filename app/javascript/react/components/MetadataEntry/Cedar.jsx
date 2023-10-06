import React from 'react';
import {Form, Formik} from 'formik';
import moment from 'moment';
import {isEqual} from 'lodash';
import {showSavingMsg, showSavedMsg} from '../../../lib/utils';

class Cedar extends React.Component {
  state = {
    template: null,
    csrf: null,
    metadata: null,
    updated: undefined,
    currentMetadata: null,
  };

  formRef = React.createRef();

  delete = null;

  dialog = null;

  editor = null;

  componentDidMount() {
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const {template, metadata, updated} = this.props.resource.cedar_json ? JSON.parse(this.props.resource.cedar_json) : {};
    this.setState({
      csrf, template, metadata, updated,
    });
  }

  componentWillUnmount() {
    if (this.popupWatcher) {
      this.popupWatcher.disconnect();
      this.popupWatcher = null;
    }
    if (this.formObserver) {
      this.formObserver.disconnect();
      this.formObserver = null;
    }
    if (this.editorLoaded) {
      this.editorLoaded.disconnect();
      this.editorLoaded = null;
    }
  }

  setRef = (el) => {
    if (el?.id === 'cedarDialog') {
      this.dialog = el;

      // Move the cdk-overlay-container into the modal for rendering above dialog
      this.popupWatcher = new MutationObserver(() => {
        const popups = document.querySelector('body > .cdk-overlay-container');
        if (popups) this.dialog.append(popups);
      });

      // Check form content when touched
      this.formObserver = new MutationObserver((changes) => {
        changes.forEach((change) => {
          const {target: {classList}} = change;
          if (classList.contains('ng-touched')) this.checkSave();
        });
      });

      this.popupWatcher.observe(document.body, {childList: true});
      this.formObserver.observe(this.dialog, {subtree: true, attributeFilter: ['class']});
    }
    if (el?.id === 'deleteCedarDialog') this.delete = el;
    if (el?.id === 'cedarEditor') this.editor = el;
  };

  // Save form content when changed
  checkSave = () => {
    const currentMetadata = JSON.parse(JSON.stringify(this.editor.currentMetadata));
    if (!isEqual(currentMetadata, this.state.currentMetadata)) {
      const updated = new Date().toISOString();
      this.setState({currentMetadata, updated}, this.saveContent);
    }
  };

  deleteContent = () => {
    this.setState({currentMetadata: null, template: null}, this.saveContent);
    showSavedMsg();
  };

  saveContent = () => {
    const {id: resource_id} = this.props.resource;
    const {
      template, csrf, updated, currentMetadata: metadata,
    } = this.state;
    const info = {
      template, resource_id, csrf, updated,
    };
    const wrappedMeta = {info, metadata};
    const xhr = new XMLHttpRequest();
    xhr.open('POST', '/cedar-save');
    xhr.setRequestHeader('Accept', 'application/json');
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send(JSON.stringify(wrappedMeta, null, 2));
    console.log('Saved metadata');
    console.log(wrappedMeta);
    this.setState({metadata, updated});
    if (this.editor) this.editor.templateInfo = info;
    showSavedMsg();
  };

  modalSetup = () => {
    const {
      template, csrf, metadata, updated = new Date().toISOString(),
    } = this.state;
    const {id: resource_id} = this.props.resource;
    this.editor.loadConfigFromURL(`/cedar-config?template=${template.id}`);
    this.editor.templateInfo = {
      template, resource_id, csrf, updated,
    };
    this.editor.dataset.template = template.id;
    // restore metadata
    this.editorLoaded = new MutationObserver(() => {
      const app = document.querySelector('app-cedar-embeddable-metadata-editor');
      if (app && !!metadata) {
        console.log('Loading metadata', metadata);
        this.editor.metadata = metadata;
        this.editorLoaded.disconnect();
        this.editorLoaded = null;
      }
    });
    this.editorLoaded.observe(this.editor, {childList: true});
  };

  openModal = () => {
    showSavingMsg();
    const {template} = this.state;
    if (!template && !template.id) {
      console.log('Cannot open modal unless a template is selected.');
      return;
    }
    if (this.dialog.dataset.template !== template.id) {
      console.log(`Cedar init the modal for template ${template.id}`);
      const {table: {editor_url}} = this.props.appConfig;
      if (editor_url) {
        const script = document.createElement('script');
        script.src = editor_url;
        script.async = true;
        script.onload = () => this.modalSetup();
        this.dialog.appendChild(script);
        this.dialog.dataset.template = template.id;
      }
    }
    this.dialog.showModal();
  };

  render() {
    if (!this.props.appConfig) return null;
    const {table: {templates}} = this.props.appConfig;
    if (!templates) return null;
    const {id: resource_id} = this.props.resource;
    const {
      csrf, metadata, template, updated,
    } = this.state;
    return (
      <div className="cedar-container">
        <h3 className="cedar-heading__level3">Standardized metadata</h3>
        <p>Fill out a standardized metadata form for your discipline to make your data more useful to others.</p>
        <Formik
          initialValues={{resource_id, authenticity_token: (csrf || '')}}
          innerRef={this.formRef}
          onSubmit={() => this.openModal()}
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
                  <button type="button" className="o-button__remove" onClick={() => this.delete.showModal()}>
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
                      this.setState({
                        template: {id: t.value, title: t.options[t.selectedIndex].label},
                      });
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
        <dialog className="modalDialog" id="cedarDialog" ref={this.setRef}>
          <div className="modalClose">
            <button aria-label="close" type="button" onClick={() => this.dialog.close()}>
              <i className="fa fa-window-close fa-lg" aria-hidden="true" />
            </button>
          </div>
          <div className="c-modal-content__cedar">
            <cedar-embeddable-editor id="cedarEditor" ref={this.setRef} />
          </div>
        </dialog>
        <dialog className="modalDialog" id="deleteCedarDialog" ref={this.setRef}>
          <div className="modalClose">
            <button aria-label="close" type="button" onClick={() => this.delete.close()}>
              <i className="fa fa-window-close fa-lg" aria-hidden="true" />
            </button>
          </div>
          <div className="c-modal-content__normal">
            <h1 className="mat-card-title">Confirm Deletion</h1>
            <p>Are you sure you want to delete this form? All answers will be lost.</p>
            <button
              type="button"
              className="o-button__plain-text2"
              style={{marginRight: '16px'}}
              onClick={() => {
                this.deleteContent();
                this.delete.close();
              }}
            >
              Delete Form
            </button>
            <button type="button" className="o-button__remove" onClick={() => this.delete.close()}>Cancel</button>
          </div>
        </dialog>
      </div>
    );
  }
}

export default Cedar;
