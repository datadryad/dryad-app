//Modal.js
import React, { useRef } from "react";
import ReactDom from "react-dom";

export const CedarModal = ({ setShowModal }) => {
    console.log("CedarModal ssm");
    
    // close the modal when clicking outside the modal.
    const modalRef = useRef();
    const closeModal = (e) => {
	console.log("CedarModal.closeModal");
	if (e.target === modalRef.current) {
	    console.log("CedarModal.closeModal true");
	    setShowModal(false);
	}
    };

    function configCedar() {
	console.log("Loading CEDAR config");
	var comp = document.querySelector('cedar-embeddable-editor');
	comp.loadConfigFromURL('/cedar-embeddable-editor/cee-config.json');
    }

    function initCedar() {
	console.log("CedarModal. init the modal");
	
	document.querySelector('#genericModalContent').classList.replace('c-modal-content__normal', 'c-modal-content__cedar');
	$('#genericModalContent').html("<script src=\"/cedar-embeddable-editor/cedar-embeddable-editor-2.6.18-SNAPSHOT.js\"></script> <cedar-embeddable-editor />");

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
