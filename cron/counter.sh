#!/bin/bash

: ${RAILS_ENV:?"Need to set RAILS_ENV (e.g. development, stage, production)"}

echo ""
dt=`date '+%m/%d/%Y_%H:%M:%S'`
echo "Starting counter run at $dt"

# may have some environment problems, maybe needs to be run as interactive shell
# maybe /usr/bin/bash -l -c <script> will run with correct environment set

COUNTER_JSON_STORAGE="/home/ec2-user/deploy/shared/cron/counter-json"

cd /home/ec2-user/deploy/current

bundle exec rails counter:cop_populate # this does counter population from the hub instead of our local files
