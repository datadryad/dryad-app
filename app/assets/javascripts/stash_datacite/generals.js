// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.


$(function() {
  var icons = {
    header: "ui-icon-circle-arrow-e",
    activeHeader: "ui-icon-circle-arrow-s"
  };
  $( "#accordion" ).accordion({
    heightStyle: "content",
    collapsible: true,
    icons: icons
  });
});


$(document).ready(function(){
  $( "#target" ).blur(function() {
    autoSaveForm();
  });
});

function autoSaveForm(){
  var valuesToSubmit = $('form').serialize();
  alert(valuesToSubmit)
  $.ajax({
    url: $(this).action,
    headers: {
      Accept : "text/javascript; charset=utf-8",
      "Content-Type": 'application/x-www-form-urlencoded; charset=UTF-8'
    },
    type: 'POST',
    data: valuesToSubmit,
  });
}