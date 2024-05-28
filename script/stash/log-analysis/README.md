# About this directory
This directory currently contains a standalone script that will extract timing from the rails logs where it sees a string
like "Completed in *digits* ms" which indicates the timing for a completed request in
the log.

Unfortunately, it is hard/annoying to match this completion with the action
that is actually being completed since it is on an earlier line in the application log.
In theory you could find it by searching backwards in the file for
the previous action started by the same process ID that is currently completing.

The script just gets these numbers out of the file and buckets them into
different ranges and also gets totals and an average.

For some items we wanted to get information about specific actions (version and
file downloads) so we obtained these by URLs from the Apache access logs which
are easier to deal with since there is one action per line.

Unfortunately, the Apache logs don't have request time lengths, but they do have
byte counts and http status codes. I was able to get some byte counts for the
normal download actions from the apache logs.  I'm putting those shell commands in
below so I won't have to re-invent them again if we need to run them in the future.

Note that the queries of the Apache access logs and the Rails logs don't exactly match
up and there may be some reasons for this which I haven't really investigated in
detail.  I think the reasons may be:

- Rails probably doesn't log timings for requests that cause errors.
- Rails may be configured to have another server (NGINX or Apache for instance)
serve static (non-interpreted) assets such as CSS and JavaScript rather than
handle it itself.
- Perhaps need to match the HTTP status codes more closely between Rails and Apache.
- Does Apache do any redirect handling or caching that show in its access logs, but not in Rails logs?

Anyway, some useful queries.  (These were performed on my Mac, so might be slightly different or maybe not in Amazon Linux).

```bash
# counts the lines, aka all requests in access log
wc -l <apache-access-log-filename>

# counts completed requests with timings in rails log
egrep 'Completed.+in.+[0-9]+ms' <rails-log-filename> | wc -l

# counts started version downloads in rails log (may not have successfully completed)
egrep 'Started.+\/stash\/downloads\/download_resource\/[0-9]+' <rails-log-filename> | wc -l

# counts started individual file downloads in rails log (may not have successfully completed)
egrep 'Started.+\/stash\/downloads\/file_stream\/[0-9]' <rails-log-filename> | wc -l

# counts 200 OK version downloads in Apache access log
egrep '\/stash\/downloads\/download_resource\/[0-9]+ HTTP/1.1" 200 [0-9]+' <apache-access-log> | wc -l

# counts 200 OK file downloads in Apache access log
egrep '\/stash\/downloads\/file_stream\/[0-9]+ HTTP/1.1" 200 [0-9]+' <apache-access-log> | wc -l

# sums version download bytes from Apache access log for 200 OK
egrep -o '\/stash\/downloads\/download_resource\/[0-9]+ HTTP/1.1" 200 [0-9]+' <apache-access-log> | awk '{ SUM += $4} END { print SUM }'

# sums file download bytes from Apache access log for 200 OK
egrep -o '\/stash\/downloads\/file_stream\/[0-9]+ HTTP/1.1" 200 [0-9]+' <apache-access-log> | awk '{ SUM += $4} END { print SUM }'
```

