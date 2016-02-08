// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {
    $('#fileupload').fileupload({
        dataType: 'script',
        add: function (e, data) {
            data.files[0]['id'] = generateQuickId();
            data.context = $(tmpl("upload-line", data.files[0]));
            $('#upload_list').append(data.context);
            $('#up_button_' + data.files[0].id ).click(function (e) {
                var inputs = data.context.find(':input');
                data.formData = inputs.serializeArray();
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

function formatBytes(bytes,decimals) {
    if(bytes == 0) return '0 Byte';
    var k = 1000;
    var dm = decimals + 1 || 3;
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return (bytes / Math.pow(k, i)).toPrecision(dm) + ' ' + sizes[i];
}