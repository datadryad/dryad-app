#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/

# In Progress reminder - at 3 days
bundle exec rails identifiers:in_progess_reminder RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/in_progess_reminder.log 2>&1
# In Progress reminders - monthly
bundle exec rails dataset_deletion:in_progress_reminders RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/in_progess_reminder.log 2>&1

# Action required reminder - at 2 weeks
bundle exec rails identifiers:action_required_reminder RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/action_required_reminders.log 2>&1
# Action required reminders - monthly
bundle exec rails dataset_deletion:in_action_required_reminders RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/action_required_reminders.log 2>&1

# Peer review reminders - monthly after 6 months
bundle exec rails dataset_deletion:in_peer_review_reminders RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/peer_review_reminders.log 2>&1

# Automatically withdraw dataset
bundle exec rails dataset_deletion:auto_withdraw RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/automatic_dataset_widrawn.log 2>&1

# Final withdraw email notification
bundle exec rails dataset_deletion:final_withdrawn_notification RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/final_withdrawn_notification.log 2>&1


bundle exec rails identifiers:publish_datasets RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/publish_datasets.log 2>&1
bundle exec rails identifiers:doi_linking_invitation RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/doi_linking_invitation.log 2>&1
bundle exec rails identifiers:update_missing_search_words RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/update_search_words.log 2>&1
bundle exec rails dev_ops:retry_zenodo_errors RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/retry_zenodo_errors.log 2>&1
bundle exec rails curation_stats:update_recent RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/curation_stats.log 2>&1
bundle exec rails journal_email:clean_old_manuscripts RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/manuscripts_clean.log 2>&1
#bundle exec rails compressed:update_contents RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/compressed_contents.log 2>&1
bundle exec rails identifiers:datasets_without_primary_articles_report  RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/datasets_without_primary_articles_report.log 2>&1

# Clean outdated content from the database and temporary S3 store
bundle exec rails identifiers:remove_old_versions DRY_RUN=false >> /home/ec2-user/deploy/shared/log/remove_old_versions.log 2>&1
bundle exec rails identifiers:remove_abandoned_datasets DRY_RUN=false RAILS_ENV=$1 >> /home/ec2-user/deploy/shared/log/abandoned_datasets.log 2>&1

# Download & validate file digests
bundle exec rails checksums:validate_files >> /home/ec2-user/deploy/shared/log/validate_files.log 2>&1
