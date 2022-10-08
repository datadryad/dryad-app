import React from 'react'
import ReactDOM from 'react-dom'
import { Field, Form, Formik } from 'formik'
import moment from 'moment'
import {isEqual} from 'lodash'
import { showSavedMsg, showSavingMsg } from '../../../lib/utils'

class Cedar extends React.Component {
  state = {
    template: null, 
    csrf: null, 
    metadata: null,
    updated: null,
    currentMetadata: null,
  }
  formRef = React.createRef()
  delRef = React.createRef()
  dialog = document.getElementById('genericModalDialog')
  componentDidMount(){
    const csrf = document.querySelector("meta[name='csrf-token']").getAttribute('content')
    const {template, metadata, updated} = JSON.parse(this.props.resource.cedar_json)
    this.setState({ csrf, template, metadata, updated })
    // Move the cdk-overlay-container into the modal for rendering above dialog
    this.popupWatcher = new MutationObserver(() => {
      const popups = document.querySelector('body > .cdk-overlay-container')
      if (popups) {
        this.dialog.append(popups)
      }
    })
    this.popupWatcher.observe(document.body, {childList: true})
    // Check form content when touched
    this.formObserver = new MutationObserver((changes) => {
      changes.forEach((change) => {
        const {target: {classList}} = change
        if (classList.contains('ng-touched')) {
          this.checkSave()
        }
      })
    })
    this.formObserver.observe(this.dialog, {subtree: true, attributeFilter: ['class']})
  }
  componentWillUnMount() {
    if (this.popupWatcher) {
      this.popupWatcher.disconnect()
      this.popupWatcher = null
    }
    if (this.formObserver) {
      this.formObserver.disconnect()
      this.formObserver = null
    }
  }
  // Save form content when changed
  checkSave = () => {
    const currentMetadata = JSON.parse(JSON.stringify(this.editor.currentMetadata))
    if(!isEqual(currentMetadata, this.state.currentMetadata)) {
      this.setState({currentMetadata}, this.saveContent)
    }
  }
  deleteContent = () => {
    this.setState({currentMetadata: null, template: null}, this.saveContent)
  }
  saveContent = () => {
    const { id: resource_id } = this.props.resource
    const { template, csrf, currentMetadata: metadata } = this.state
    const updated = new Date().toISOString()
    const wrappedMeta = {
      info: { template, resource_id, csrf, updated }, 
      metadata
    }
    const xhr = new XMLHttpRequest()
    xhr.open("POST", "http://localhost:3000/cedar-save")
    xhr.setRequestHeader("Accept", "application/json")
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.send(JSON.stringify(wrappedMeta, null, 2))
    console.log('Saved metadata')
    console.log(wrappedMeta)
    this.setState({ metadata, updated })
  }
  modalSetup = () => {
    console.log("Loading CEDAR config")
    const { template, csrf, metadata } = this.state
    const { id: resource_id } = this.props.resource
    this.editor.loadConfigFromURL(`/cedar-config?template=${template.id}`)
    this.editor.templateInfo = {template, resource_id, csrf}
    this.editor.dataset.template = template.id
    // restore metadata
    if(!!metadata) {
      console.log("loading metadata", metadata)
      this.editor.metadata = metadata
    }
  }
  openModal = () => {
    const { template } = this.state
    if (!template && !template.id) {
      console.log("Cannot open modal unless a template is selected.")
      return
    }
    console.log("Cedar init the modal for template " + template.id)
    if (this.dialog) {
      const { table: { editor_url } } = this.props.appConfig
      const modal = document.getElementById('genericModalContent')
      const [currModalClass] = modal.classList
      // only initialize if it hasn't been initialized yet
      if(currModalClass === 'c-modal-content__normal') { 
        // Inject the cedar editor into the modal and open it
        const script = document.createElement('script')
        this.editor = document.createElement('cedar-embeddable-editor')
        script.src = editor_url
        script.async = true
        script.onload = () => this.modalSetup()
        modal.classList.replace('c-modal-content__normal', 'c-modal-content__cedar')
        modal.appendChild(script)
        modal.appendChild(this.editor)
        this.dialog.showModal()        
      }
    }
  }
  showDelete = () => {
    if (this.delRef) {
      const m = this.delRef.current
      if (m.open) {
        m.close()
      } else {
        m.showModal()
      }
    }
  }
  render() {
    if (!this.props.appConfig) return null
    const { table: { templates } } = this.props.appConfig
    if (!templates) return null
    const { id: resource_id, cedar_json } = this.props.resource
    const { csrf, metadata, template, updated, deleteModal } = this.state
    return (
      <div className="cedar-container">
        <h3 className="cedar-heading__level3">Standardized Metadata</h3>
        <p>Fill out a standardized metadata form for your discipline to make your data more useful to others.</p>
        <Formik
          initialValues={{ resource_id, authenticity_token: (csrf || '') }}
          innerRef={this.formRef}
          onSubmit={(values, {setSubmitting}) => {
            showSavingMsg()
            console.log("submitting Cedar selection form")
            this.openModal()
          }}
        >    
          {(formik) => (
            <Form onSubmit={formik.handleSubmit}>
              {metadata && template ? (
                <div style={{display: 'flex', alignItems: 'center' }}>
                  <p style={{padding: '8px', border: 'thin solid #777', backgroundColor: '#fff'}}>
                    <strong>{template.title}</strong><br/>
                    {updated && `Last modified ${moment(updated).local().format('H:mmA, MM/DD/YYYY')}`}
                  </p>
                  <button type="submit" className="o-button__plain-text2" style={{margin: '0 1rem'}}>
                    Edit Form
                  </button>
                  <button type="button" className="o-button__remove" onClick={this.showDelete}>
                    Delete Form
                  </button>
                </div>
              ) : (
                <React.Fragment>
                  <label className="c-input__label" htmlFor={`cedar__${resource_id}`}>Choose a metadata form
                  </label>
                  <select
                    id={`cedar__${resource_id}`}
                    className="c-input__text"
                    name="cedarTemplate"
                    onChange={(e) => {
                      const t = e.currentTarget
                      this.setState({
                        template: {id: t.value, title: t.options[t.selectedIndex].label} 
                      })
                    }}
                    onBlur={formik.handleBlur}
                  >
                    <option key="0" value="" label="- Select One -" />
                    {templates.map((templ) => {
                      return(<option key={ templ[0] } value={ templ[0] } label={ templ[2] } />);
                    })}
                  </select>
                  <button type="submit" className="o-button__add">
                    Add Metadata Form
                  </button>
                </React.Fragment>
              )}
            </Form>       
          )}
        </Formik>
        <dialog className="modalDialog" id="deleteCedarDialog" ref={this.delRef}>
          <div className="modalClose">
            <button aria-label="close" type="button" onClick={this.showDelete}>
              <i className="fa fa-window-close fa-lg" aria-hidden="true"></i>
            </button>
          </div>
          <div className="c-modal-content__normal mat-card">
            <h1 className="mat-card-title">Confirm Deletion</h1>
            <p>Are you sure you want to delete this form? All answers will be lost.</p>
            <button
              className="o-button__plain-text2"
              style={{marginRight: '16px'}}
              onClick={() => {
                this.deleteContent()
                this.showDelete()
              }}
            >
              Delete Form
            </button>
            <button className="o-button__remove" onClick={this.showDelete}>Cancel</button>
          </div>
        </dialog>
      </div>
    )
  }
}

export default Cedar
