// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

/*
jQuery(function() {
    return $('#fileupload').fileupload({
        dataType: "script",
        add: function(e, data) {
            return data.submit();
        },
        progress: function(e, data) {
            var progress;
            if (data.context) {
                progress = parseInt(data.loaded / data.total * 100, 10);
                return data.context.find('.bar').css('width', progress + '%');
            }
        }
    });
});*/

$(function () {
    $('#fileupload').fileupload({
        dataType: 'script',
        add: function (e, data) {
            console.log(data.files[0]);
            data.files[0]['id'] = generateQuickId();
            data.context = $(tmpl("upload-line", data.files[0]));
            $('#upload_table').append(data.context);
            $('#up_button_' + data.files[0].id ).click(function () {
                    data.submit();
            });
        },
        done: function (e, data) {
            $('#up_button_' + data.files[0].id).text('Upload finished.');
        }
    });
});

function generateQuickId() {
    return Math.random().toString(36).substring(2, 15) +
        Math.random().toString(36).substring(2, 15);
}