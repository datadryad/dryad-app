# Counter log comparison

The files in this directory are used to compare our raw counter logs
with the DataCite Tracker events which were sent to us as a CSV
after requesting it from them.  It has these column headers.

```csv
"timestamp","metric_name","repo_id","user_id","session_id","url","pid"
```

## Technical info about scripts.

- This is a standalone ruby script, it doesn't require rails.
- This populates  the information into a SQLite database (which is a file).
- It will create the SQLite database if it doesn't exist on running.
- Uses ActiveRecord and automatically migrates the one table it creates.
- bundle install inside this directory to get dependencies.

## Running the script

Usage: `ruby cdl_logs.rb --file FILE --action [cdl|datacite]`

- To make use of this first run the script with the `cdl` action to
  populate the database with the counter log file from our own logs
  for a log date.
- Then run the script with the `datacite` action to attempt matching events
  from the DataCite tracker CSV file.  That will set the `matched` column to
  1 (true) if it believes it has found a match.
- It will output to the terminal items that it couldn't match to our logs.  I was able 
  to get an over 90% "match" rate.

## What a "match" means

The data that we get from DataCite doesn't have an identifier that matches exactly
with the things we log.  We also don't have an IP address or anything in their data.

Matches are based on:

- Same DOI
- Same type (view or download)
- Our item was logged up to 60 seconds before or 30 seconds after the DataCite event log
  to take into account time skew between the systems.
- Closest time match between the two if there is more than one within that time window.

Clearly this matching isn't very exact, but it does seem to work a lot of the time and
roughly line up with some events.

