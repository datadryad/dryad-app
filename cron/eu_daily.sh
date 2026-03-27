#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/
export RAILS_ENV="$1"

# Spot check files digests for secondary storage
bundle exec rails checksums:spot_check_secondary_storage_files >> /home/ec2-user/deploy/shared/log/spot_check_secondary_storage_files.log 2>&1
