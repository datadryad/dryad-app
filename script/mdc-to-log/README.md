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

## Some other notes about related activities

1. Get good log files, without errors from dryad
2. Get the dash log files from this script
3. Combine duplicate months with a command like
```
cat good-counter/counter_2019-04.log dash-stats/counter_db_2019-04.log | sort > counter_2019-04.log
```


This will help you run counter for months.

```
export PATH=$HOME/opt/bin:$PATH
export PYTHONPATH=$HOME/opt/bin/python-3.6.9
python --version
cd /apps/dryad/apps/counter/counter-processor

for file in /apps/dryad-prd-shared/good-counter/*.log
do
  YEAR_MONTH=$(echo "$file" | grep -oP '201\d{1}-\d{2}')
  LOG_NAME_PATTERN="$file"
  export YEAR_MONTH
  export LOG_NAME_PATTERN
  UPLOAD_TO_HUB=False ./main.py
  unset -v YEAR_MONTH LOG_NAME_PATTERN
  break
done
```
