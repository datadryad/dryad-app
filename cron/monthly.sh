#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

export RAILS_ENV="$1"

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

export REPORT_DIR="/apps/dryad/apps/ui/shared/cron/counter-json"

# force submission for last month (and will submit other missing months)
# export FORCE_SUBMISSION="`date --date="$(date +%Y-%m-15) - 1 month" "+%Y-%m"`"

# run the script with the above settings (RAILS_ENV, REPORT_DIR, FORCE_SUBMISSION)
# bundle exec rails counter:datacite_pusher >> /apps/dryad/apps/ui/shared/cron/logs/counter-uploader.log 2>&1

# Clean outdated content from the database and temporary S3 store
bundle exec rails identifiers:remove_old_versions >> /apps/dryad/apps/ui/shared/cron/logs/remove_old_versions.log 2>&1

# Update Genbank IDs and PubMedIDs related to Dryad datasets,
# then send them to LinkOut (NCBI) and LabsLink (Europe PMC)
bundle exec rails link_out:seed_pmids >> /apps/dryad/apps/ui/shared/cron/logs/link_out_seed_pmids.log 2>&1
bundle exec rails link_out:seed_genbank_ids >> /apps/dryad/apps/ui/shared/cron/logs/link_out_seed_pmids.log 2>&1
bundle exec rails link_out:publish >> /apps/dryad/apps/ui/shared/cron/logs/link_out_publish.log 2>&1

# Update ROR organizations
bundle exec rails affiliation_import:update_ror_orgs >>/apps/dryad/apps/ui/shared/cron/logs/ror_update.log 2>&1
