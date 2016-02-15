// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function() {
  $("div.success").hide();
});

$(document).ready(function(){
  $( ".title" ).on('blur', function(){
    var form =  $(this).parents('form');
    $(form).trigger('submit.rails');
    $( "div.success" ).show().delay( 1000 ).fadeOut( 400 );
  });
});