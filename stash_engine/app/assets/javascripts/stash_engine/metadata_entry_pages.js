function trapNavigation() {
    $(function () {
        // only attach these events on metadata entry pages
        if ($('body.metadata_entry_pages_find_or_create').length < 1) {
            return;
        }

        // blocks until all ajax connections are closed
        var waitAjax = function () {
            if ($.active < 1) {
                return;
            } else {
                setTimeout(waitAjax, 100); // check again in 100 ms
            }
        }

        var waitForMyAjaxClicks = function () {
            $.ajax({
                type: 'GET',
                async: false,
                url: '/stash/ajax_wait'
            }).done(function () {
                waitAjax();
            });
        };

        $('a, #dashboard_path, #upload_path').on('click', waitForMyAjaxClicks);
    });
}

// see https://stackoverflow.com/questions/7610871/how-to-trigger-an-event-after-using-event-preventdefault
// may need to use in the future.
