#!/bin/bash

: ${1:?"Need to pass in environment (e.g. development, stage, production)"}

PATH=$PATH:/apps/dryad/local/bin

cd /apps/dryad/apps/ui/current/

# Opting not to record output in logs since it would display the command in clear text
bundle exec rails dev_ops:backup RAILS_ENV=$1
