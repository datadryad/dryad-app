$(function () {
  // only attach these events on metadata entry pages
  if($('body.metadata_entry_pages_find_or_create').length < 1){
    return;
  }
  $('a').click(function(){
    $.ajax({
      type: 'GET',
      async: false,
      url: '/stash/ajax_wait'
    });
    waitAjax();
  });
});

// blocks until all ajax connections are closed
var waitAjax = function(){
  if($.active < 1){
    return;
  }
  else {
    setTimeout(waitAjax, 100); // check again in 100 ms
  }
}