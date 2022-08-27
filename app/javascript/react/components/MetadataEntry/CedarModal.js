//Modal.js
import React, { useRef } from "react";
import ReactDom from "react-dom";

export const CedarModal = ({ setShowModal, template, config }) => {
    console.log("CedarModal ssm");
   
    const modalRef = useRef();

    function configCedar() {
	console.log("Loading CEDAR config");
	var comp = document.querySelector('cedar-embeddable-editor');
	comp.loadConfigFromURL('/cedar-embeddable-editor/cee-config' + template + '.json');
    }

    function initCedar() {
	console.log("CedarModal.init the modal for template", template);

	// Inject the cedar editor into the modal and open it
	document.querySelector('#genericModalContent').classList.replace('c-modal-content__normal', 'c-modal-content__cedar');
	$('#genericModalContent').html("<script src=\"" + config.table.editor_url + "\"></script>" +
				       "<cedar-embeddable-editor />");
	$('#genericModalDialog')[0].showModal();
    
	// Wait to ensure the page is loaded before initializing the Cedar config
	setTimeout(configCedar, 500);
    }

    // only initialize if it hasn't been initialized yet
    let currModalClass = document.querySelector('#genericModalContent').classList[0];
    if(currModalClass == 'c-modal-content__normal') {
	initCedar();
    }

    // return null because the CEDAR editor fits in the #genericModalDialog, not
    // in the space on the page where this component lives
    return null;
};
