//Modal.js
import React, { useRef } from "react";
import ReactDom from "react-dom";

export const CedarModal = ({ setShowModal }) => {
    // close the modal when clicking outside the modal.
    const modalRef = useRef();
    const closeModal = (e) => {
	if (e.target === modalRef.current) {
	    setShowModal(false);
	}
    };
    
    $('#genericModalContent').html("<h1>Old style Modal</h1><script src=\"/cedar-embeddable-editor/cedar-embeddable-editor-2.6.18-SNAPSHOT.js\"></script> <cedar-embeddable-editor />");
    $(function() {
	document.querySelector('#genericModalContent').classList.replace('c-modal-content__normal', 'c-modal-content__wide');
	$('#genericModalDialog')[0].showModal();
    });
    
    function configCedar() {
	console.log("Loading CEDAR config");
	var comp = document.querySelector('cedar-embeddable-editor');
	comp.loadConfigFromURL('/cedar-embeddable-editor/cee-config.json');
    }
    
    // Wait to ensure the page is loaded before initializing the Cedar config
    setTimeout(configCedar, 500);
};
