// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function loadAccordion() {
  var icons = {
    header: "ui-icon-circle-arrow-e",
    activeHeader: "ui-icon-circle-arrow-s"
  };
  $( "#accordion" ).accordion({
    heightStyle: "content",
    collapsible: true,
    icons: icons
  });

  $('#location_opener').click(function(){
    map.invalidateSize();
    setTimeout(function() {
      map.invalidateSize();
      map.fitBounds(mapBounds());
    }, 1000);
  });
};

function addSavingDisplay(){
  $("[data-remote='true']").bind('ajax:success', function(evt, data, status, xhr){
    $('.saving_text').hide();
    $('.saved_text').show();
  });

  $("[data-remote='true']").bind('ajax:beforeSend', function(evt, data, status, xhr){
    $('.saving_text').show();
    $('.saved_text').hide();
  });
};
