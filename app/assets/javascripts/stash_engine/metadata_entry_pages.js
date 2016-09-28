$(function () {
  if($('body.metadata_entry_pages_find_or_create').length < 1){
    return;
  }
  $('a').click(function(){
    $.ajax({
      type: 'GET',
      async: false,
      url: '/stash/ajax_wait'
    });
  });
});