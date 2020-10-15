#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

export RAILS_ENV="$1"

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

# gets the token from our config by way of rake task and sets variable for last line and also variable for report dir
tok=`bundle exec rails dev_ops:get_counter_token RAILS_ENV=$1`
# set env for last line of output
export TOKEN=`echo "$tok" | tail -n1`
export REPORT_DIR="/apps/dryad-prd-shared/json-reports"

# force submission for last month (and will submit other missing months)
export FORCE_SUBMISSION="`date --date="$(date +%Y-%m-15) - 1 month" "+%Y-%m"`"

# run the script with the above settings, this is just a ruby script (no rails)
/apps/dryad/apps/ui/current/stash/script/counter-uploader/main.rb >> /apps/dryad/apps/ui/shared/cron/logs/counter-uploader.log 2>&1
