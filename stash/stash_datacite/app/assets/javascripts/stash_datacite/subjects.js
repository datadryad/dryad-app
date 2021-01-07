function loadSubjects() {

  $('#js-keywords__container').click(function(){
    $('.js-keywords__input').focus();
  });

  $('.js-keywords__input').focus(function(){
    $('#js-keywords__container').addClass('c-keywords__container--has-focus').removeClass('c-keywords__container--has-blur');
  });

  $('#keyword').keydown(function(event) {
    if (event.keyCode == 13 || event.keyCode == 9) {
      // only does the complete/submit with a value, otherwise allow to tab out of form
      if($('#keyword').val()) {
        var self = $(this);
        var form = self.parents('form');
        $(form).trigger('submit.rails');
        event.preventDefault();
      }
    }
  });

  $('.js-keywords__input').blur(function(){
    $('#js-keywords__container').removeClass('c-keywords__container--has-focus').addClass('c-keywords__container--has-blur');
  });
};