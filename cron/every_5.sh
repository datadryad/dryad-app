#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/
export RAILS_ENV="$1"

bundle exec rails status_dashboard:check >> /home/ec2-user/deploy/shared/log/status_dashboard_check.log 2>&1
bundle exec rails journal_email:process >> /home/ec2-user/deploy/shared/log/journal_email.log 2>&1
