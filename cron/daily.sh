#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

bundle exec rails identifiers:publish_datasets RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/publish_datasets.log 2>&1
bundle exec rails identifiers:peer_review_reminder RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/peer_review_reminder.log 2>&1
bundle exec rails identifiers:doi_linking_invitation RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/doi_linking_invitation.log 2>&1
bundle exec rails identifiers:in_progess_reminder RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/in_progess_reminder.log 2>&1
bundle exec rails identifiers:update_missing_search_words RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/update_search_words.log 2>&1
bundle exec rails identifiers:identifiers:action_required_reminder RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/action_required_reminders.log 2>&1
bundle exec rails dev_ops:retry_zenodo_errors RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/retry_zenodo_errors.log 2>&1
bundle exec rails curation_stats:update_recent RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/curation_stats.log 2>&1
bundle exec rails journal_email:clean_old_manuscripts RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/manuscripts_clean.log 2>&1
bundle exec rails compressed:update_contents RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/compressed_contents.log 2>&1
bundle exec rails identifiers:datasets_without_primary_articles_report  RAILS_ENV=$1 >> /apps/dryad/apps/ui/shared/cron/logs/datasets_without_primary_articles_report.log 2>&1
