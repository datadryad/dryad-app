// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadRelatedIdentifiers() {
$( ".related_identifier" ).on('focus', function () {
  previous_value = this.value;
  }).change(function() {
    new_value = this.value;
    // Save when the new value is different from the previous value
    if(new_value != previous_value) {
      var form = $(this.form);
      $(form).trigger('submit.rails');
    }
  });

  $( ".relation_type" ).on('focus', function () {
  previous_value = this.value;
  }).change(function() {
    new_value = this.value;
    // Save when the new value is different from the previous value
    if(new_value != previous_value) {
      var form = $(this.form);
      $(form).trigger('submit.rails');
    }
  });

  $( ".related_identifier_type" ).on('focus', function () {
  previous_value = this.value;
  }).change(function() {
    new_value = this.value;
    // Save when the new value is different from the previous value
    if(new_value != previous_value) {
      var form = $(this.form);
      $(form).trigger('submit.rails');
    }
  });
};