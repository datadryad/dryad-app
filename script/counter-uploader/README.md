# What is all the crap in this directory?

These are mostly one-off scripts for manual COUNTER stuff we needed to get
old reports pushed to the hub.

- `main.rb <filename>` will take an argument for a json report file and
tweak it so that it can be uploaded to DataCite Counter hub as a gz file.
  - The `uploader.rb` file is used by the above.  It modifies the headers for the
  very special upload and gzips and sends it.
- `up_it.rb` will just upload report files to the hub without doing compression shenanigans.
The assumptions are:
  - The reports you want to upload are in `json-reports`.
  - The `json-state` directory contains `config.yaml`, `secrets.yaml`
  and `statefile.json` with the state info for your already submitted reports.
  - The `statefile.json` already has the `id`s filled in for each month
  and you're just updating the reports.
  - The script doesn't have differential methods for doing `POST` sometimes
  for new months (and saving to the state) and `PUT` for updating old reports.
  It assumes it's always just an update since that is all I needed from
  this script.
  - PS.  The timeouts are high because otherwise the MDC/Counter hub causes it to barf.
- `check_reports.rb` checks the actual reports to see if they've been processed and have data in them.
  - Run the curl command shown in the file to get the report of reports.
  ```
  curl "https://api.datacite.org/reports?client-id=cdl.dash&page\[size\]=200" > reports_submitted.json
  ```
  - It will query the datacite-usage event-date API to see if it returns
  some annoying linked data that indicates your report is returning results.
  - It outputs the months and either `no data` or `total pages`