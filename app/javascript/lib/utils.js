import {nanoid} from 'nanoid';

export function showSavingMsg(){
  [...document.querySelectorAll('.saving_text')].forEach((el) => el.removeAttribute('hidden'));
  [...document.querySelectorAll('.saved_text')].forEach((el) => el.setAttribute('hidden', true));
  return true;
}

export function showSavedMsg(){
  [...document.querySelectorAll('.saving_text')].forEach((el) => el.setAttribute('hidden', true));
  [...document.querySelectorAll('.saved_text')].forEach((el) => el.removeAttribute('hidden'));
  return true;
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
  dlgRemoveHandlers();

  const yBtn = document.getElementById('railsConfirmDialogYes');
  const nBtn = document.getElementById('railsConfirmDialogNo');
  const cBtn = document.getElementById('railsConfirmDialogClose');

  function dlgRemoveHandlers() {
    ['railsConfirmDialogYes', 'railsConfirmDialogNo', 'railsConfirmDialogClose'].forEach((el) => {
      var old_element = document.getElementById(el);
      var new_element = old_element.cloneNode(true);
      old_element.parentNode.replaceChild(new_element, old_element);
    });
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