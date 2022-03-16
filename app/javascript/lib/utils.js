import {nanoid} from 'nanoid';

export function showSavingMsg(){
  // ignore jquery undefined in tests without page context
  if (! typeof jQuery == 'undefined') {
    $('.saving_text').show();
    $('.saved_text').hide();
  }
}

export function showSavedMsg(){
  // ignore jquery undefined in tests without page context
  if (! typeof jQuery == 'undefined'){
    $('.saving_text').hide();
    $('.saved_text').show();
  }
}

// if an id is null then make one for a form, etc
export function makeId(id){
  return id || nanoid();
}

// a version of the modal confirm dialog from rails for react
export function showModalYNDialog(message, functionIfYes){

  const msgPlace = document.getElementById('railsConfMsg');

  // if no confirm message or no place to put it then just call the action, since no way to make meaningful dialog
  if (!message || !msgPlace) {
    functionIfYes();
    return;
  }

  msgPlace.textContent = message;
  // $('#railsConfMsg').text(message);

  document.getElementById('railsConfirmDialog').showModal();

  const yBtn = document.getElementById('railsConfirmDialogYes');
  const nBtn = document.getElementById('railsConfirmDialogNo');
  const cBtn = document.getElementById('railsConfirmDialogClose');

  const dlgRemoveHandlers = function() {
    yBtn.removeEventListener('click', yHandler, false);
    nBtn.removeEventListener('click', nHandler, false);
    cBtn.removeEventListener('click', cHandler, false);
  }

  const yHandler = yBtn.addEventListener("click", () => {
    document.getElementById('railsConfirmDialog').close();
    dlgRemoveHandlers();
    functionIfYes();
  });

  const nHandler = nBtn.addEventListener("click", () => {
    document.getElementById('railsConfirmDialog').close();
    dlgRemoveHandlers();
  });

  const cHandler = cBtn.addEventListener("click", () => {
    document.getElementById('railsConfirmDialog').close();
    dlgRemoveHandlers();
  });

  return false;
}