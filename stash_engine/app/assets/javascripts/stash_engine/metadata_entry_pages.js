function trapNavigation() {
    $(function () {
        // only attach these events on metadata entry pages
        if ($('body.metadata_entry_pages_find_or_create').length < 1) {
            return;
        }

        var someThingsThatNeedToBeDoneFirst = function () {
            $.ajax({
                type: 'GET',
                async: false,
                url: '/stash/ajax_wait'
            }).done(function () {
                console.log('wait a second for ajax to complete');
                waitAjax();
                console.log('ajax completed');
            });
        };

        $('a, #dashboard_path, #upload_path').on('click', onWithPrecondition(someThingsThatNeedToBeDoneFirst));

        // blocks until all ajax connections are closed
        var waitAjax = function () {
            if ($.active < 1) {
                return;
            } else {
                setTimeout(waitAjax, 100); // check again in 100 ms
            }
        }
    });
}

// see https://stackoverflow.com/questions/7610871/how-to-trigger-an-event-after-using-event-preventdefault
function onWithPrecondition(callback) {
    var isDone = false;

    return function (e) {
        if (isDone === true) {
            isDone = false;
            return;
        }

        // preventing default and re-triggering events seems to be problematic with security in Safari and no longer works
        // e.preventDefault();

        callback.apply(this, arguments);

        isDone = true;

        // $(this).click();
    }
}
