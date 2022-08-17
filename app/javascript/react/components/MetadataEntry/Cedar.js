/* eslint-disable jsx-a11y/label-has-associated-control */
// above eslint is too stupid to realize that the label and control match

import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import { CedarModal } from "./CedarModal";

function Cedar({resource, path, config}) {

    // do not display anything unless there is a template defined
    if (!config || !config.table || !config.table.templates) {
	return null;
    }
    
    const templates = config.table.templates;
    console.log("templates", templates);    

    // see https://stackoverflow.com/questions/54808071/cant-verify-csrf-token-authenticity-rails-react for other options
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    
    const formRef = useRef();
    const templateSelectRef = useRef();
    const [showModal, setShowModal] = useState(false);
    const [cedarTemplate, setCedarTemplate] = useState(0);
    
    console.log("Cedar.js, path is ", path);
    
    const openModal = () => {
	console.log("openModal");
	setShowModal(true);
    };


    const templateOptions = () => {
	templates.map((template, index) => (
	    <option value="{template}" label="Form {template}" />
	));
    };


    console.log("templateOptions", templateOptions);
    
    return (
	<div className="cedar-container">
	    <h3 className="cedar-heading__level3">Standardized Metadata</h3>
	    
	    <p>Fill out a standardized metadata form for your discipline to make your data more useful to others.</p>

	    <Formik
		initialValues={{ resource_id: resource.id, authenticity_token: (csrf || '') }}
		innerRef={formRef}
		onSubmit={(values, {setSubmitting}) => {
		    showSavingMsg();
		    axios.post(path, values, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'text/javascript'}})
			.then((data) => {
			     if (data.status !== 200) {
				 console.log('Received ' + data.status + ' response from CEDAR form');
			     }
			    showSavedMsg();
			    setSubmitting(false);
			});
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
			    { templates.map((templ) => {
				return(<option key={ templ[0] } value={ templ[0] } label={ templ[1] } />);
			    })}
			</select><button className="o-button__add" onClick={openModal}>Add Metadata Form</button>
			{showModal ? <CedarModal setShowModal={setShowModal} template={templateSelectRef.current.value} config={config} /> : null}
		    </Form>
		)}
	    </Formik>
	</div>
    );
}

export default Cedar;
