function loadPublications() {
    // based on example at http://jqueryui.com/autocomplete/#remote-jsonp
    $(function() {
        function split( val ) {
            return val.split( /,\s*/ );
        }
        function extractLast( term ) {
            return split( term ).pop();
        }

        $( ".js-publications" )
        // don't navigate away from the field on tab when selecting an item
            .bind( "keydown", function( event ) {
                if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).autocomplete( "instance" ).menu.active ) {
                    event.preventDefault();
                }
            })
            .autocomplete({
                create: function(a) {
                    $.ajax({
                        url: "https://api.crossref.org/journals/"+ document.getElementById("internal_datum_publication_name").value,
                        dataType: "json",
                        success: function( data ) {
                            document.getElementById("internal_datum_publication_name").value = ""
                            if (data.message.title != null) {
                                document.getElementById("internal_datum_publication_name").value = data.message.title;
                            }
                        }
                    });
                },
                source: function( request, response ) {
                    $.ajax({
                        url: "https://api.crossref.org/journals?query="+ extractLast( request.term ),
                        dataType: "json",
                        success: function( data ) {
                            $.ajax({
                                url: "https://api.crossref.org/journals?query="+ extractLast( request.term ) + "&rows=" + data.message["total-results"],
                                dataType: "json",
                                success: function( data ) {
                                    var arr = jQuery.map( data.message.items, function( a ) {
                                        return [[ a.ISSN[0], a.title ]];
                                    });
                                    var labels = [];
                                    $.each(arr, function(index, value) {
                                        if (value[0] != null) {
                                            labels.push({value: value[0], label: value[1]});
                                        }
                                    });
                                    response(labels);
                                }
                            });
                        }
                    });
                },
                minLength: 3,
                select: function( event, ui ) {
                    new_value = ui.item.value;
                    document.getElementById("internal_datum_publication_issn").value = new_value;
                    ui.item.value = ui.item.label;
                    var form = $(this.form);
                    $(form).trigger('submit.rails');
                    previous_value = new_value;
                },
                focus: function() {
                    // prevent value inserted on focus
                    return false;
                },
            });
    });

    $( '.js-msid' ).on('focus', function () {
        previous_value = this.value;
        // console.log('previous value:' + previous_value );
    }).change(function() {
        new_value = this.value;
        // Save when the new value is different from the previous value
        if(new_value != previous_value) {
            var form = $(this.form);
            $(form).trigger('submit.rails');
        }
    });
    // trap the submit button, change hidden 'do_import' = 'true' and then submit when this button is clicked
    $('.js-import-ms').click(function(e){
        e.preventDefault();
        $('#internal_datum_do_import').val('true');
        $('#new_internal_datum').submit();
    });
};
