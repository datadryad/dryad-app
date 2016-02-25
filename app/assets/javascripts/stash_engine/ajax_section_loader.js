// see http://stackoverflow.com/questions/6214201/best-practices-for-loading-page-content-via-ajax-request-in-rails3
// for information about how data-load works.

$( document ).ready(function() {
  $("[data-load]").filter(":visible").each(function () {
    var path = $(this).attr('data-load');
    // $(this).load(path);
    $.ajax({
      url: path,
      // data: data,
      // success: success,
      dataType: 'script'
    });
  });
});