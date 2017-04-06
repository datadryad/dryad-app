// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadTitles() {
  $( '.title' ).on('focus', function () {
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        $(form).trigger('submit.rails');
      }
    });
};