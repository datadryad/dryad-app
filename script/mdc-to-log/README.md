# Read Make Data Count Database to Log File

This is a simple script to read the MDC sqlite databases that were created
by a python script and extract the information in the database to recreate
log files from the database.

I needed to do this because we do not have our log files except for the past
2 months or so.  We needed to reprocess our Dash log files combined
with the Dryad ones for the same period where we both saw usage.

We'll combine and sort our files and reprocess them to get usage.

## How to run

```
bundle install # to install gems
./main.rb <db_filename.sqlite>
# it will create <db_filename.log>
```