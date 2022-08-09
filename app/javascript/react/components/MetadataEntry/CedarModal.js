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
 
    // Wait a second to ensure the page is loaded before initializing the Cedar config
    // (we should base this one some better trigger in the future)
    setTimeout(configCedar,1000);

    
  //render the modal JSX in the portal div.
  return ReactDom.createPortal(
    <div className="container" ref={modalRef} onClick={closeModal}>
	<div className="modal">

ajaj
	    
          <h2>React-style Modal</h2>
        <button onClick={() => setShowModal(false)}>X</button>
      </div>
    </div>,
    document.getElementById("portal")
  );
};
