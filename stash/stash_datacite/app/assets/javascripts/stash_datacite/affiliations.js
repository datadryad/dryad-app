// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

/* need this info to get autocomplete working
  1. Text field for the value
  2. Hidden field to store the ID once it is selected
  3. It is assumed that the parent form above either of these elements is the one that will be submitted with changes.
  4. URL to hit with the autocomplete query (including item to indicate where to substitute the query string)
  5. Assuming JSON is returned, info on how to get the text
  6. Assuming JSON is returned, info on how to get the ID

  We also need to track what changes in the text field (enter/leaving) and do the following
  1) Store the starting value when entering the field or when autocomplete is selected
  1) Submit parent form on blur or after selection
  2) Clear the ID on blur and before form submission if the text value has changed since entry or when it was updated
     by selecting from the list.
 */

function setupAutocomplete(txtFieldId, idFieldId, autoURL, txtKey, idKey){
  const txtField = $(`#${txtFieldId}`);
  const idField = $(`#${idFieldId}`);
  const parentForm = txtField.parents('form');

  console.log(`parent form ${parentForm.attr('id')}`);

  // get rid of any existing event handlers for these items
  txtField.unbind('click');
  txtField.unbind('blur');
  txtField.unbind('focus');

  txtField.focus(function() {
    txtField.attr('data-starting', txtField.val());
    console.log(`focused on autocomplete with ${txtField.val()}`);
  });

  txtField.blur(function() {
    // only submit again if the value has changed since last save
    if (txtField.attr('data-starting') !== txtField.val()){
      $(parentForm).trigger('submit.rails');
    }
  });

  $(txtField).bind( "keydown", function( event ) {
    // prevent tab from navigating out if it is for autocomplete
    if ( event.keyCode === $.ui.keyCode.TAB &&
      $( this ).autocomplete( "instance" ).menu.active ) {
        event.preventDefault();
      }
    }
  );

  $(txtField).autocomplete({
    source: function (request, response) {
      $.ajax({
        url: autoURL,
        dataType: "json",
        data: {
          term: request.term
        },
        success: function (data) {
          response($.map(data, function (item) {
            return {
              value: item.long_name,
              id: item.id
            }
          }));
        }
      });
    },
    minLength: 2,
    focus: function () {
      // prevent value inserted on focus
      return false;
    },
    select: function (event, ui) {
      console.log(ui);
      console.log(event);
      console.log(`idField: ${idField.val()}`);
      console.log(`txtField: ${txtField.val()}`);
      txtField.val(ui.item.value); // be sure the selected item is set, since it sometimes isn't
      idField.val(ui.item.id); // set hidden field ror_id
      txtField.attr('data-starting', txtField.val());
      $(parentForm).trigger('submit.rails');
    },
    open: function (event, ui) {
    },
    close: function (event, ui) {
      // $(this).focus();
    },
    change: function( event, ui ) {
    }
  });

} // end of setupAutocomplete