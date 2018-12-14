function trapNavigation() {
    $(function () {
        // only attach these events on metadata entry pages
        if ($('body.metadata_entry_pages_find_or_create').length < 1) {
            return;
        }

        // blocks until all ajax connections are closed
        var waitAjax = function () {
            if ($.ajax.active < 1) {
                return;
            } else {
                setTimeout(waitAjax, 100); // check again in 100 ms
            }
        }

        /* trap the click event for the simple links that navigate away (have .js-nav-out class), wait briefly,
        wait for any ajax to stop, and then navigate manually with the window.location. */
        $('.js-nav-out').on('click', function(e) {
            e.preventDefault();
            my_target = e.target.href;

            setTimeout(
                function(e) {
                    // alert( my_target );
                    waitAjax();
                    window.location = my_target;
                }, 500);
        });
    });
}

// see https://stackoverflow.com/questions/7610871/how-to-trigger-an-event-after-using-event-preventdefault
// may need to use in the future.

