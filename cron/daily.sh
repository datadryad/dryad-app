#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/
export RAILS_ENV="$1"

# In Progress reminder - at 1 day
bundle exec rails identifiers:in_progress_reminder_1_day >> /home/ec2-user/deploy/shared/log/in_progess_reminder.log 2>&1
# In Progress reminder - at 3 days
bundle exec rails identifiers:in_progress_reminder_3_days >> /home/ec2-user/deploy/shared/log/in_progess_reminder.log 2>&1
# In Progress reminders - monthly
bundle exec rails dataset_deletion:in_progress_reminders >> /home/ec2-user/deploy/shared/log/in_progess_reminder.log 2>&1

# Action required reminder - at 2 weeks
bundle exec rails identifiers:action_required_reminder >> /home/ec2-user/deploy/shared/log/action_required_reminders.log 2>&1
# Action required reminders - monthly
bundle exec rails dataset_deletion:in_action_required_reminders >> /home/ec2-user/deploy/shared/log/action_required_reminders.log 2>&1
# Awaiting payment reminders - monthly after 6 months
bundle exec rails dataset_deletion:in_awaiting_payment_reminders >> /home/ec2-user/deploy/shared/log/awaiting_payment_reminders.log 2>&1
# Peer review reminders - monthly after 6 months
bundle exec rails dataset_deletion:in_peer_review_reminders >> /home/ec2-user/deploy/shared/log/peer_review_reminders.log 2>&1

# Automatically withdraw dataset
bundle exec rails dataset_deletion:auto_withdraw >> /home/ec2-user/deploy/shared/log/automatic_dataset_widrawn.log 2>&1

# Final withdraw email notification
bundle exec rails dataset_deletion:final_withdrawn_notification >> /home/ec2-user/deploy/shared/log/final_withdrawn_notification.log 2>&1


bundle exec rails identifiers:publish_datasets >> /home/ec2-user/deploy/shared/log/publish_datasets.log 2>&1
bundle exec rails identifiers:check_dataset_payment >> /home/ec2-user/deploy/shared/log/dataset_invoice_status.log 2>&1
bundle exec rails identifiers:doi_linking_invitation >> /home/ec2-user/deploy/shared/log/doi_linking_invitation.log 2>&1
bundle exec rails identifiers:update_missing_search_words >> /home/ec2-user/deploy/shared/log/update_search_words.log 2>&1
bundle exec rails dev_ops:retry_zenodo_errors >> /home/ec2-user/deploy/shared/log/retry_zenodo_errors.log 2>&1
bundle exec rails curation_stats:update_recent >> /home/ec2-user/deploy/shared/log/curation_stats.log 2>&1
bundle exec rails journal_email:clean_old_manuscripts >> /home/ec2-user/deploy/shared/log/manuscripts_clean.log 2>&1
bundle exec rails compressed:update_contents >> /home/ec2-user/deploy/shared/log/compressed_contents.log 2>&1
bundle exec rails identifiers:datasets_without_primary_articles_report  >> /home/ec2-user/deploy/shared/log/datasets_without_primary_articles_report.log 2>&1

# Clean outdated content from the database and temporary S3 store
#bundle exec rails identifiers:remove_old_versions DRY_RUN=false >> /home/ec2-user/deploy/shared/log/remove_old_versions.log 2>&1
bundle exec rails identifiers:remove_abandoned_datasets DRY_RUN=false >> /home/ec2-user/deploy/shared/log/abandoned_datasets.log 2>&1

# Download & Validate file digests
bundle exec rails checksums:validate_files >> /home/ec2-user/deploy/shared/log/validate_files.log 2>&1
# Generate checksum for files without digests
bundle exec rails checksums:generate_digests >> /home/ec2-user/deploy/shared/log/generate_file_digests.log 2>&1
