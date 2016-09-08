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
