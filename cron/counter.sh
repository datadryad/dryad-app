#!/bin/bash

: ${RAILS_ENV:?"Need to set RAILS_ENV (e.g. development, stage, production)"}

echo ""
dt=`date '+%m/%d/%Y_%H:%M:%S'`
echo "Starting counter run at $dt"

# may have some environment problems, maybe needs to be run as interactive shell or see /apps/dryad/apps/ui/unbloat.sh for setting environment
# maybe /usr/bin/bash -l -c <script> will run with correct environment set

# this is for flexility but right now only used in production for real purposes
source "${RAILS_ENV}_counter.sh"

COUNTER_JSON_STORAGE="/apps/dryad/apps/ui/shared/cron/counter-json"

# --------------------------------------
# combining daily logs from both servers
# --------------------------------------
echo "Combining logs from all servers"
export LOG_DIRECTORY="/apps/dryad/apps/ui/current/log"
cd /apps/dryad/apps/ui/current
# note for the combine_files to work, this server must have its public key added to the other SCP_HOSTS authorized keys so it can scp in to get files
bundle exec rails counter:combine_files

# ---------------------------------------
# set up python and run counter-processor (maybe twice)
# ---------------------------------------
# echo "Running counter-processor"
# should no longer need to do this on the new servers because pyenv is installed into the environment with 3.7.9
# export VIRTUAL_ENV=/apps/dryad/python_venv/python3.7.9
# export PATH=$VIRTUAL_ENV/bin:$PATH
# export PYTHONPATH=$VIRTUAL_ENV

python --version
cd /apps/dryad/apps/counter/counter-processor
# may need to to run the following lines to get dependencies (like bundler) before the first time the processor is run
# pip install -r requirements.txt
YEST_MONTH="`date --date='1 day ago' '+%Y-%m'`"
WEEK_AGO_MONTH="`date --date='8 days ago' '+%Y-%m'`"

# note there are additional configurations in the counter-processor config diretory and these just override or set thing there
# UPLOAD_TO_HUB=True \
# YEAR_MONTH=$WEEK_AGO_MONTH \
# OUTPUT_FILE="$COUNTER_JSON_STORAGE/$WEEK_AGO_MONTH" \
# LOG_NAME_PATTERN="/apps/dryad/apps/ui/current/log/counter_(yyyy-mm-dd).log_combined" \
# python -u main.py

if [ "$YEST_MONTH" != "$WEEK_AGO_MONTH" ]; then
    # We have another month to partially process
    # note there are additional configurations in the counter-processor config diretory and these just override or set thing there
    # UPLOAD_TO_HUB=True \
    # YEAR_MONTH=$YEST_MONTH \
    # OUTPUT_FILE="$COUNTER_JSON_STORAGE/$YEST_MONTH" \
    # LOG_NAME_PATTERN="/apps/dryad/apps/ui/current/log/counter_(yyyy-mm-dd).log_combined" \
    # python -u main.py
fi

cd /apps/dryad/apps/ui/current

# There is a "monthly" task which re-uploads all stats to datacite from our output json files

# This was from when we weren't getting stats back from DataCite because of problems
# --------------------------------------
# clear out cached stats in our database
# --------------------------------------
# echo "Clearing cached stats from database"
# bundle exec rails counter:clear_cache

# This was from when we weren't getting stats back from DataCite because of problems and occasionally switch it in and out
# when there are problems again.
# -----------------------------------------
# repopulate all stats back into our tables
# -----------------------------------------
echo "Repopulating stats into database cache"
# JSON_DIRECTORY="$COUNTER_JSON_STORAGE" bundle exec rails counter:cop_manual # this populates from our local reports
bundle exec rails counter:cop_populate # this does it from the hub instead of our local files

# -----------------------------------------------
# remove old logs that are past our deletion time
# -----------------------------------------------
echo "Remove old logs past their deletion time"
bundle exec rails counter:remove_old_logs
