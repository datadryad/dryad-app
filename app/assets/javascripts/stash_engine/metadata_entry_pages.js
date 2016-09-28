$(function () {
  if($('body.metadata_entry_pages_find_or_create').length < 1){
    return;
  }
  $(window).unload(function(){
    console.log('unload function');
    $.ajax({
      type: 'GET',
      async: false,
      url: '/stash/ajax_wait'
    });
  });
});