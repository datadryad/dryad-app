#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

RAILS_ENV=$1 bundle exec rails notifier:execute >> /dryad/apps/ui/shared/cron/logs/stash-notifier.log 2>&1

