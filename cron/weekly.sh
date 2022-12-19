#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

export RAILS_ENV="$1"

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

bundle exec rails publication_updater:crossref >> /apps/dryad/apps/ui/shared/cron/logs/publication_updater_crossref.log 2>&1

bundle exec rails identifiers:voided_invoices_report >>/apps/dryad/apps/ui/shared/cron/logs/voided_invoices_report.log 2>&1

# putting this in background since I don't want to delay the counter processor starting
bundle exec rails counter:populate_citations >> /apps/dryad/apps/ui/shared/cron/logs/citation_populator.log 2>&1 &!

# the MDC/counter processor only runs in the production environment to send stats to the datacite hub, no need to run in other environments
if [ "$RAILS_ENV" == "production" ] || [ "$RAILS_ENV" == "stage" ]
then
    source ~/.profile.d/pyenv
    cd /apps/dryad/apps/ui/current/cron
    ./counter.sh >> /apps/dryad/apps/ui/shared/cron/logs/counter.log 2>&1
fi
