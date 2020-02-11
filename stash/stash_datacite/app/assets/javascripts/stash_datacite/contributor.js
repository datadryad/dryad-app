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
	
	$( ".js-funders" )
	// don't navigate away from the field on tab when selecting an item
	    .bind( "keydown", function( event ) {
		if ( event.keyCode === $.ui.keyCode.TAB &&
		     $( this ).autocomplete( "instance" ).menu.active ) {
		    event.preventDefault();
		}
	    })
	    .autocomplete({
		source: function( request, response ) {
		    $('.js-funder-id').val('');  // erase hidden field name_identifier_id when searching
		    $.ajax({
			url: "/stash_datacite/contributors/autocomplete",
			data: { term: request.term },
			dataType: "json",
			success: function( data ) {
			    response($.map(data, function (item) {
				return {
				    value: item.name,
				    id: item.uri
				}
			    }));			    
			}
		    });
		},
		minLength: 1,
		select: function( event, ui ) {
		    $('.js-funder-id').val(ui.item.id); // set hidden field name_identifier_id
		},
		focus: function() {
		    // prevent value inserted on focus
		    return false;
		},
	    });
    });
    
    $( '.js-funders' ).on('focus', function () {
    }).change(function() {
	var form = $(this).parents('form');
	$(form).trigger('submit.rails');
    });
    
    $( '.js-award_number' ).on('focus', function () {
    }).change(function() {
	var form = $(this).parents('form');
	var form = $(this.form);
	$(form).trigger('submit.rails');
    });
};

function hideRemoveLinkContributors() {
  if($('.js-funders').length < 2)
  {
   $('.js-funders').first().parent().parent().find('.remove_record').hide();
  }
  else
  {
   $('.js-funders').first().parent().parent().find('.remove_record').show();
  }
};
