#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

cd /home/ec2-user/deploy/current/
export RAILS_ENV="$1"

# Opting not to record output in logs since it would display the command in clear text
nice -n 19 ionice -c 3 bundle exec rails dev_ops:backup
