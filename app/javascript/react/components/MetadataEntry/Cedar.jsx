import React from 'react'
import { Field, Form, Formik } from 'formik'
import PropTypes from 'prop-types'
import axios from 'axios'
import {isEqual} from 'lodash'
import { showSavedMsg, showSavingMsg } from '../../../lib/utils'

class Cedar extends React.Component {
  state = {
    templateSelect: null, 
    csrf: null, 
    loaded: true, 
    metadata: null,
    currentMetadata: null,
  }
  formRef = React.createRef
  dialog = document.getElementById('genericModalDialog')
  componentDidMount(){
    const csrf = document.querySelector("meta[name='csrf-token']").getAttribute('content')
    const metadata = JSON.parse(this.props.resource.cedar_json)
    this.setState({ csrf, metadata })
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
      this.setState({currentMetadata})
      this.saveContent()
    }
  }
  saveContent = () => {
    const { id: resource_id } = this.props.resource
    const { csrf, currentMetadata: metadata } = this.setState
    const wrappedMeta = {info: {resource_id, csrf}, metadata}
    const xhr = new XMLHttpRequest()
    xhr.open("POST", "http://localhost:3000/cedar-save")
    xhr.setRequestHeader("Accept", "application/json")
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.send(JSON.stringify(wrappedMeta, null, 2))
    console.log('Saved metadata')
    console.log(wrappedMeta)
  }
  modalSetup = () => {
    console.log("Loading CEDAR config")
    const { templateSelect, csrf, metadata } = this.state
    const { id: resource_id } = this.props.resource
    this.editor.loadConfigFromURL(`/cedar-embeddable-editor/cee-config${templateSelect}.json`)
    this.editor.templateInfo = {resource_id, csrf}
    this.editor.dataset.template = templateSelect
    // restore metadata
    if(!!metadata) {
      console.log("loading metadata", metadata)
      this.editor.metadata = metadata
    }
  }
  openModal = (e) => {
    e.preventDefault()
    const { templateSelect } = this.state
    if (!templateSelect) {
      console.log("Cannot open modal unless a template is selected.")
      return
    }
    console.log("Cedar init the modal for template " + templateSelect)
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
  render() {
    if (!this.props.appConfig) return null
    const { table: { templates } } = this.props.appConfig
    if (!templates) return null
    const { id: resource_id } = this.props.resource
    const { csrf } = this.state
    return (
      <div className="cedar-container">
        <h3 className="cedar-heading__level3">Standardized Metadata</h3>
        <p>Fill out a standardized metadata form for your discipline to make your data more useful to others.</p>
        <Formik
          initialValues={{ resource_id, authenticity_token: (csrf || '') }}
          innerRef={this.formRef}
          onSubmit={(values, {setSubmitting}) => {
            showSavingMsg();
            console.log("submitting Cedar selection form");
          }}
        >    
          {(formik) => (
            <Form onSubmit={this.openModal}>
              <label className="c-input__label" htmlFor={`cedar__${resource_id}`}>Choose a metadata form</label>
              <select
                className="c-input__text"
                name="cedarTemplate"
                onChange={(e) => this.setState({ templateSelect: e.currentTarget.value })}
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
            </Form>       
          )}
        </Formik>
      </div>
    )
  }
}

export default Cedar