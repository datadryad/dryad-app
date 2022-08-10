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

    function configCedar() {
	console.log("Loading CEDAR config");
	var comp = document.querySelector('cedar-embeddable-editor');
	comp.loadConfigFromURL('/cedar-embeddable-editor/cee-config.json');
    }

    document.querySelector('#genericModalContent').classList.replace('c-modal-content__normal', 'c-modal-content__cedar');
    $('#genericModalContent').html("<script src=\"/cedar-embeddable-editor/cedar-embeddable-editor-2.6.18-SNAPSHOT.js\"></script> <cedar-embeddable-editor />");

    $('#genericModalDialog')[0].showModal();
    
    // Wait to ensure the page is loaded before initializing the Cedar config
    setTimeout(configCedar, 500);
};
