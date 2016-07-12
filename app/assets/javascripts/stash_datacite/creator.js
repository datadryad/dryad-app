// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadCreators() {
  $( '.js-creator_first_name' ).on('focus', function () {
    $('.saving_text').show();
    $('.saved_text').hide();
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        $(form).trigger('submit.rails');
      }
    });

  $( '.js-creator_first_name' ).blur(function (event) {
    $('.saved_text').show();
    $('.saving_text').hide();
  });

  $( '.js-creator_last_name' ).on('focus', function () {
    $('.saving_text').show();
    $('.saved_text').hide();
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        $(form).trigger('submit.rails');
      }
    });

  $( '.js-creator_last_name' ).blur(function (event) {
    $('.saved_text').show();
    $('.saving_text').hide();
  });
};


function hideRemoveLinkCreators() {
  if($('.js-creator_first_name').length < 2)
  {
   $('.js-creator_first_name').first().parent().parent().find('.remove_record').hide();
  }
  else{
   $('.js-creator_first_name').first().parent().parent().find('.remove_record').show();
  }
};
