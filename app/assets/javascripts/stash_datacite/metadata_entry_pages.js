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

  els = $("[data-remote='true']").not("[data-savedisplay='true']");
  els.bind('ajax:success', function(evt, data, status, xhr){
    [...document.querySelectorAll('.saving_text')].forEach((el) => el.setAttribute('hidden', true));
    [...document.querySelectorAll('.saved_text')].forEach((el) => el.removeAttribute('hidden'));
    return true;
  })

  els.bind('ajax:beforeSend', function(evt, data, status, xhr){
    [...document.querySelectorAll('.saving_text')].forEach((el) => el.removeAttribute('hidden'));
    [...document.querySelectorAll('.saved_text')].forEach((el) => el.setAttribute('hidden', true));
    return true;
  });
  // adds data-save-display if event attached
  els.each(function() {
    $(this).attr('data-savedisplay', 'true');
  });
};
