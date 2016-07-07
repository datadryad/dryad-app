// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadRelatedIdentifiers() {
$( '.js-related_identifier' ).on('focus', function () {
  $('.saving_text').show();
  $('.saved_text').hide();
  previous_value = this.value;
  }).change(function() {
    new_value = this.value;
    // Save when the new value is different from the previous value
    if( (new_value != '') && (new_value != previous_value) )  {
      var form = $(this.form);
      $(form).trigger('submit.rails');
    }
  });

  $( '.js-related_identifier' ).blur(function (event) {
    $('.saved_text').show();
    $('.saving_text').hide();
  });
};