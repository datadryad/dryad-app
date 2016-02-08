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
                e.preventDefault();
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

function formatSizeUnits(bytes) {
    if (bytes == 1){
        return '1 byte';
    }else if (bytes < 1000){
        return bytes + ' bytes';
    }

    var units = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    for (i = 0; i < units.length; i++) {
        if(bytes/Math.pow(10, 3*(i+1)) < 1){
            return (bytes/Math.pow(10, 3*i)).toFixed(2) + " " + units[i];
        }
    }
}
