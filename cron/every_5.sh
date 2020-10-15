#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

bundle exec rails status_dashboard:check RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/status_dashboard_check.log 2>&1

