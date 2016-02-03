// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

jQuery(function() {
    return $('#new_fileupload').fileupload({
        dataType: "script",
        add: function(e, data) {
            return data.submit();
        }/*,
        progress: function(e, data) {
            var progress;
            if (data.context) {
                progress = parseInt(data.loaded / data.total * 100, 10);
                return data.context.find('.bar').css('width', progress + '%');
            }
        }*/
    });
});
