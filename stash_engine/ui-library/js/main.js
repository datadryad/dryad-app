// ##### Main JavaScript ##### //

function joelsReady(){

  // ***** Keywords Input Focus ***** //

  // Copied this to keywords component JS in Rails for compatibility with autocomplete JS and removed from here:

  /*

  $('#js-keywords__container').click(function(){
    $('.js-keywords__input').focus();
  });

  $('.js-keywords__input').focus(function(){
    $('#js-keywords__container').attr('class', 'c-keywords__container--has-focus');
  });

  $('.js-keywords__input').blur(function(){
    $('#js-keywords__container').attr('class', 'c-keywords__container--has-blur');
  });

  */

  // ***** Initialize jQuery UI Tooltip ***** //

  // Comment out tooltip method until jQuery UI is included on every page:
  
  // $('.o-button__help').tooltip();

  // ***** Toggle Table Cell Details ***** //

  $('.js-table-heading__button-hide').hide();

  $('.js-table-heading__button-show').click(function(){
    $(this).hide();
    $(this).siblings('.js-table-heading__button-hide').show();
    $(this).parents('.c-table-heading').next().find('.js-table-progress').toggleClass('c-table-progress c-table-progress--details');
    $(this).parents('.c-table-heading').next().find('.js-table-submitted').toggleClass('c-table-submitted c-table-submitted--details');
  });

  $('.js-table-heading__button-hide').click(function(){
    $(this).hide();
    $(this).siblings('.js-table-heading__button-show').show();
    $(this).parents('.c-table-heading').next().find('.js-table-progress').toggleClass('c-table-progress--details c-table-progress');
    $(this).parents('.c-table-heading').next().find('.js-table-submitted').toggleClass('c-table-submitted--details c-table-submitted');
  });

  // ***** Select Content Object ***** //

  $('.o-select__select').change(function(){
    $(this).find('option:selected').each(function(){
      if($(this).hasClass('js-select__option1')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content1').show();
      }
      else if($(this).hasClass('js-select__option2')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content2').show();
      }
      else if($(this).hasClass('js-select__option3')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content3').show();
      }
      else if($(this).hasClass('js-select__option4')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content4').show();
      }
      else if($(this).hasClass('js-select__option5')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content5').show();
      }
      else if($(this).hasClass('js-select__option6')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content6').show();
      }
      else if($(this).hasClass('js-select__option7')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content7').show();
      }
      else{
        $(this).parents('.o-select__input').siblings('.o-select__content').hide();
      }
    });
  }).change();

  // ***** Location Inputs ***** //

  $('.js-location__box-inputs').hide();

  $('.js-location__point-button').click(function(){
    $('.js-location__point-inputs').show();
    $('.js-location__box-inputs').hide();
    $('.js-location__point-button').removeClass('c-location__point-button');
    $('.js-location__point-button').addClass('c-location__point-button--active');
    $('.js-location__box-button').removeClass('c-location__box-button--active');
    $('.js-location__box-button').addClass('c-location__box-button');
  });

  $('.js-location__box-button').click(function(){
    $('.js-location__box-inputs').show();
    $('.js-location__point-inputs').hide();
    $('.js-location__box-button').removeClass('c-location__box-button');
    $('.js-location__box-button').addClass('c-location__box-button--active');
    $('.js-location__point-button').removeClass('c-location__point-button--active');
    $('.js-location__point-button').addClass('c-location__point-button');
  });

  // ***** Facets ***** //

  $('.js-facet__deselect-button').click(function(){
    $(this).parent().siblings().children('.js-facet__check-input').prop('checked', false);
    $(this).attr('disabled', '');
  });

  $('.js-facet__check-input').click(function() {
    if ($(this).is(':checked')) {
      $(this).parent().siblings().find('.js-facet__deselect-button').removeAttr('disabled');
    } else {
      $(this).parent().siblings().find('.js-facet__deselect-button').attr('disabled', '');
    }
    
  });

  $('.js-facet__toggle-button').click(function(){
    $(this).toggleClass('c-facet__toggle-button--open c-facet__toggle-button');
    $(this).parents().siblings('.js-facet__check-group').toggleClass('c-facet__check-group--open c-facet__check-group');
    $(this).parent().siblings('.js-facet__deselect-button').toggleClass('c-facet__deselect-button--open c-facet__deselect-button');
  });

  // ***** Alert Close ***** //

  $('.js-alert__close').click(function(){
    $(this).parent('.js-alert').fadeToggle();
  });

  // ***** Header Mobile Menu Toggle ***** //

  $('.js-header__menu-button').click(function(){
    $('.js-header__nav').toggleClass('c-header__nav c-header__nav--is-open');
  });

  // ***** Required Field State ***** //

  $('[required]').map(function() {
    $(this).siblings('label').removeClass('c-input__label');
    $(this).siblings('label').addClass('c-input__label--required');
  });

  // ***** Publication Dates ***** //

  $('.js-pubdate__release-date-input').attr('value', 'mm/dd/yyyy');

  var week1 = moment().add(1, 'week').format('M/DD/YYYY');
  var week1datetime = moment().add(1, 'week').format('YYYY-MM-DD');
  $('.js-pubdate__week1').text(week1);
  $('.js-pubdate__week1').attr('datetime', week1datetime);

  var month1 = moment().add(1, 'month').format('M/DD/YYYY');
  var month1datetime = moment().add(1, 'month').format('YYYY-MM-DD');
  $('.js-pubdate__month1').text(month1);
  $('.js-pubdate__month1').attr('datetime', month1datetime);

  var month3 = moment().add(3, 'month').format('M/DD/YYYY');
  var month3datetime = moment().add(3, 'month').format('YYYY-MM-DD');
  $('.js-pubdate__month3').text(month3);
  $('.js-pubdate__month3').attr('datetime', month3datetime);

  var month6 = moment().add(6, 'month').format('M/DD/YYYY');
  var month6datetime = moment().add(6, 'month').format('YYYY-MM-DD');
  $('.js-pubdate__month6').text(month6);
  $('.js-pubdate__month6').attr('datetime', month6datetime);

  var year1 = moment().add(1, 'year').format('M/DD/YYYY');
  var year1datetime = moment().add(1, 'year').format('YYYY-MM-DD');
  $('.js-pubdate__year1').text(year1);
  $('.js-pubdate__year1').attr('datetime', year1datetime);

}// close joelsReady()
