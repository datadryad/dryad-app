#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/

bundle exec rails status_dashboard:check RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/status_dashboard_check.log 2>&1
bundle exec rails journal_email:process RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/journal_email.log 2>&1
