
Letter Opener
==============

letter_opener is a gem that intercepts emails and makes them available for easy
viewing.

When a non-production Dryad server is running, view the emails at http://<server_name>/letter_opener/


Issues
-------

If you are trying to use letter_opener in rails console, a web browser must be
installed, preferably Chrome. If a browser is not available, any attempts at
sending email will result in an exception.

On servers that are accessed remotely, Chrome should still be installed. Even
though you will still see error messages, they won't actually trigger
exceptions, so the flow of control will remain.
