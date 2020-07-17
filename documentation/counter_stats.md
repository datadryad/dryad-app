# Counter Stats

## The report and the tool

This is the report for the Counter CoP on which our counter stats are based.  https://www.projectcounter.org/wp-content/uploads/2019/02/Research_Data_20190227.pdf .

The Python tool is at https://github.com/CDLUC3/counter-processor and was originally
designed around preliminary versions of the report and design-by-committee meetings when
the spec wasn't complete.  It has problems for large-scale processing and is quite slow
because it is trying to calculate "unique size" which was later dropped. It was also created
against a smaller amount of traffic in the logs and has half-completed features like creating
CSV files (which didn't turn out to be a feature the committee decided to prioritize).

Problems:
- Slow to calculate stats on large amounts of log files or traffic.
- Resource intensive
- Calculates unique sizes which never became a thing in the final specification.
- Combines reading logs, calculating and submitting which might be separated.
- The MaxMind geolocation database now requires sign-up, updates and additional overhead to use.
  - For now the lastest available version is available for download from archive.org.
  - If we want to use newer versions, we have to update our code and also check for updates to their DB frequently.
- Submitting to "the hub" had enough errors that it became untrustworthy to try to do it.
  - Right now we are just saving reports to disk, calculating stats into our database through
  another script (from our own reports) and maybe submitting to DataCite occasionally.

## Interventions

- Because of slowness and bugs at the hub we stopped automatically submitting there and have
lots of workarounds in place.
  - We save reports to `/apps/dryad-prd-shared/json-reports`
  - Weekly processing script at `cron/counter.sh` in our config repo.
  - `bundle exec rake counter:clear_cache` completely clears our database table that contains counts.
  - `bundle exec rake counter:cop_manual` reads every month out of the json files and accumulates
  the stats for each dataset into the database (month by month).  I happens after we run stats every
  week.

## The Counter Uploader tool

We reworked the [counter-uploader](../stash/script/counter-uploader/readme.md) so that it can independently
upload counter files outside of the Python tool.  (At least for the time being) the idea
is that we'll process the counter files, populate numbers into our daatabase manually and
then once a month we can upload any missing reports to DataCite.  The tool should be
able to do that without requiring a lot of saved state information besides what it gets from
querying DataCite and the files in the directory.
