
Letter Opener
==============

letter_opener is a gem that intercepts emails and makes them available for easy
viewing.

When a non-production Dryad server is running, view the emails at http://<server_name>/letter_opener/


Testing code with Letter Opener and Timecop
-------------------------------------------

Many activities that use letter_opener are tasks that run at specific times. To
test them, you will need to use Timecop to manipulate the passage of time.

In Rails Console, this will look something like:

```
require 'rake'
require 'timecop'
Timecop.travel(2.months.from_now)
Rails.application.load_tasks
Rake::Task['identifiers:in_progress_reminder_3_days'].execute
```

Issues
-------

If you are trying to use letter_opener in rails console, a web browser must be
installed, preferably Chrome. If a browser is not available, any attempts at
sending email will result in an exception.

On servers that are accessed remotely, Chrome should still be installed. Even
though you will still see error messages, they won't actually trigger
exceptions, so the flow of control will remain.
