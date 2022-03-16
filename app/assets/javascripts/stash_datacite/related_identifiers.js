// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadRelatedIdentifiers() {
  $( '.js-related_identifier' ).on('focus', function () {
    previous_value = this.value;
  }).change(function() {
    new_value = this.value;
    // Save when the new value is different from the previous value
    if( (new_value != '') && (new_value != previous_value) )  {
      var form = $(this.form);
      $(form).trigger('submit.rails');
    }
  });

  $( '.js-work_type').change(function(){
    var form = $(this.form);
    $(form).trigger('submit.rails');
  });
};

function hideRemoveLinkRelatedIdentifiers() {
  if($('.js-related_identifier').length < 2)
  {
   $('.js-related_identifier').first().parent().parent().find('.remove_record').hide();
  }
  else
  {
   $('.js-related_identifier').first().parent().parent().find('.remove_record').show();
  }
};