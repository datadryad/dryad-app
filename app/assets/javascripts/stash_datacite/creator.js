// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadCreators() {

  // this uses a namespace (.mycreators) to disconnect previous events (off) before attaching them again
  // http://stackoverflow.com/questions/11612874/how-can-you-bind-an-event-handler-only-if-it-doesnt-already-exist
  $( '.js-author_first_name, .js-author_last_name' )
    .off('.mycreators')
    .on('focus.mycreators', function () {
      previous_value = this.value;
    })
    .on('change.mycreators', function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        // $(form).trigger('submit.rails');
        queueAjaxFormSubmit(form);
      }
    });


  // ajax events for ujs listed at https://github.com/rails/jquery-ujs/wiki/ajax
  $('form.js-creator_form')
      .off('.mycreator_forms')
      .on('ajax:complete.mycreator_forms', function(event, xhr, status) {
        console.log('ajax:complete');
        if(ajaxQueue.length > 0){
          console.log('submitting form for next queued request:' + ajaxQueue[ajaxQueue.length-1]);
          ajaxInProgress = true;
          $(ajaxQueue.pop()).trigger('submit.rails');
        }else{
          ajaxInProgress = false;
        }
      });

  /*
  $('form.js-creator_form').on('ajax:beforeSend', function(event, xhr, settings) {
    console.log('ajax beforesend');
  }); */
};


function hideRemoveLinkCreators() {
  if($('.js-author_first_name').length < 2)
  {
   $('.js-author_first_name').first().parent().parent().find('.remove_record').hide();
  }
  else{
   $('.js-author_first_name').first().parent().parent().find('.remove_record').show();
  }
};

var ajaxQueue = [];
var ajaxInProgress = false;

function queueAjaxFormSubmit(form){
  console.log('using queueAjaxFormSubmit');
  console.log("ajaxQueue.length " + ajaxQueue.length);
  if(ajaxQueue.length < 1 && !ajaxInProgress){
    ajaxInProgress = true;
    $(form).trigger('submit.rails');
  }else{
    ajaxQueue.push(form);
  }
}
