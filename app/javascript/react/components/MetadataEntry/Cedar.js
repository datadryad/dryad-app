/* eslint-disable jsx-a11y/label-has-associated-control */
// above eslint is too stupid to realize that the label and control match

import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';


function Cedar({resource, appConfig}) {
    console.log("Rendering Cedar.js");
    
    // do not display anything unless there is a template defined
    if (!appConfig || !appConfig.table || !appConfig.table.templates) {
	return null;
    }

    const formRef = useRef();
    const templateSelectRef = useRef();
    
    const templates = appConfig.table.templates;
    console.log("templates", templates);    

    // see https://stackoverflow.com/questions/54808071/cant-verify-csrf-token-authenticity-rails-react for other options
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');    


    ///////////////////////
    
    function configCedar() {
	console.log("Loading CEDAR config");
	var cee = document.querySelector('cedar-embeddable-editor');

	// config for the metadata template and layout of the CEDAR editor
	cee.loadConfigFromURL('/cedar-embeddable-editor/cee-config' + templateSelectRef.current.value + '.json');

	cee.templateInfo = getCustomTemplateInfo();
    }

    function getCustomTemplateInfo() {
	return {
	    resource_id: resource.id,
	    csrf: csrf
	};
    }

    function setAutoSave() {
	var cee = document.querySelector('cedar-embeddable-editor');
	const saveTime = 3000; // 3 seconds
	setInterval(() => {
	    const meta = cee.currentMetadata;
	    var wrappedMeta = { "metadata" : meta };
	    wrappedMeta['info'] = getCustomTemplateInfo();
	    
	    const xhr = new XMLHttpRequest();
	    xhr.open("POST", "http://secundus.datadryad.org/cedar-save");
	    xhr.setRequestHeader("Accept", "application/json");
	    xhr.setRequestHeader("Content-Type", "application/json");
	    xhr.send(JSON.stringify(wrappedMeta, null, 2));
	    console.log('Saved metadata after ' + saveTime / 1000 + ' seconds');
	    console.log(wrappedMeta);
	}, saveTime);

    }

    /**
       Move the cdk-overlay-container into the modal, so it renders above the modal and not under it.
     */
    function fixPopups() {
        waitForElementToLoad(".cdk-overlay-container", 0).then(function() {
	    const cee = document.querySelector('cedar-embeddable-editor');
	    const dialog = document.getElementById("genericModalDialog");
            const collection = document.getElementsByClassName("cdk-overlay-container");
            dialog.append(collection[0]);
        });
    }
    
    function restoreMetadata() {
	var comp = document.querySelector('cedar-embeddable-editor');
		
	// metadata that previously existed in this resource
	var cjson = resource.cedar_json;
	if(cjson !== null && cjson !== 'undefined') {
	    console.log("loading metadata", cjson);
	    comp.metadata = JSON.parse(cjson);
	}
    }

    /**
     * Wait for an element before resolving a promise
     * Need this to detect when the element "cdk-overlay-container" 
     * has been loaded
     */
    function waitForElementToLoad(querySelector, timeout=0) {
        console.log("1");
        const startTime = new Date().getTime();
        return new Promise((resolve, reject) => {
            const timer = setInterval(() => {
                const now = new Date().getTime();
                if (document.querySelector(querySelector)) {
                    clearInterval(timer);
                    resolve();
                } else if (timeout && now - startTime >= timeout){
                    clearInterval(timer);
                    reject();
                }
            }, 100);
        });
    }
    
    function openModal() {
	if (templateSelectRef.current.value == 0) {
	    console.log("Cannot open modal unless a template is selected.");
	    return;
	}
	// only initialize if it hasn't been initialized yet
	let currModalClass = document.querySelector('#genericModalContent').classList[0];
	if(currModalClass == 'c-modal-content__normal') {
	    console.log("Cedar init the modal for template", templateSelectRef.current.value);
	    
	    // Inject the cedar editor into the modal and open it
	    document.querySelector('#genericModalContent').classList.replace('c-modal-content__normal', 'c-modal-content__cedar');
	    $('#genericModalContent').html("<script src=\"" + appConfig.table.editor_url + "\"></script>" +
					   "<cedar-embeddable-editor />");
	    $('#genericModalDialog')[0].showModal();
	    
	    // Wait to ensure the page is loaded before initializing the Cedar config,
	    // and wait a little longer before restoring any metadata that was in the form
	    setTimeout(configCedar, 250);
	    setTimeout(fixPopups, 250);
	    setTimeout(restoreMetadata, 1000);
	    setTimeout(setAutoSave, 3000);
	}	
    };

    return (
	<div className="cedar-container">
	    <h3 className="cedar-heading__level3">Standardized Metadata</h3>
	    
	    <p>Fill out a standardized metadata form for your discipline to make your data more useful to others.</p>

	    <Formik
		initialValues={{ resource_id: resource.id, authenticity_token: (csrf || '') }}
		innerRef={formRef}
		onSubmit={(values, {setSubmitting}) => {
		    showSavingMsg();
		    console.log("submitting Cedar selection form");
		}}
	    >	   
		{(formik) => (
		    <Form onSubmit={formik.handleSubmit}>
			<label className="c-input__label" htmlFor={`cedar__${resource.id}`}>Choose a metadata form</label>
			<select
			    className="c-input__text"
			    name="cedarTemplate"
			    onChange={formik.handleChange}
			    onBlur={formik.handleBlur}
			    ref={templateSelectRef}
			>
			    <option key="0" value="0" label="- Select One -" />
			    { templates.map((templ) => {
				return(<option key={ templ[0] } value={ templ[0] } label={ templ[2] } />);
			    })}
			</select>
			<button type="submit" className="o-button__add" onClick={openModal}>Add Metadata Form</button>
		    </Form>		    
		)}
	    </Formik>

	</div>
    );
}

export default Cedar;
