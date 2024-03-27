#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

export RAILS_ENV="$1"

cd /home/ec2-user/deploy/current/

# clear out cache older than 3 weeks old, remove empty directories in cache
find /home/ec2-user/deploy/shared/tmp/cache -mtime +21 -type f -exec rm {} \;
find /home/ec2-user/deploy/shared/tmp/cache -empty -type d -delete

bundle exec rails publication_updater:crossref >> /home/ec2-user/deploy/shared/log/publication_updater_crossref.log 2>&1

bundle exec rails identifiers:voided_invoices_report >> /home/ec2-user/deploy/shared/log/voided_invoices_report.log 2>&1

# putting this in background since I don't want to delay the counter processor starting
bundle exec rails counter:populate_citations >> /home/ec2-user/deploy/shared/log/citation_populator.log 2>&1 &!

# the MDC/counter processor only runs in the production && stage environments
if [ "$RAILS_ENV" == "production" ] || [ "$RAILS_ENV" == "stage" ]
then
    # the counter.sh script used to do more log procesing, but now only does a couple of things
    cd /home/ec2-user/deploy/current/cron
    ./counter.sh >> /home/ec2-user/deploy/shared/log/counter.log 2>&1
fi
