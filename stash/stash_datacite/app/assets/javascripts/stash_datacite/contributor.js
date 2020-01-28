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
		    //console.log("csource -- save")
		    // save the user's typed request, in case they don't click on an autocomplete result
		    //$('<%= "##{form_id}" %> #contributor_name_<%= "##{my_suffix}" %>').val(request.term + "*");
		    //		    var form = $(this).parents('form');
		    //$(form).trigger('submit.rails');
		    $.ajax({
			url: "/stash_datacite/contributors/autocomplete",
			data: { term: request.term },
			dataType: "json",
			success: function( data ) {
			    console.log("csuccess")
			    var arr = jQuery.map( data, function( a ) {
				return [[ a.id, a.name, a.uri ]];
			    });
			    var labels = [];
			    $.each(arr, function(index, value) {
				labels.push(value[1]);
			    });
			    response(labels);
			}
		    });
		},
		minLength: 1,
		select: function( event, ui ) {
		    console.log("cselect")
		    this.value = ui.item.value;
		    var form = $(this.form);
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
        $(form).trigger('submit.rails');
    });
    
    $( '.js-award_number' ).on('focus', function () {
	console.log("afocus")
    }).change(function() {
	console.log("afocus -- save")
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
