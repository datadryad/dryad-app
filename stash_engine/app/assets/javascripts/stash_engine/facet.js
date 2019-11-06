// only load on certain pages
$(document).ready(function(){
  if( $( ".js-title-toggle" ).length) {
    console.log('loading js on page');
    // set menus hidden if they are in hidden state of pointy arrow
    $(".js-title-toggle").each(function (index) {
      if ($(this).hasClass("c-facet-title--closed")) {
        $(this).next('.js-hideshow').hide();
      }
    });

    // add events to toggle and prevent default of toggle click
    $(".js-title-toggle").click(function (event) {
      toggleMenu($(this));
    });
    $(".js-title-toggle a").click(function (event) {
      event.preventDefault();
    });
  }
});

// toggle the menu open and closed
function toggleMenu(t){
  var el = t.next('.js-hideshow');
  if(el.is(':visible')){
    el.slideUp();
    t.removeClass('c-facet-title--open');
    t.addClass('c-facet-title--closed');
  }else{
    el.slideDown();
    t.addClass('c-facet-title--open');
    t.removeClass('c-facet-title--closed');
  }
}