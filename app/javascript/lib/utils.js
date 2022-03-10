import {nanoid} from 'nanoid';

export function showSavingMsg(){
  $('.saving_text').show();
  $('.saved_text').hide();
}

export function showSavedMsg(){
  $('.saving_text').hide();
  $('.saved_text').show();
}

// if an id is null then make one for a form, etc
export function makeId(id){
  return id || nanoid();
}