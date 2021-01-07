// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function() {
    $('.js-trap-curator-url').click(function (e) {
        e.preventDefault();
        // set the url to come back to for this dataset and they may have a million or two tabs open
        var returnUrl = $(e.target).closest('form').find('input#return_url');
        $(returnUrl).val(window.location.href);

        $(e.target).closest('form').submit();
    })
});
