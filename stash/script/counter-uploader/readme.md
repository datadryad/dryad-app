# The reworked Counter-Uploader tool

The old tool depended on state files and we also ran into a number
of issues uploading reports. It was quite manual and it was difficult to keep *state* in sync between the
Python tool that calculates stats and the things we needed to do to re-submit failures.
It's better to minimize the shared state and get as much as possible from the live sources
such as by querying DataCite.  That way we know it is up to date and in sync.

If you invoke the ./main.rb file without setting environment variables it will give info.

## Upload unsubmitted (or suspiciously small) reports for DataCite Counter EventData

Reports should be in the same directory and named in the format 'yyyy-mm.json'. The
tool will scan your files and scan the known reports at DataCite and resubmit things
that DataCite does not have or that have a suspiciously small number of results.

Use a command like this:

```shell script
REPORT_DIR="</path/to/my/reports/directory>" TOKEN="<my-token>" ./main.rb
```

## Force upload of JSON reports (even if they're not suspicious)

This will force resubmission of whatever report months you wish, even if they don't
appear suspicious at DataCite.

Use a command like this:

```shell script
FORCE_SUBMISSION="2018-10, 2019-03, 2020-01" REPORT_DIR="</path/to/my/reports/directory>" TOKEN="<my-token>" ./main.rb
```

## Get information about the reports at DataCite, but don't upload any reports

It's often useful to just run a report of the months that DataCite has reports for along
with the number of pages of results each of those months has. It's useful for tracking
down submission problems.

```shell script
REPORT_IDS=true ./main.rb
```

At the end of the output it will print out report months, DataCite report identifiers and
the number of pages of results.  You'll need report identifiers if you need to update
a report or ask DataCite to investigate ingest problems.