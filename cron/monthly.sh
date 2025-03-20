#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/
export RAILS_ENV="$1"
export REPORT_DIR="/home/ec2-user/deploy/shared/cron/counter-json"

# force counter submissions for last month (and will submit other missing months)
# export FORCE_SUBMISSION="`date --date="$(date +%Y-%m-15) - 1 month" "+%Y-%m"`"

# run the script with the above settings (RAILS_ENV, REPORT_DIR, FORCE_SUBMISSION)
# this script is no longer used since we don't routinely update and force reports based on logs/json files
# bundle exec rails counter:datacite_pusher >> /home/ec2-user/deploy/shared/log/counter-uploader.log 2>&1


# Update Genbank IDs and PubMedIDs related to Dryad datasets,
# then send them to LinkOut (NCBI) and LabsLink (Europe PMC)
bundle exec rails link_out:seed_pmids >> /home/ec2-user/deploy/shared/log/link_out_seed_pmids.log 2>&1
bundle exec rails link_out:seed_genbank_ids >> /home/ec2-user/deploy/shared/log/link_out_seed_pmids.log 2>&1
bundle exec rails link_out:publish >> /home/ec2-user/deploy/shared/log/link_out_publish.log 2>&1

# Update ROR organizations
bundle exec rails affiliation_import:update_ror_orgs >> /home/ec2-user/deploy/shared/log/ror_update.log 2>&1
bundle exec rails affiliation_import:update_affiliations_names >> /home/ec2-user/deploy/shared/log/affiliations_name_updates.log 2>&1

# Cleanup affiliation/contributor records
bundle exec rails cleanup:duplicate_affiliations >> /home/ec2-user/deploy/shared/log/duplicate_affiliations.log 2>&1
bundle exec rails cleanup:affiliations_wo_ror >> /home/ec2-user/deploy/shared/log/affiliations_wo_ror_cleanup.log 2>&1
bundle exec rails cleanup:contributors_wo_ror >> /home/ec2-user/deploy/shared/log/contributors_wo_ror_cleanup.log 2>&1
