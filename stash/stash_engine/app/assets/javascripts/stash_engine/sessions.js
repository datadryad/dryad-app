// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function(){
  // Cancel form submission if the user has not selected a tenant
  $('.c-institution__container').on('click', 'input[type="submit"]', function(e){
    if (!$('#tenant_id').val()) {
      e.preventDefault();
    }
  });

});
