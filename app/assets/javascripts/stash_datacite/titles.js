// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function(){
  $( ".title" ).blur(function() {
    var form =  $(".title").parents('form');
    $(form).trigger('submit.rails');
  });
});