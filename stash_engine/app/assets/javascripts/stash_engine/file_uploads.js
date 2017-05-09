// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.\

// manifest workflow
function validateFileUrl(){
  $('#validate_files').on('click', function(){
    var location_urls = $('#location_urls').val();
    alert(location_urls);
    var form = $(this).parents('form');
    $(form).trigger('submit.rails');
    $('#location_urls').val('');
    event.preventDefault();
    $
  });
}

function selectFileLocation(){
  $('#file_location_select').on('change', function() {
    if ($(this).val() == "On this Computer") {
      $('.files_on_computer').show();
      $('.files_on_server').hide();
    }
    else {
      $('.files_on_server').show();
      $('.files_on_computer').hide();
    }
  });
}