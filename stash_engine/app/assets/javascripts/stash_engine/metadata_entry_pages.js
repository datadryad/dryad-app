function trapNavigation(){
  $(function () {
    // only attach these events on metadata entry pages
    if($('body.metadata_entry_pages_find_or_create').length < 1){
      return;
    }
    $('a, #dashboard_path, #upload_path').click(function(my_evt){

      if (typeof waitedOnceForNavigation === "undefined") {
        // wait for completion and trigger again
          console.log('waitedOnceForNavigation === undefined');
        my_evt.preventDefault();
        $.ajax({
            type: 'GET',
            async: false,
            url: '/stash/ajax_wait'
        }).done(function() {
            waitAjax();
            waitedOnceForNavigation = 1;
            $(my_evt.target).trigger(my_evt);
        });
      }else{
        console.log('waitedOnceForNavigation == 1');
      }
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
}
