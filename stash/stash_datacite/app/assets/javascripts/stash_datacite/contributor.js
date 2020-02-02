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
			    console.log("csuccess")
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
		    console.log("cselect", ui.item)
		    console.log("-- val", ui.item.value)
		    console.log("-- lab", ui.item.label)
		    console.log("-- id", ui.item.id)
		    console.log("-- formfiedld",$('.js-funder-id'))
		    
		    $('.js-funder-id').val(ui.item.id); // set hidden field name_identifier_id
		    var form = $(this).parents('form');
		    console.log("trigger A")
		    $(form).trigger('submit.rails');
		},
		focus: function() {
		    // prevent value inserted on focus
		    return false;
		},
	    });
    });
    
    $( '.js-funders' ).on('focus', function () {
	console.log("cfocus")
    }).change(function() {
	console.log("cfocus -- save")
	var form = $(this.form);
	console.log("trigger B")
        $(form).trigger('submit.rails');
    });
    
    $( '.js-award_number' ).on('focus', function () {
	console.log("afocus")
    }).change(function() {
	console.log("afocus -- save")
        var form = $(this.form);
	console.log("trigger C")
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
