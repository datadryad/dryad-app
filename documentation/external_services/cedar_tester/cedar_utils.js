function openModal() {
    console.log("Init the modal");

    const dialog = document.getElementById("genericModalDialog");
    dialog.showModal();
    setTimeout(configCedar, 250);
}

function closeModal() {
    const dialog = document.getElementById("genericModalDialog");
        
    console.log("closing genericModal");
    dialog.close();
}

function configCedar() {
    console.log("Loading CEDAR config");
    var cee = document.querySelector("cedar-embeddable-editor");
    
    // config for the metadata template and layout of the CEDAR editor                                                                                                     
    cee.loadConfigFromURL("https://dryad-ryan-devbucket.s3.amazonaws.com/cee-config45.json");   
}

