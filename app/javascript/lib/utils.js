export function showSavingMsg(){
  $('.saving_text').show();
  $('.saved_text').hide();
}

export function showSavedMsg(){
  $('.saving_text').hide();
  $('.saved_text').show();
}

// a version of the modal confirm dialog from rails for react
export function showModalYNDialog(message, functionIfYes){
  if (!message) return false;

  $('#railsConfMsg').text(message);

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