// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.\

// manifest workflow
function validateFileUrl(){
  $('#validate_files').on('click', function(){
    var location_urls = $('#location_urls').val();
    var form = $(this).parents('form');
    $(form).trigger('submit.rails');
    $('#location_urls').val('');
    event.preventDefault();
    $
  });
}