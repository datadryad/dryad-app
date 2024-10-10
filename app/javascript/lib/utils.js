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

export function upCase(str, locale=navigator.language) {
  return str.replace(/^\p{CWU}/u, char => char.toLocaleUpperCase(locale));
}

const ordinal = ['zeroth', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth',
  'ninth', 'tenth', 'eleventh', 'twelfth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth',
  'seventeenth', 'eighteenth', 'nineteenth'];

const deca = ['twent', 'thirt', 'fort', 'fift', 'sixt', 'sevent', 'eight', 'ninet'];

export function ordinalNumber(n) {
  if (n < 20) return ordinal[n];
  if (n % 10 === 0) return `${deca[Math.floor(n / 10) - 2]}ieth`;
  return `${deca[Math.floor(n / 10) - 2]}y-${ordinal[n % 10]}`;
};

export function formatSizeUnits(bytes) {
  if (bytes < 1000) {
    return `${bytes} B`;
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  for (let i = 0; i < units.length; i += 1) {
    if (bytes / 10 ** (3 * (i + 1)) < 1) {
      return `${(bytes / 10 ** (3 * i)).toFixed(2)} ${units[i]}`;
    }
  }
  return true;
};

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