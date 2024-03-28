#!/bin/bash

: ${RAILS_ENV:?"Need to set RAILS_ENV (e.g. development, stage, production)"}

echo ""
dt=`date '+%m/%d/%Y_%H:%M:%S'`
echo "Starting counter run at $dt"

# may have some environment problems, maybe needs to be run as interactive shell or see /apps/dryad/apps/ui/unbloat.sh for setting environment
# maybe /usr/bin/bash -l -c <script> will run with correct environment set

COUNTER_JSON_STORAGE="/home/ec2-user/deploy/shared/cron/counter-json"

cd /apps/dryad/apps/ui/current

bundle exec rails counter:cop_populate # this does counter population from the hub instead of our local files

# -----------------------------------------------
# remove old logs that are past our deletion time
# -----------------------------------------------
# we may want to keep this until moved to the new servers or all logs have passed the 2 month window

echo "Remove old logs past their deletion time"
bundle exec rails counter:remove_old_logs
