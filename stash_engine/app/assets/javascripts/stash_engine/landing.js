// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $('.js-download').click(function() {
    my_url = $(this).attr('data-url');
    $.ajax({
      url: my_url,
      type: 'PUT',
     dataType: 'script'
      /* success: function(response) {
        //...
      } */
    });
  });
});
