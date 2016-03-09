// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadCreators() {
  $( "#affliation_id" ).autocomplete({
    source: function( request, response ) {
      $.ajax({
        url: "<%= stash_datacite.affliations_autocomplete_path %>",
        dataType: "json",
        data: {
          term: request.term
        },
        success: function( data ) {
          response( data );
        }
      });
    },
    minLength: 1,
    focus: function() {
      // prevent value inserted on focus
      return false;
    },
    open: function() {
      $( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );
    },
    close: function() {
      $( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );
    }
  });

  $( ".creator_first_name" ).on('focus', function () {
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        $(form).trigger('submit.rails');
      }
    });

  $( ".creator_last_name" ).on('focus', function () {
    previous_value = this.value;
    }).change(function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        $(form).trigger('submit.rails');
      }
    });
};