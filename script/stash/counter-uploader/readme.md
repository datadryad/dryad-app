# The reworked Counter-Uploader tool

The old tool depended on state files and we also ran into a number
of issues uploading reports. It was quite manual and it was difficult to keep *state* in sync.

This gets the state and report ids from datacite and checks them against the json report files locally.



## Upload unsubmitted (or suspiciously small) reports for DataCite Counter EventData

Reports should be in the directory you specify and in the format 'yyyy-mm.json'. The
tool will scan your files and scan the known reports at DataCite and resubmit things
that DataCite does not have or that have a suspiciously small number of results.

Use a command like this:

```shell script
RAILS_ENV=production REPORT_DIR="/my/report/dir" bundle exec rails counter:datacite_pusher
```

## Force upload of JSON reports (even if they're not suspicious)

This will force resubmission of whatever report months you wish, even if they don't
appear suspicious at DataCite.

Use a command like this:

```shell script
RAILS_ENV=production REPORT_DIR="/my/report/dir" FORCE_SUBMISSION="2021-11" bundle exec rails counter:datacite_pusher
```

## Get information about the reports at DataCite, but don't upload any reports

It's often useful to just run a report of the months that DataCite has reports for along
with the number of pages of results each of those months has. It's useful for tracking
down submission problems.

```shell script
RAILS_ENV=production REPORT_DIR="/my/report/dir" REPORT_IDS=true bundle exec rails counter:datacite_pusher
```

At the end of the output it will print out report months, DataCite report identifiers and
the number of pages of results.  You'll need report identifiers if you need to update
a report or ask DataCite to investigate ingest problems.