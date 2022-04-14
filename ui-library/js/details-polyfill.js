// ##### Details Element Polyfill ##### //

$(document).ready(function(){
  setTimeout(function() {
    // $('details div.o-sites__group').hide();
    if($.active > 0) {
      $(document).ajaxStop(function () {
        // $('details div.o-sites__group').show();
        modernizeIt();
        joelsReady();
        $(this).unbind("ajaxStop"); // required since it fires everytime ajax stops after that, otherwise!
      });
    }else{
      modernizeIt();
      joelsReady();
    }
  }, 30);
});

function modernizeIt(){
  // Detect via Modernizr if details element is supported in a browser:

  if (Modernizr.details) {

    // Details element supported:

    $('details').attr('aria-expanded', 'false');
    $('summary').attr('role', 'button');

    if ($('details').is('[open]')) {
      $('[open]').attr('aria-expanded', 'true');
    }

    $('summary').click(function () {
      if ($(this).parent().is('[open]')) {
        $(this).parent().attr('aria-expanded', 'false');

      } else {
        // Close any other menu items before displaying the one clicked
        closeSiblings(this);
        $(this).parent().attr('aria-expanded', 'true');
      }
    });
  } else {
    // Details element not supported:
    $('details').attr('aria-expanded', 'false');
    $('summary').attr('role', 'button');
    $('summary').siblings().hide();

    if ($('details').is('[open]')) {
      $('[open]').children().show();
      $('[open]').attr('aria-expanded', 'true');
    }

    // unbind('click') removed
    $('summary').on("click", function () {
      $(this).parents().siblings().toggle();

      if ($(this).parent().is('[open]')) {
        $(this).parent().removeAttr('open');
        $(this).parent().attr('aria-expanded', 'false');
      } else {
        // Close any other menu items before displaying the one clicked
        closeSiblings(this);
        $(this).parent().attr('open', '');
        $(this).parent().attr('aria-expanded', 'true');
      }
    });
  }
}

function closeSiblings(selector) {
  // Close any other menu items before displaying the selector
  $(selector).closest('.c-header__nav-item').siblings().each(function(idx, sibling) {
    var details = $(sibling).find('details');
    if (details && details.is('[open]')) {
      details.attr('aria-expanded', 'false');
      details.removeAttr('open');
    }
  });
}
