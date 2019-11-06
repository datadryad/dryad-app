// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function loadDescriptions() {
  // the js-description is a text-area for text, only, but turns hidden with ckeditor, so really not used except maybe fallback(?)
  /*
  $( '.js-description' ).on('focus', function () {
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        $(form).trigger('submit.rails');
      }
    }); */

  /*
  $('.js-description').on('blur', function(e){
    alert('hi there, blurred');
  } );
  */

  // CKEditor is a bit hard to work with and the documentation is voluminous and spread far around
  // These examples might be helpful for us
  //
  /* evt.editor gives the editor for the current event
     evt.editor.name gives the name of the editor, which corresponds with the id of the textarea the CKEditor replaces
     evt.editor.getData() gives the HTML inside the CKEditor in case you want to do something with it.
     evt.editor.updateElement() seems necessary to force the hidden textarea to be updated programatically.
          It will update automatically with a submit button, but not a programatic submit, it seems.
  */

  for (instance in CKEDITOR.instances){
    CKEDITOR.instances[instance].on('blur', function(evt){
      txtAreaElement = $('#' + evt.editor.name); // gives the original hidden/replaced textarea (not the iFrame CKEditor)
      parentForm = txtAreaElement.closest('form');

      evt.editor.updateElement(); // need to force it because doesn't update without a submit click
      parentForm.trigger('submit.rails');
    });
  };
}
