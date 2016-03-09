// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadContributors() {
  // based on example at http://jqueryui.com/autocomplete/#remote-jsonp
  $(function() {
    function split( val ) {
      return val.split( /,\s*/ );
    }
    function extractLast( term ) {
      return split( term ).pop();
    }

    $( ".funders" )
      // don't navigate away from the field on tab when selecting an item
      .bind( "keydown", function( event ) {
        if ( event.keyCode === $.ui.keyCode.TAB &&
            $( this ).autocomplete( "instance" ).menu.active ) {
          event.preventDefault();
        }
      })
      .autocomplete({
        source: function( request, response ) {
          $.ajax({
            url: "https://api.crossref.org/funders?query="+ extractLast( request.term ),
            dataType: "json",
            success: function( data ) {
                var arr = jQuery.map( data.message.items, function( a ) {
                return [[ a.id, a.name, a.uri ]];
              });
              console.log(arr);
              var labels = [];
              $.each(arr, function(index, value) {
                labels.push(value[1]);
              });
              response(labels);
            }
          });
        },
        minLength: 1,
        focus: function() {
          // prevent value inserted on focus
          return false;
        },
      });
    });

    $( ".funders" ).on('focus', function () {
      previous_value = this.value;
      }).change(function() {
        new_value = this.value;
        // Save when the new value is different from the previous value
        if(new_value != previous_value) {
          var form = $(this.form);
          alert(form);
          $(form).trigger('submit.rails');
        }
    });

    $( ".award_number" ).on('focus', function () {
      previous_value = this.value;
      }).change(function() {
        new_value = this.value;
        // Save when the new value is different from the previous value
        if(new_value != previous_value) {
          var form = $(this.form);
          $(form).trigger('submit.rails');
        }
    });

};
