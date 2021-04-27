#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

STASH_ENV=$1 NOTIFIER_OUTPUT=stdout /dryad/apps/stash-notifier/main.rb >> /dryad/apps/ui/shared/cron/logs/stash-notifier.log 2>&1
bundle exec rails journal_email:process RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/journal_email.log 2>&1
